@echo off
setlocal

:: Prompt user for the name of the WSL instance and linux user name
set /p WSLName=Please enter the name of the WSL instance you wish to use: 
set /p LinuxUsername=Please enter your username in the WSL instance:
set /p WhisperMode=Do you want to run Whisper STT in CPU mode or GPU(CUDA) mode? (cpu/cuda):


if /i "%WhisperMode%"=="cpu" (
    set WhisperArg=--build-arg WHISPER_MODE=cpu
    set WhisperArg2=-e WHISPER_MODE=cpu
) else if /i "%VisionModel%"=="cuda" (
    set WhisperArg=--build-arg WHISPER_MODE=cuda
    set WhisperArg2=-e WHISPER_MODE=cuda
) else (
    echo Invalid option. Exiting script.
    exit /b 1
)

echo STT SERVER: Checking if Docker daemon is running...

REM Check if dockerd is running
wsl -d %WSLName% -- pgrep dockerd >nul 2>&1
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Docker daemon not running. Try restarting WSL: 'wsl --shutdown' or reboot Windows. Exiting..
    pause
    exit /b %ERRORLEVEL%
) ELSE (
    echo STT SERVER: Docker daemon is running.
)

echo STT SERVER: Building Docker image...

wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/STT_server && docker build . %WhisperArg% -t stt_server_docker"
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to build Docker image. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Running Docker container...
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/STT_server && docker rm -f stt_server_docker"
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/STT_server && docker run --gpus all -d %WhisperArg2% -p 8070:8070 -v /home/%LinuxUsername%/STT_server:/home/%LinuxUsername%/STT_server --name stt_server_docker stt_server_docker"
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to run Docker container. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: AI servers running - press CTRL+C here when done playing to close this window.
pause > NUL

echo STT SERVER: Cleaning up WSL state...
wsl -t %WSLName%
if NOT %ERRORLEVEL% == 0 (
    echo STT SERVER: ERROR: Failed to terminate WSL instance. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo STT SERVER: Cleanup completed successfully.
endlocal