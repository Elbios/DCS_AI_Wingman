#!/bin/bash

# Run XTTS server
cd /xtts_app
#cd XTTS-RVC-UI
cd xtts-webui
source venv/bin/activate
python app.py --deepspeed --share
#python app.py > /home/debian/TTS_server/xtts_rvc_ui_log.txt 2>&1

# Checking if INCLUDE_TTS is set to true and starting xTTS server
#uvicorn main:app --host 0.0.0.0 --port 80 > /home/debian/TTS_server/tts_log.txt 2>&1 &
# Keep the container running since background processes won't do it
wait
