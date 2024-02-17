#!/bin/bash

echo "STT SERVER: Starting the installation"

echo "STT SERVER: Updating package lists..."
sudo apt update
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to update package lists. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Installing curl..."
sudo apt install -y curl
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to install curl. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Checking if Docker daemon is running..."

pgrep dockerd > /dev/null
if [ $? -eq 0 ]; then
    echo "STT SERVER: Docker daemon already running, assuming dependencies are installed. Exiting.."
    exit 0
fi

echo "STT SERVER: Docker daemon not running. Assuming Docker is not installed. Proceeding to install Docker.."

echo "STT SERVER: Downloading Docker install script..."
cd $HOME && curl -fsSL https://get.docker.com -o get-docker.sh
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to download Docker install script. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Installing Docker..."
cd $HOME && sudo sh get-docker.sh
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to install Docker. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Setting up NVIDIA Container Toolkit..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to setup NVIDIA Container Toolkit. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Updating package lists again..."
sudo apt-get update
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to update package lists again. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Installing NVIDIA Container Toolkit..."
sudo apt-get install -y nvidia-container-toolkit
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to install NVIDIA Container Toolkit. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Failed to start or enable Docker. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Verifying Docker is running..."
sudo docker run hello-world
if [ $? -ne 0 ]; then
    echo "STT SERVER: ERROR: Docker does not appear to be running correctly. Please check the log above for details."
    exit 1
fi

echo "STT SERVER: Adding current user to the Docker group..."
sudo usermod -aG docker $USER

echo "STT SERVER: Applying group changes..."
newgrp docker

echo "STT SERVER: Installation completed successfully!"