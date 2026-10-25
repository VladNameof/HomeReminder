@echo off
chcp 65001 >nul
echo ===================================================
echo   HomeReminder PL — Запуск под Android
echo ===================================================
echo.

REM 1. Запускаем локальный Backend (FastAPI + ИИ-оракул + Польские магазины) в отдельном окне
if exist "D:\AI_Workspace\01_Projects\Персональный тренер\backend\.venv\Scripts\python.exe" (
    echo [1/2] Запуск Backend сервера на порту 8000...
    start "HomeReminder Backend" cmd /k "cd /d D:\AI_Workspace\01_Projects\HomeReminder\backend && D:\AI_Workspace\01_Projects\Персональный тренер\backend\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
) else (
    echo [1/2] Запуск Backend через uv...
    start "HomeReminder Backend" cmd /k "cd /d D:\AI_Workspace\01_Projects\HomeReminder\backend && uv run uvicorn app.main:app --host 0.0.0.0 --port 8000"
)

REM 2. Собираем и запускаем Flutter-приложение на подключенном Android-устройстве (или собираем APK)
echo [2/2] Подготовка мобильного приложения (Flutter Android)...
cd /d "D:\AI_Workspace\01_Projects\HomeReminder\mobile"
set PATH=%PATH%;C:\src\flutter\bin;D:\Antigravity\mingit\cmd;C:\Program Files\Git\cmd

C:\src\flutter\bin\flutter.bat pub get
echo.
echo Поиск подключенных Android-устройств...
C:\src\flutter\bin\flutter.bat devices
echo.
echo Запускаем приложение на Android (если телефон подключен по USB/Wi-Fi с отладкой)...
C:\src\flutter\bin\flutter.bat run
pause
