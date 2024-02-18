@echo off
setlocal

:: Prompt user for the name of the WSL instance and linux user name
set /p WSLName=Please enter the name of the WSL instance you wish to use:
set /p LinuxUsername=Please enter your username in the WSL instance:

:: Get the current directory in Windows format
cd /d %~dp0
:: Convert the current Windows directory to WSL path format and store it in a variable
for /f "tokens=*" %%i in ('wsl wslpath -a "%CD%"') do set WSL_CURRENT_DIR=%%i
:: Use the variable to copy the Dockerfile into the desired location in WSL
wsl -d %WSLName% -e sudo mkdir -p /home/%LinuxUsername%/TTS_server
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to create server directory.
    pause
    exit /b %ERRORLEVEL%
)
wsl -d %WSLName% -e sudo cp "%WSL_CURRENT_DIR%/Dockerfile" /home/%LinuxUsername%/TTS_server/
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to copy server Dockerfile.
    pause
    exit /b %ERRORLEVEL%
)
wsl -d %WSLName% -e sudo cp "%WSL_CURRENT_DIR%/main.py" /home/%LinuxUsername%/TTS_server/
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to copy main.py.
    pause
    exit /b %ERRORLEVEL%
)
wsl -d %WSLName% -e sudo cp "%WSL_CURRENT_DIR%/xtts_requirements.txt" /home/%LinuxUsername%/TTS_server/
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to copy main.py.
    pause
    exit /b %ERRORLEVEL%
)
wsl -d %WSLName% -e sudo cp "%WSL_CURRENT_DIR%/start_tts_service.sh" /home/%LinuxUsername%/TTS_server/
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to copy start script.
    pause
    exit /b %ERRORLEVEL%
)

echo TTS SERVER: Checking if Docker daemon is running...

REM Check if dockerd is running
wsl -d %WSLName% -- pgrep dockerd >nul 2>&1
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: Docker daemon not running. Starting dockerd background process
    wsl -d %WSLName% -e nohup sh -c "dockerd &"
    timeout 5 /NOBREAK >NUL
) ELSE (
    echo TTS SERVER: Docker daemon is running.
)

echo TTS SERVER: Building Docker image...

wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/TTS_server && docker build . -t tts_server_docker"
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to build Docker image. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo TTS SERVER: Running Docker container...
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/TTS_server && docker rm -f tts_server_docker"
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/TTS_server && docker run --gpus all -d -p 8010:8010 -p 80:80 -p 5000:5000 -v /home/%LinuxUsername%/TTS_server:/home/%LinuxUsername%/TTS_server --name tts_server_docker tts_server_docker"
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to run Docker container. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo TTS SERVER: AI servers running - press CTRL+C here when done playing to close this window.
pause > NUL

echo TTS SERVER: Cleaning up WSL state...
wsl -t %WSLName%
if NOT %ERRORLEVEL% == 0 (
    echo TTS SERVER: ERROR: Failed to terminate WSL instance. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo TTS SERVER: Cleanup completed successfully.
endlocal