@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Service Account Key Setup
echo ===================================================
echo.
echo This script will help you set up your Firebase service account key
echo for use with the mock data generators.
echo.

:MENU
echo Choose an option:
echo 1. Create directories for service account key
echo 2. Copy existing service account key to required locations
echo 3. Open Firebase console to download service account key
echo 4. Exit
echo.
set /p CHOICE="Enter your choice (1-4): "

if "%CHOICE%"=="1" (
    echo.
    echo Creating directories...
    
    if not exist temp_puv (
        mkdir temp_puv
        echo Created temp_puv directory
    ) else (
        echo temp_puv directory already exists
    )
    
    if not exist temp_commuters (
        mkdir temp_commuters
        echo Created temp_commuters directory
    ) else (
        echo temp_commuters directory already exists
    )
    
    echo.
    echo Directories created successfully!
    echo.
    goto MENU
    
) else if "%CHOICE%"=="2" (
    echo.
    echo This will copy your service account key to the required locations.
    echo.
    
    set /p KEY_PATH="Enter the path to your serviceAccountKey.json file: "
    
    if not exist "%KEY_PATH%" (
        echo.
        echo ERROR: File not found at %KEY_PATH%
        echo Please check the path and try again.
        echo.
        goto MENU
    )
    
    echo.
    echo Copying service account key...
    
    if not exist temp_puv (
        mkdir temp_puv
    )
    
    if not exist temp_commuters (
        mkdir temp_commuters
    )
    
    copy "%KEY_PATH%" temp_puv\serviceAccountKey.json
    copy "%KEY_PATH%" temp_commuters\serviceAccountKey.json
    
    echo.
    echo Service account key copied successfully!
    echo.
    goto MENU
    
) else if "%CHOICE%"=="3" (
    echo.
    echo Opening Firebase console...
    echo.
    echo Please follow these steps:
    echo 1. Go to Project settings
    echo 2. Go to Service accounts tab
    echo 3. Click "Generate new private key"
    echo 4. Save the file as "serviceAccountKey.json"
    echo 5. Copy this file to the temp_puv and temp_commuters folders
    echo.
    echo Press any key to open the Firebase console...
    pause > nul
    
    start https://console.firebase.google.com/
    
    echo.
    goto MENU
    
) else if "%CHOICE%"=="4" (
    echo.
    echo Thank you for using the iPara Service Account Key Setup!
    echo.
    exit /b 0
    
) else (
    echo.
    echo Invalid choice. Please try again.
    echo.
    goto MENU
)
