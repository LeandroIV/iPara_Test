@echo off
echo iPara Route Data Uploader
echo ========================
echo.

:: Create a temporary directory for our script if it doesn't exist
if not exist "temp_routes" mkdir temp_routes
cd temp_routes

:: Check if package.json exists, if not create it
if not exist "package.json" (
    echo Creating package.json...
    echo {^
      "name": "ipara-route-uploader",^
      "version": "1.0.0",^
      "description": "Upload route data to Firebase for iPara app",^
      "main": "upload_routes.js",^
      "dependencies": {^
        "firebase-admin": "^11.10.1"^
      }^
    } > package.json
)

:: Check if node_modules exists, if not install dependencies
if not exist "node_modules" (
    echo Installing dependencies...
    call npm install
)

echo.
echo IMPORTANT: Before continuing, make sure you have:
echo 1. Downloaded your Firebase service account key
echo 2. Saved it as 'serviceAccountKey.json' in the 'temp_routes' folder
echo.

:: Check if serviceAccountKey.json exists
if not exist "serviceAccountKey.json" (
    echo ERROR: serviceAccountKey.json not found in temp_routes folder.
    echo Please download your Firebase service account key and save it as 'serviceAccountKey.json' in the 'temp_routes' folder.
    cd ..
    exit /b 1
)

echo Running the script to upload routes...
echo.

:: Run the Node.js script
node upload_routes.js

echo.
echo Script execution completed!
echo.

:: Return to the original directory
cd ..

echo Do you want to keep the temporary files? (Y/N)
set /p KEEP_FILES=
if /i "%KEEP_FILES%" NEQ "Y" (
    echo Cleaning up temporary files...
    rmdir /s /q temp_routes
)

echo.
echo Done!
pause
