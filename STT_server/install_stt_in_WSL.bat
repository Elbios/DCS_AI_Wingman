@echo off
setlocal

echo STT SERVER: Starting the installation

:: Prompt user for the name of the WSL instance and linux user name
set /p WSLName=Please enter the name of the WSL instance you wish to use: 
set /p LinuxUsername=Please enter your username in the WSL instance:

echo STT SERVER: Updating package lists...
wsl -d %WSLName% -e sudo apt update
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to update package lists. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Installing curl...
wsl -d %WSLName% -e sudo apt install -y curl
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to install curl. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Checking if Docker daemon is running...

:: Check if dockerd is running
wsl -d %WSLName% -- pgrep dockerd >nul 2>&1
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: Docker daemon not running. Assuming Docker is not installed. Proceeding to install Docker..
) ELSE (
    echo STT SERVER: Docker daemon already running, assuming dependencies are installed. Exiting..
    exit /b 0
)

echo STT SERVER: Downloading Docker install script...
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername% && curl -fsSL https://get.docker.com -o get-docker.sh"
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to download Docker install script. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Installing Docker...
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername% && sudo sh get-docker.sh"
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to install Docker. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Setting up NVIDIA Container Toolkit...
wsl -d %WSLName% -e bash -c "curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to setup NVIDIA Container Toolkit. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Updating package lists again...
wsl -d %WSLName% -e sudo apt-get update
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to update package lists again. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Installing NVIDIA Container Toolkit...
wsl -d %WSLName% -e sudo apt-get install -y nvidia-container-toolkit
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to install NVIDIA Container Toolkit. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Adding user to the Docker group...
wsl -d %WSLName% -e sudo usermod -aG docker %LinuxUsername%
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to add user to the Docker group. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

:: Get the current directory in Windows format
cd /d %~dp0
:: Convert the current Windows directory to WSL path format and store it in a variable
for /f "tokens=*" %%i in ('wsl wslpath -a "%CD%"') do set WSL_CURRENT_DIR=%%i
:: Use the variable to copy the Dockerfile into the desired location in WSL
wsl -d %WSLName% -e mkdir -p /home/%LinuxUsername/STT_server
wsl -d %WSLName% -e cp "%WSL_CURRENT_DIR%/Dockerfile" /home/%LinuxUsername/STT_server
endlocal

echo STT SERVER: Recommending running 'wsl --shutdown' or full Windows reboot for changes to take effect...

echo STT SERVER: Installation completed successfully!
endlocal
pause