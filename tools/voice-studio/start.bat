@echo off
rem Pilo voice studio - double-click to start on Windows.
rem Needs Node.js 18+ and ffmpeg on PATH (see README.md).
chcp 65001 >nul
cd /d "%~dp0"
where node >nul 2>nul || (echo Node.js is not installed: https://nodejs.org & pause & exit /b 1)
where ffmpeg >nul 2>nul || echo [warning] ffmpeg not found - install it: winget install Gyan.FFmpeg
if not exist node_modules (
  echo Installing packages...
  call npm install || (pause & exit /b 1)
)
rem the page opens once the build is done and the server is up
start "" /min cmd /c "timeout /t 15 /nobreak >nul & start http://127.0.0.1:5174"
call npm start
pause
