@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Mock Data Generator for Firebase (FIXED VERSION)
echo ===================================================
echo.
echo This script will upload mock data to your Firebase database:
echo 1. Operators and their vehicles
echo 2. Drivers aligned with jeepney routes
echo 3. Associate drivers with vehicles
echo.

:: Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in PATH.
    echo Please install Node.js from https://nodejs.org/
    exit /b 1
)

:: Check if npm is installed
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npm is not installed or not in PATH.
    exit /b 1
)

echo.
echo What would you like to do?
echo 1. Upload operators and vehicles
echo 2. Upload drivers on routes
echo 3. Associate drivers with vehicles
echo 4. Run all (complete setup)
echo.
set /p CHOICE=Enter your choice (1-4): 

if "%CHOICE%"=="1" (
    echo.
    echo Step 1: Uploading operators and vehicles...
    echo.
    
    echo IMPORTANT: Before continuing, make sure you have:
    echo 1. Downloaded your Firebase service account key
    echo 2. Saved it as 'serviceAccountKey.json' in the 'temp_operators' folder
    echo.
    echo Press any key when you're ready...
    pause > nul
    
    cd temp_operators
    node upload_operators_fixed.js
    cd ..
    
) else if "%CHOICE%"=="2" (
    echo.
    echo Step 2: Uploading drivers on routes...
    echo.
    
    echo IMPORTANT: Before continuing, make sure you have:
    echo 1. Downloaded your Firebase service account key
    echo 2. Saved it as 'serviceAccountKey.json' in the 'temp' folder
    echo.
    echo Press any key when you're ready...
    pause > nul
    
    cd temp
    node upload_drivers_fixed.js
    cd ..
    
) else if "%CHOICE%"=="3" (
    echo.
    echo Step 3: Associating drivers with vehicles...
    echo.
    
    echo IMPORTANT: Before continuing, make sure you have:
    echo 1. Downloaded your Firebase service account key
    echo 2. Saved it as 'serviceAccountKey.json' in the 'temp_master' folder
    echo.
    echo Press any key when you're ready...
    pause > nul
    
    cd temp_master
    node associate_drivers_vehicles_fixed.js
    cd ..
    
) else if "%CHOICE%"=="4" (
    echo.
    echo Running all steps in sequence...
    echo.
    
    echo IMPORTANT: Before continuing, make sure you have:
    echo 1. Downloaded your Firebase service account key
    echo 2. Saved it as 'serviceAccountKey.json' in ALL of these folders:
    echo    - temp_operators
    echo    - temp
    echo    - temp_master
    echo.
    echo Press any key when you're ready...
    pause > nul
    
    echo.
    echo Step 1: Uploading operators and vehicles...
    echo.
    cd temp_operators
    node upload_operators_fixed.js
    cd ..
    
    echo.
    echo Step 2: Uploading drivers on routes...
    echo.
    cd temp
    node upload_drivers_fixed.js
    cd ..
    
    echo.
    echo Step 3: Associating drivers with vehicles...
    echo.
    cd temp_master
    node associate_drivers_vehicles_fixed.js
    cd ..
    
) else (
    echo Invalid choice!
    exit /b 1
)

echo.
echo Process completed!
echo.
echo Thank you for using the iPara Mock Data Generator!
echo.
pause
