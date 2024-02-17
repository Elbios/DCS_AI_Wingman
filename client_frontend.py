import argparse
import io
import os
import speech_recognition as sr
from datetime import datetime
from queue import Queue
from tempfile import NamedTemporaryFile
from time import sleep
from sys import platform

import simpleaudio as sa

def play_wav(file_path):
    wave_obj = sa.WaveObject.from_wave_file(file_path)
    play_obj = wave_obj.play()
    play_obj.wait_done()
    

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--energy_threshold", default=1000, help="Energy level for mic to detect.", type=int)
    parser.add_argument("--record_timeout", default=30, help="How real time the recording is in seconds.", type=float)
    parser.add_argument("--phrase_timeout", default=0.5, help="How much empty space between recordings before we consider it a new line in the transcription.", type=float)
    if 'linux' in platform:
        parser.add_argument("--default_microphone", default='pulse', help="Default microphone name for SpeechRecognition. Run this with 'list' to view available Microphones.", type=str)
    args = parser.parse_args()

    # Create voice cache dir
    voice_cache_dir = "voice_cache"
    os.makedirs(voice_cache_dir, exist_ok=True)

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
    recorder.listen_in_background(source, record_callback, phrase_time_limit=args.record_timeout)
    
    print("Ready to record.\n")

    samples = bytes()
    
    print('<Listening...>', end='\r\n', flush=True)
    while True:
        now = datetime.utcnow()

        if not data_queue.empty():
            while not data_queue.empty():
                samples += data_queue.get()

        if len(samples) > 0:
            print('<Processing...>', end='\r\n', flush=True)
            # Use AudioData to convert the raw data to wav data.
            audio_data = sr.AudioData(samples, source.SAMPLE_RATE, source.SAMPLE_WIDTH)
            wav_data = io.BytesIO(audio_data.get_wav_data())
            # Write wav data to the temporary file in voice_cache dir
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            temp_file_path = os.path.join(voice_cache_dir, f"voice_{timestamp}.wav")
            with open(temp_file_path, 'w+b') as f:
                f.write(wav_data.read())

            print(f"Audio saved to {temp_file_path}", end='\r\n', flush=True)

            samples = bytes()
            print('<Listening...>', end='\r\n', flush=True)
        else:
            # Infinite loops are bad for processors, must sleep.
            sleep(0.25)

if __name__ == "__main__":
    main()