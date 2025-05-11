@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Complete Mock Data Generator
echo ===================================================
echo.
echo This script will upload all mock data to your Firebase database:
echo 1. Bus, Multicab, and Motorela drivers
echo 2. Commuters looking for these PUV types
echo.
echo IMPORTANT: Before running this script, make sure you have:
echo 1. Downloaded your Firebase service account key
echo 2. Set up the service account key using setup_service_account.bat
echo.

:: Check if service account key setup script exists
if not exist setup_service_account.bat (
    echo ERROR: setup_service_account.bat not found.
    echo Please make sure all scripts are in the same directory.
    exit /b 1
)

:MENU
echo Choose an option:
echo 1. Upload mock PUV drivers (Bus, Multicab, Motorela)
echo 2. Upload mock commuters
echo 3. Upload both drivers and commuters
echo 4. Set up service account key
echo 5. Exit
echo.
set /p CHOICE="Enter your choice (1-5): "

if "%CHOICE%"=="1" (
    call upload_mock_puv_data.bat
    goto MENU
) else if "%CHOICE%"=="2" (
    call upload_mock_commuters.bat
    goto MENU
) else if "%CHOICE%"=="3" (
    echo.
    echo Uploading all mock data...
    echo.
    call upload_mock_puv_data.bat
    call upload_mock_commuters.bat
    echo.
    echo All mock data has been uploaded successfully!
    echo.
    goto MENU
) else if "%CHOICE%"=="4" (
    call setup_service_account.bat
    goto MENU
) else if "%CHOICE%"=="5" (
    echo.
    echo Thank you for using the iPara Mock Data Generator!
    echo.
    exit /b 0
) else (
    echo.
    echo Invalid choice. Please try again.
    echo.
    goto MENU
)
