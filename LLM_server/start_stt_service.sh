#!/bin/bash

# Redirecting stdout and stderr to separate log files for koboldcpp
# XXX: consider --noshift vs shift
# Offload only part of the layers for Mixtral as it is a big model
# For all other models - assume the entire model fits in VRAM
if [[ "${LLM_FILENAME}" == *"mixtral"* ]]; then
    GPULAYERS=18
else
    GPULAYERS=99
fi

koboldcpp --usecublas --gpulayers ${GPULAYERS} --threads 7 --contextsize 20000 --skiplauncher --multiuser 5 --model \
    /models/${LLM_FILENAME} > /home/debian/LLM_server/koboldcpp_log.txt 2>&1 &

# Keep the container running since background processes won't do it
wait
