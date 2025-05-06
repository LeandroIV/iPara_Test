@echo off
echo iPara Terminal Runner
echo ====================
echo.
echo This script will help you run the app and restart it when needed.
echo.

:menu
echo Choose an option:
echo 1. Start app (flutter run)
echo 2. Build and install manually
echo 3. Install existing APK
echo 4. Exit
echo.

set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" (
    echo.
    echo Starting app with flutter run...
    echo.
    echo Hot reload/restart commands:
    echo - Press 'r' for hot reload (preserves state)
    echo - Press 'R' for hot restart (resets state)
    echo - Press 'q' to quit
    echo.
    flutter run
    goto menu
) else if "%choice%"=="2" (
    echo.
    echo Building and installing manually...
    echo.
    
    echo Building APK...
    flutter build apk --debug
    
    if %ERRORLEVEL% neq 0 (
        echo Error building APK.
        pause
        goto menu
    )
    
    echo Installing APK...
    adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
    
    if %ERRORLEVEL% neq 0 (
        echo Error installing APK.
        pause
        goto menu
    )
    
    echo Launching app...
    adb shell am start -n com.example.ipara_new/com.example.ipara_new.MainActivity
    
    echo App built, installed, and launched successfully!
    echo.
    goto menu
) else if "%choice%"=="3" (
    echo.
    echo Installing existing APK...
    echo.
    
    echo Installing APK...
    adb install -r "android\app\build\outputs\apk\debug\app-debug.apk"
    
    if %ERRORLEVEL% neq 0 (
        echo Error installing APK. Trying alternative path...
        adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
        
        if %ERRORLEVEL% neq 0 (
            echo Error installing APK from alternative path.
            pause
            goto menu
        )
    )
    
    echo Launching app...
    adb shell am start -n com.example.ipara_new/com.example.ipara_new.MainActivity
    
    echo App installed and launched successfully!
    echo.
    goto menu
) else if "%choice%"=="4" (
    exit /b 0
) else (
    echo Invalid choice. Please try again.
    goto menu
)
