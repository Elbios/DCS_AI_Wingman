# Use PyTorch base image with CUDA
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel as base

# Set non-interactive installation mode
ARG DEBIAN_FRONTEND=noninteractive

# Use WHISPER_MODE cpu or cuda
ARG WHISPER_MODE=cuda
ARG WHISPERCPP_MODEL=base.en
ENV WHISPERCPP_MODEL_FILENAME=ggml-base.en.bin

# Common dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y sox libsox-fmt-all curl wget gcc git git-lfs build-essential libaio-dev libsndfile1 ssh ffmpeg && \
    apt-get clean && apt-get -y autoremove

WORKDIR /whispercpp

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/opt/cuda/lib64:/usr/lib/x86_64-linux-gnu:/usr/local/cuda-12.1/compat:$LD_LIBRARY_PATH
RUN  git clone https://github.com/ggerganov/whisper.cpp.git && \
    cd whisper.cpp && \
    export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH && \
    if [ "${WHISPER_MODE}" = "cuda" ]; then \
        WHISPER_CUBLAS=1 make -j; \
    else \
        WHISPER_CUBLAS=0 make -j; \
    fi && \
    bash ./models/download-ggml-model.sh ${WHISPERCPP_MODEL}

CMD ["bash", "start_stt_service.sh"]