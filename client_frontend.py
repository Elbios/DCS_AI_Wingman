#! python3.10

import argparse
import io
import os
import speech_recognition as sr
import whisper
import torch

import os
import openai
import json

import threading
import time

from datetime import datetime, timedelta
from queue import Queue
from tempfile import NamedTemporaryFile
from time import sleep
from sys import platform

from TTS.api import TTS
import simpleaudio as sa

openai.api_key = 'xxx'

command_text = 'empty'
prompt_cnt = 0
messages_list = 'empty'

def play_wav(file_path):
    wave_obj = sa.WaveObject.from_wave_file(file_path)
    play_obj = wave_obj.play()
    play_obj.wait_done()
    
def say_response(tts, text):
    lines = text.splitlines()
    for line in lines:
        if len(line) > 3 and line[0] == '[':
            tts.tts_to_file(text=line, file_path="out.wav")
            # tts.tts_to_file(line[1:-1], speaker_wav="rad.wav", language="en", file_path="out.wav")
            # tts.tts_to_file(line[1:-1], language="en", file_path="out.wav", emotion="Dull", speed=1.2)
            play_wav("out.wav")
            
def load_prompt():
    file_path = 'F16_prompt.txt'
    
    # Read single string element and replace the existing prompt list
    file = open(file_path, "r")
    # Return list with single text element
    return [{"role": "system", "content": file.read()}]


def handle_keyboard_input():
    global command_text
    global prompt_cnt
    global prompt
    global messages_list
    
    while True:
        try:
            command_text = input()
            if command_text == 'dump':
                print(messages_list, end='\r\n\r\n')
                command_text = ''
            if command_text == 'reset':
                print('<Reset>', end='\r\n')
                prompt_cnt = 0
                messages_list = load_prompt()
                command_text = ''
        except (KeyboardInterrupt, EOFError):
            if prompt_cnt == 0:
                break

