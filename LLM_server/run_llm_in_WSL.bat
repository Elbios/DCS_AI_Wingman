@echo off
setlocal

:: Prompt user for the name of the WSL instance and linux user name
set /p WSLName=Please enter the name of the WSL instance you wish to use: 
set /p LinuxUsername=Please enter your username in the WSL instance:
set /p LLMBackend=Do you want to use OpenAI or koboldcpp as LLM? (openai/koboldcpp):

if /i "%LLMBackend%"=="openai" (
    set LLMArg=--build-arg LLM_BACKEND=openai
    set LLMArg2=-e LLM_BACKEND=openai
) else if /i "%LLMBackend%"=="koboldcpp" (
    set LLMArg=--build-arg LLM_BACKEND=koboldcpp
    set LLMArg2=-e LLM_BACKEND=koboldcpp
) else (
    echo Invalid option. Exiting script.
    exit /b 1
)

:: Get the current directory in Windows format
cd /d %~dp0
:: Convert the current Windows directory to WSL path format and store it in a variable
for /f "tokens=*" %%i in ('wsl wslpath -a "%CD%"') do set WSL_CURRENT_DIR=%%i
:: Use the variable to copy the Dockerfile into the desired location in WSL
wsl -d %WSLName% -e sudo mkdir -p /home/%LinuxUsername%/LLM_server
if NOT %ERRORLEVEL% == 0 (
    echo LLM SERVER: ERROR: Failed to create server directory.
    pause
    exit /b %ERRORLEVEL%
)
wsl -d %WSLName% -e sudo cp "%WSL_CURRENT_DIR%/Dockerfile" /home/%LinuxUsername%/LLM_server
if NOT %ERRORLEVEL% == 0 (
    echo LLM SERVER: ERROR: Failed to copy server Dockerfile.
    pause
    exit /b %ERRORLEVEL%
)
wsl -d %WSLName% -e sudo cp "%WSL_CURRENT_DIR%/start_llm_service.sh" /home/%LinuxUsername%/LLM_server
if NOT %ERRORLEVEL% == 0 (
    echo LLM SERVER: ERROR: Failed to copy server startup script.
    pause
    exit /b %ERRORLEVEL%
)


echo LLM SERVER: Checking if Docker daemon is running...

REM Check if dockerd is running
wsl -d %WSLName% -- pgrep dockerd >nul 2>&1
if NOT %ERRORLEVEL% == 0 (
    echo LLM SERVER: Docker daemon not running. Starting dockerd background process
    wsl -d %WSLName% -e nohup sh -c "dockerd &"
    timeout 5 /NOBREAK >NUL
) ELSE (
    echo LLM SERVER: Docker daemon is running.
)

echo LLM SERVER: Building Docker image...

wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/LLM_server && docker build . %LLMArg% -t llm_server_docker"
if NOT %ERRORLEVEL% == 0 (
    echo LLM SERVER: ERROR: Failed to build Docker image. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo LLM SERVER: Running Docker container...
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/LLM_server && docker rm -f llm_server_docker"
wsl -d %WSLName% -e bash -c "cd /home/%LinuxUsername%/LLM_server && docker run --gpus all -d %LLMArg2% -p 5001:5001 -v /home/%LinuxUsername%/LLM_server:/home/%LinuxUsername%/LLM_server --name llm_server_docker llm_server_docker"
if NOT %ERRORLEVEL% == 0 (
    echo LLM SERVER: ERROR: Failed to run Docker container. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo LLM SERVER: AI servers running - press CTRL+C here when done playing to close this window.
pause > NUL

echo LLM SERVER: Cleaning up WSL state...
wsl -t %WSLName%
if NOT %ERRORLEVEL% == 0 (
    echo LLM SERVER: ERROR: Failed to terminate WSL instance. Please check the log above for details.
    pause
    exit /b %ERRORLEVEL%
)

echo LLM SERVER: Cleanup completed successfully.
endlocal