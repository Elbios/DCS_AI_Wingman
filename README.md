Quick and dirty instructions:

BACKEND:

0) Windows Control Panel -> "Programs and Features" -> "Turn Windows features on or off" -> select "Windows Subsystem for Linux" and "Virtual Machine Platform" -> restart Windows

1) Run powershell
2) Install WSL: `wsl --install`
3) Update WSL: `wsl --update --pre-release`
4) Install Debian WSL, refer to this link:
`https://xaviergeerinck.com/2023/02/14/installing-wsl-to-a-custom-location/`
and use this link for the distro instead of ubuntu:
`https://aka.ms/wsl-debian-gnulinux`

TIP: best way to refresh WSL/fix random WSL issues is restarting Windows, second best is `wsl --shutdown` and waiting at least 10 seconds
TIP2: use `wsl hostname -I` to find out your WSL IP - use that to access backend services in browser on host

5) Double-click on STT_server/install_stt_in_WSL.bat if you want STT service installed (OpenAI Whisper, local)
6) Double-click on STT_server/run_stt_in_WSL.bat when you want to have STT server running (first launch will be slower)
7) Double-click on TTS_server/install_tts_in_WSL.bat if you want TTS service installed (Coqui XTTSv2 API server and/or XTTS+RVC gradio demo for testing)
8) Double-click on TTS_server/run_tts_in_WSL.bat when you want to have TTS server running (first launch will be slower)

Expect WSL will eat 40GB+ disk space.


FRONTEND:
When selected backend services are running, run `python client_frontend.py` to run the client app which listens to the microphone and converts voice to text with STT.

BUILDING RELEASE:
1) Download `https://www.gyan.dev/ffmpeg/builds/ffmpeg-git-essentials.7z`
2) Extract ffmpeg.exe to ffmpeg folder in repo
3) pyinstaller --add-data "ffmpeg;ffmpeg" client_frontend.py
4) Result will be created in `dist` folder

DEBUGGING:
`wsl -d Debian`
`docker ps`
`docker logs stt_server_docker`
`docker logs tts_server_docker`
`cat /home/debian/TTS_server/coqui_xtts_server_log.txt`
`cat /home/debian/STT_server/whispercpp_log.txt`
