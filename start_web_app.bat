@echo off
chcp 65001 >nul
echo ===============================================================
echo   HomeReminder PL — Веб-приложение (PWA) для телефона и ПК
echo ===============================================================
echo.
echo Сейчас запустится сервер. Откройте на телефоне (в той же сети Wi-Fi)
echo один из ваших IPv4-адресов ниже с портом :8080
echo (например: http://192.168.X.X:8080)
echo.
ipconfig | findstr /i "IPv4"
echo.
echo На ПК открывается автоматически: http://localhost:8080
echo ===============================================================
start "" "http://localhost:8080"

if exist "D:\AI_Workspace\01_Projects\Персональный тренер\backend\.venv\Scripts\python.exe" (
    cd /d "D:\AI_Workspace\01_Projects\HomeReminder\backend"
    "D:\AI_Workspace\01_Projects\Персональный тренер\backend\.venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8080
) else (
    cd /d "D:\AI_Workspace\01_Projects\HomeReminder\mobile\build\web"
    python -m http.server 8080 --bind 0.0.0.0
)
pause
