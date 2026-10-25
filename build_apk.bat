@echo off
chcp 65001 >nul
echo ===================================================
echo   HomeReminder PL — Сборка готового APK-файла
echo ===================================================
cd /d "D:\AI_Workspace\01_Projects\HomeReminder\mobile"
set PATH=%PATH%;C:\src\flutter\bin;D:\Antigravity\mingit\cmd;C:\Program Files\Git\cmd

C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat build apk --release

echo.
echo Готово! Ваш установочный файл APK находится здесь:
echo D:\AI_Workspace\01_Projects\HomeReminder\mobile\build\app\outputs\flutter-apk\app-release.apk
explorer.exe "D:\AI_Workspace\01_Projects\HomeReminder\mobile\build\app\outputs\flutter-apk"
pause
