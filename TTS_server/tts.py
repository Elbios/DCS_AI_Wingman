import asyncio
import aiohttp
import time
import json
import os
from os import path

async def tts(textString, endpoint, language, voiceid):
    url = f"{endpoint}tts_stream"
    headers = {
        'Accept': 'audio/wav',
        'Content-Type': 'application/json'
    }
    
    lang =  language
    voice = voiceid
    # Get the directory of tts.py
    script_path = path.dirname(path.realpath(__file__))
    # Construct the path to the speakers directory from there
    data_voice_path = path.join(script_path, "speakers", f"{voiceid}.json")

    with open(data_voice_path, "r") as file:
        data_voice = json.load(file)
    
    data = {
        'text': textString,
        'language': lang,
    }
    data_final = {**data, **data_voice}
    
    async with aiohttp.ClientSession() as session:
        async with session.post(url, headers=headers, json=data_final) as resp:
            if resp.status == 200:
                #print('got response from XTTS')
                response_content = await resp.read()
                #print('read response from XTTS')
                timestamp = int(time.time())
                soundcache_dir = path.join(script_path, "tts_cache")
                if not os.path.exists(soundcache_dir):
                    os.makedirs(soundcache_dir)
                base_filename = f"{timestamp}"
                output_wav_path = path.join(soundcache_dir, f"{base_filename}_o.wav")
                
                with open(output_wav_path, "wb") as audio_file:
                    audio_file.write(response_content)
                #print(f'saved xtts output file to {output_wav_path}')
                # Saving metadata or debug information as an example
                metadata_path = path.join(soundcache_dir, f"{base_filename}.txt")
                with open(metadata_path, "w") as metadata_file:
                    metadata_file.write(f"{textString}\nTimestamp: {timestamp}\nSize of WAV: {len(response_content)} bytes\n")
                
                return output_wav_path
            else:
                # Handle error case
                error_log_path = path.join(soundcache_dir, f"{base_filename}.err")
                with open(error_log_path, "w") as error_file:
                    error_text = f"{textString}\nResponse status: {resp.status}"
                    error_file.write(error_text)
                return False

