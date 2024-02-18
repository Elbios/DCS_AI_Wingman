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
    
    data_voice_path = path.join("speakers", f"{voice}.json")
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
                response_content = await resp.read()
                
                timestamp = int(time.time())
                soundcache_dir = "tts_cache"
                if not os.path.exists(soundcache_dir):
                    os.makedirs(soundcache_dir)
                base_filename = f"{timestamp}"
                output_wav_path = path.join(soundcache_dir, f"{base_filename}_o.wav")
                
                with open(output_wav_path, "wb") as audio_file:
                    audio_file.write(response_content)
                
                # Saving metadata or debug information as an example
                metadata_path = path.join(soundcache_dir, f"{base_filename}.txt")
                with open(metadata_path, "w") as metadata_file:
                    metadata_file.write(f"{textString}\nTimestamp: {timestamp}\nSize of WAV: {len(response_content)} bytes\n")
                
                return f"soundcache/{base_filename}.wav"
            else:
                # Handle error case
                error_log_path = path.join(soundcache_dir, f"{base_filename}.err")
                with open(error_log_path, "w") as error_file:
                    error_text = f"{textString}\nResponse status: {resp.status}"
                    error_file.write(error_text)
                return False

# Example call to the async function
# This assumes you have defined endpoint, language, and voiceid accordingly
async def main():
    result = await tts("Hello world how are you feeling?", "http://172.27.206.9:80/", "en", "ATC_sample1_denoised_cloned")
    print(result)

if __name__ == "__main__":
    asyncio.run(main())
