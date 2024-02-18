import asyncio
from tts import tts

# Example call to the async function
# This assumes you have defined endpoint, language, and voiceid accordingly
async def main():
    result = await tts("Hello world how are you feeling?", "http://172.27.206.9:80/", "en", "ATC_sample1_denoised_cloned")
    print(result)

if __name__ == "__main__":
    asyncio.run(main())
