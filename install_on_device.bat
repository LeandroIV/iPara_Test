@echo off
echo iPara Device Installation Tool
echo ===========================
echo.

echo Checking for connected devices...
adb devices
echo.

set /p continue="Continue with installation? (Y/N): "
if /i "%continue%" neq "Y" exit /b

echo.
echo Building APK...
flutter build apk --debug
if %ERRORLEVEL% neq 0 (
    echo Error building APK.
    pause
    exit /b 1
)

echo.
echo Installing on connected device(s)...
adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
if %ERRORLEVEL% neq 0 (
    echo Error installing APK. Trying alternative path...
    adb install -r "android\app\build\outputs\apk\debug\app-debug.apk"
    
    if %ERRORLEVEL% neq 0 (
        echo Error installing APK from alternative path.
        pause
        exit /b 1
    )
)

echo.
echo App installed successfully!
echo.
echo To launch the app, find "iPara" in your app drawer.
echo.
pause