def main():
    global command_text
    global prompt_cnt
    global prompt
    global messages_list
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="medium", help="Model to use",
                        choices=["tiny", "base", "small", "medium", "large"])
    parser.add_argument("--non_english", action='store_true',
                        help="Don't use the english model.")
    parser.add_argument("--energy_threshold", default=1000,
                        help="Energy level for mic to detect.", type=int)
    parser.add_argument("--record_timeout", default=30,
                        help="How real time the recording is in seconds.", type=float)
    parser.add_argument("--phrase_timeout", default=0.5,
                        help="How much empty space between recordings before we "
                             "consider it a new line in the transcription.", type=float)  
    if 'linux' in platform:
        parser.add_argument("--default_microphone", default='pulse',
                            help="Default microphone name for SpeechRecognition. "
                                 "Run this with 'list' to view available Microphones.", type=str)
    args = parser.parse_args()
    
    # The last time a recording was retreived from the queue.
    phrase_time = None
    # Current raw audio bytes.
    samples = bytes()
    # Thread safe Queue for passing data from the threaded recording callback.
    data_queue = Queue()
    # We use SpeechRecognizer to record our audio because it has a nice feauture where it can detect when speech ends.
    recorder = sr.Recognizer()
    recorder.energy_threshold = args.energy_threshold
    # Definitely do this, dynamic energy compensation lowers the energy threshold dramtically to a point where the SpeechRecognizer never stops recording.
    recorder.dynamic_energy_threshold = False
    
    # Important for linux users. 
    # Prevents permanent application hang and crash by using the wrong Microphone
    if 'linux' in platform:
        mic_name = args.default_microphone
        if not mic_name or mic_name == 'list':
            print("Available microphone devices are: ")
            for index, name in enumerate(sr.Microphone.list_microphone_names()):
                print(f"Microphone with name \"{name}\" found")   
            return
        else:
            for index, name in enumerate(sr.Microphone.list_microphone_names()):
                if mic_name in name:
                    source = sr.Microphone(sample_rate=16000, device_index=index)
                    break
    else:
        source = sr.Microphone(sample_rate=16000)
        
    # Load / Download model
    model = args.model
    if args.model != "large" and not args.non_english:
        model = model + ".en"
    audio_model = whisper.load_model(model)

    record_timeout = args.record_timeout
    phrase_timeout = args.phrase_timeout

    temp_file = NamedTemporaryFile().name
    
    with source:
        recorder.adjust_for_ambient_noise(source)

    def record_callback(_, audio:sr.AudioData) -> None:
        """
        Threaded callback function to recieve audio data when recordings finish.
        audio: An AudioData containing the recorded bytes.
        """
        # Grab the raw bytes and push it into the thread safe queue.
        data = audio.get_raw_data()
        data_queue.put(data)

    # Create a background thread that will pass us raw audio bytes.
    # We could do this manually but SpeechRecognizer provides a nice helper.
    recorder.listen_in_background(source, record_callback, phrase_time_limit=record_timeout)
    
    # Listen to keyboard commands in background
    keyboard_thread = threading.Thread(target=handle_keyboard_input)
    keyboard_thread.start()
    
    # Init TTS with the target model name
    # Local EN female voice
    tts = TTS(model_name="tts_models/en/ljspeech/tacotron2-DDC", progress_bar=False, gpu=True)
    
    # Local TTS using WAV as reference (misgt not sound right)
    # tts = TTS(model_name="tts_models/multilingual/multi-dataset/your_tts", progress_bar=False, gpu=True)
    
    # Local polish model
    tts = TTS(model_name="tts_models/pl/mai_female/vits", progress_bar=False, gpu=True)
    
    # TTS For Cuqui external models
    # 26nM10MEB1IHuHklqnYV9P84IYbErXICevXMVlw45c5SW3nq4LWs3zomcIdeecjV
    # tts = TTS(model_name="coqui_studio/en/Damien Black/coqui_studio", progress_bar=False, gpu=False)

    # Cue the user that we're ready to go.
    print("Model loaded.\n")

    samples = bytes()
    messages_list = load_prompt()
    command_text = ''
    
    print('<Listening...>', end='\r\n', flush=True)
    
    while True:
        try:
            now = datetime.utcnow()
            
            if not data_queue.empty():
                if len(samples) == 0:
                    last_heard = now
                # Concatenate our current audio data with the latest audio data.
                while not data_queue.empty():
                    samples += data_queue.get()
                    
            if command_text and command_text != '':
                # Call OpenAI
                messages_list.append({"role": "assistant", "content": command_text})
                
                print('<AI...>', end='\r\n', flush=True)
                completion = openai.ChatCompletion.create(
                    model="gpt-4",
                    temperature=0.2,
                    top_p=1,
                    max_tokens=256,
                    messages=messages_list
                )
                
                response = completion.choices[0].message
                messages_list.append(response)

                # print(messages_list, end='\r\n\r\n')
                print(">> " + response['content'], end='\r\n', flush=True)
                say_response(tts, response['content'])
                
                command_text = ''
                    
            # If enough time has passed between recordings, consider the phrase complete.
            if (len(samples) > 0) and (now - last_heard > timedelta(seconds=phrase_timeout)):
                prompt_cnt += 1
                print('<Processing...>', end='\r\n', flush=True)
                
                # Use AudioData to convert the raw data to wav data.
                audio_data = sr.AudioData(samples, source.SAMPLE_RATE, source.SAMPLE_WIDTH)
                wav_data = io.BytesIO(audio_data.get_wav_data())

                # Write wav data to the temporary file as bytes.
                with open(temp_file, 'w+b') as f:
                    f.write(wav_data.read())

                # Read the transcription.
                result = audio_model.transcribe(temp_file, fp16=torch.cuda.is_available())
                text = result['text'].strip()

                print(text, end='\r\n', flush=True)
                
                # Call OpenAI
                messages_list.append({"role": "user", "content": "["+text+"]"})
                
                print('<AI...>', end='\r\n', flush=True)
                completion = openai.ChatCompletion.create(
                    model="gpt-4",
                    temperature=0.2,
                    top_p=1,
                    max_tokens=256,
                    messages=messages_list
                )
                
                response = completion.choices[0].message
                messages_list.append(response)

                # print(messages_list, end='\r\n\r\n')
                print(">> " + response['content'], end='\r\n', flush=True)
                say_response(tts, response['content'])
                
                samples = bytes()
                print('<Listening...>', end='\r\n', flush=True)
            else:
                # Infinite loops are bad for processors, must sleep.
                time.sleep(0.25)

        except KeyboardInterrupt:
            if prompt_cnt == 0:
                break
            print('<Reset>', end='\r\n', flush=True)
            prompt_cnt = 0
            messages_list = load_prompt()
            
if __name__ == "__main__":
    main()