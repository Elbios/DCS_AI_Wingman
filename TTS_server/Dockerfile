# Use PyTorch base image with CUDA
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel

# Set non-interactive installation mode
ARG DEBIAN_FRONTEND=noninteractive

# Common dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y sox libsox-fmt-all curl wget gcc git git-lfs build-essential libaio-dev libsndfile1 ssh ffmpeg && \
    apt-get clean && apt-get -y autoremove

# Set work directory for XTTS
WORKDIR /xtts_app

# Copy main script for TTS
COPY main.py .
# Copy requirements for Python packages for TTS
COPY xtts_requirements.txt .

# Install Python packages
RUN python -m pip install --use-deprecated=legacy-resolver -r xtts_requirements.txt \
    && python -m pip cache purge

RUN python -m unidic download; \
    mkdir -p /xtts_app/tts_models;

# Environment variables for TTS
ENV NVIDIA_DISABLE_REQUIRE=0
ENV NUM_THREADS=2
ENV COQUI_TOS_AGREED=1
# XTTS exported on port 80 within Docker
EXPOSE 80
# XTTS webui
EXPOSE 8010

#RUN git clone https://github.com/Vali-98/XTTS-RVC-UI.git && \
#    cd XTTS-RVC-UI && \
#    pip install -r requirements.txt
RUN git clone https://github.com/daswer123/xtts-webui.git && \
    cd xtts-webui && \
    chmod +x install.sh && \
    ./install.sh

WORKDIR /home/debian/TTS_server

CMD ["bash", "start_tts_service.sh"]
#CMD ["sleep", "99999"]
