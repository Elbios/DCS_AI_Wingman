#!/bin/bash

# Run XTTS server
cd /xtts_app

# XTTS-RVC-UI (not working)
#cd XTTS-RVC-UI
#python app.py > /home/debian/TTS_server/xtts_rvc_ui_log.txt 2>&1

# XTTS-webui Gradio (danswer123 TTS demo)
#cd xtts-webui
#source venv/bin/activate
#python app.py --deepspeed --share --host 0.0.0.0 --port 8010

# XTTS API server (Coqui official)
uvicorn main:app --host 0.0.0.0 --port 80 > /home/debian/TTS_server/coqui_xtts_server_log.txt 2>&1 &
# Keep the container running since background processes won't do it
wait
