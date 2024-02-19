# Use PyTorch base image with CUDA
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel as base

# Set non-interactive installation mode
ARG DEBIAN_FRONTEND=noninteractive

# Either openai or koboldcpp
ARG LLM_BACKEND=koboldcpp

# Filename of LLM, like: dolphin-2_6-phi-2.Q2_K.gguf (fill in both)
#ARG LLM_FILENAME=dolphin-2_6-phi-2.Q2_K.gguf
#ENV LLM_FILENAME=dolphin-2_6-phi-2.Q2_K.gguf
ARG LLM_FILENAME=toppy-m-7b.Q4_K_S.gguf
ENV LLM_FILENAME=toppy-m-7b.Q4_K_S.gguf
#ARG LLM_FILENAME=mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf
#ENV LLM_FILENAME=mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf
# Huggingface link to LLM, like: https://huggingface.co/TheBloke/dolphin-2_6-phi-2-GGUF/resolve/main/dolphin-2_6-phi-2.Q2_K.gguf?download=true
#ARG LLM_DOWNLOAD_LINK=https://huggingface.co/TheBloke/dolphin-2_6-phi-2-GGUF/resolve/main/dolphin-2_6-phi-2.Q2_K.gguf?download=true
ARG LLM_DOWNLOAD_LINK=https://huggingface.co/TheBloke/Toppy-M-7B-GGUF/resolve/main/toppy-m-7b.Q4_K_S.gguf?download=true
#ARG LLM_DOWNLOAD_LINK=https://huggingface.co/TheBloke/Mixtral-8x7B-Instruct-v0.1-GGUF/resolve/main/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf?download=true

# Common dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y sox libsox-fmt-all curl wget gcc git git-lfs build-essential libaio-dev libsndfile1 ssh ffmpeg && \
    apt-get clean && apt-get -y autoremove

RUN if [ "${LLM_BACKEND}" = "koboldcpp" ]; then \
        curl -fLo /usr/bin/koboldcpp https://koboldai.org/cpplinux && chmod +x /usr/bin/koboldcpp && \
		mkdir -p /models && \
        wget -q -O /models/${LLM_FILENAME} ${LLM_DOWNLOAD_LINK} \
    ; fi

EXPOSE 5001

WORKDIR /home/debian/LLM_server

CMD ["bash", "start_llm_service.sh"]