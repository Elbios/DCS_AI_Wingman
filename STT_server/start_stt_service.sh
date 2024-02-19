#!/bin/bash

# Redirecting stdout and stderr to separate log files for whispercpp
cd /whispercpp/whisper.cpp && ./server -m models/${WHISPERCPP_MODEL_FILENAME} --host 0.0.0.0 --port 8070 --convert > /home/debian/STT_server/whispercpp_log.txt 2>&1 &

# Keep the container running since background processes won't do it
wait
