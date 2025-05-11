@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Mock Driver Data Generator for Firebase
echo ===================================================
echo.
echo This script will upload mock drivers aligned with jeepney routes
echo to your Firebase database.
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

:: Create a temporary directory for our script
if not exist "temp" mkdir temp
cd temp

:: Create package.json
echo Creating package.json...
echo {^
  "name": "ipara-mock-data-uploader",^
  "version": "1.0.0",^
  "description": "Upload mock driver data to Firebase",^
  "main": "upload_drivers.js",^
  "dependencies": {^
    "firebase-admin": "^11.10.1"^
  }^
} > package.json

:: Install dependencies
echo Installing dependencies...
call npm install

:: Create the Firebase admin script
echo Creating upload script...
echo // Firebase Admin SDK setup for iPara mock data uploader > upload_drivers.js
echo const admin = require('firebase-admin'); >> upload_drivers.js
echo. >> upload_drivers.js
echo // Initialize Firebase Admin with service account >> upload_drivers.js
echo const serviceAccount = require('./serviceAccountKey.json'); >> upload_drivers.js
echo admin.initializeApp({ >> upload_drivers.js
echo   credential: admin.credential.cert(serviceAccount) >> upload_drivers.js
echo }); >> upload_drivers.js
echo. >> upload_drivers.js
echo const db = admin.firestore(); >> upload_drivers.js
echo. >> upload_drivers.js
echo // Define jeepney routes with waypoints >> upload_drivers.js
echo const routes = [ >> upload_drivers.js
echo   { >> upload_drivers.js
echo     id: 'r2', >> upload_drivers.js
echo     name: 'R2 - Gaisano-Agora-Cogon-Carmen', >> upload_drivers.js
echo     routeCode: 'R2', >> upload_drivers.js
echo     waypoints: [ >> upload_drivers.js
echo       {lat: 8.486261, lng: 124.649210}, // gaisano >> upload_drivers.js
echo       {lat: 8.488737, lng: 124.654004}, // osmena >> upload_drivers.js
echo       {lat: 8.488257, lng: 124.657648}, // agora market >> upload_drivers.js
echo       {lat: 8.484704, lng: 124.656401}, // ustp >> upload_drivers.js
echo       {lat: 8.478534, lng: 124.654355}, // pearl mont >> upload_drivers.js
echo       {lat: 8.478744, lng: 124.652822}, // pearl mont unahan >> upload_drivers.js
echo       {lat: 8.479595, lng: 124.649240}, // cogon >> upload_drivers.js
echo       {lat: 8.477819, lng: 124.642316}, // capistrano >> upload_drivers.js
echo       {lat: 8.476322, lng: 124.640128}, // yselina bridge >> upload_drivers.js
echo       {lat: 8.481712, lng: 124.637232}, // coc terminal >> upload_drivers.js
echo       {lat: 8.484994, lng: 124.637248}, // mango st >> upload_drivers.js
echo       {lat: 8.486158, lng: 124.638827}, // liceo >> upload_drivers.js
echo       {lat: 8.486261, lng: 124.649210}, // gaisano >> upload_drivers.js
echo     ] >> upload_drivers.js
echo   }, >> upload_drivers.js
echo   { >> upload_drivers.js
echo     id: 'C2', >> upload_drivers.js
echo     name: 'C2 - Patag-Gaisano-Limketkai-Cogon', >> upload_drivers.js
echo     routeCode: 'C2', >> upload_drivers.js
echo     waypoints: [ >> upload_drivers.js
echo       {lat: 8.477434, lng: 124.649630}, // Cogon >> upload_drivers.js
echo       {lat: 8.476343, lng: 124.639981}, // ysalina bridge >> upload_drivers.js
echo       {lat: 8.480251, lng: 124.637131}, // carmen cogon >> upload_drivers.js
echo       {lat: 8.485040, lng: 124.637276}, // mango st >> upload_drivers.js
echo       {lat: 8.487765, lng: 124.626766}, // Patag >> upload_drivers.js
echo       {lat: 8.486605, lng: 124.638888}, // liceo >> upload_drivers.js
echo       {lat: 8.486261, lng: 124.649210}, // gaisano >> upload_drivers.js
echo       {lat: 8.477434, lng: 124.649630}, // Cogon >> upload_drivers.js
echo     ] >> upload_drivers.js
echo   }, >> upload_drivers.js
echo   { >> upload_drivers.js
echo     id: 'RA', >> upload_drivers.js
echo     name: 'RA - Pier-Gaisano-Ayala-Cogon', >> upload_drivers.js
echo     routeCode: 'RA', >> upload_drivers.js
echo     waypoints: [ >> upload_drivers.js
echo       {lat: 8.486684, lng: 124.650807}, // Gaisano main >> upload_drivers.js
echo       {lat: 8.498177, lng: 124.660786}, // Pier >> upload_drivers.js
echo       {lat: 8.504380, lng: 124.661618}, // Macabalan Edge >> upload_drivers.js
echo       {lat: 8.503708, lng: 124.659001}, // Macabalan >> upload_drivers.js
echo       {lat: 8.498178, lng: 124.660057}, // Juliu Pacana St >> upload_drivers.js
echo       {lat: 8.476927, lng: 124.644083}, // Divisoria Plaza >> upload_drivers.js
echo       {lat: 8.476425, lng: 124.645800}, // Xavier >> upload_drivers.js
echo       {lat: 8.476817, lng: 124.652773}, // borja st >> upload_drivers.js
echo       {lat: 8.477448, lng: 124.652930}, // Roxas St >> upload_drivers.js
echo       {lat: 8.477855, lng: 124.651483}, // yacapin to vicente >> upload_drivers.js
echo       {lat: 8.480664, lng: 124.650289}, // Ebarle st >> upload_drivers.js
echo       {lat: 8.485169, lng: 124.650207}, // Ayala >> upload_drivers.js
echo       {lat: 8.486684, lng: 124.650807}, // Gaisano main >> upload_drivers.js
echo     ] >> upload_drivers.js
echo   }, >> upload_drivers.js
echo   { >> upload_drivers.js
echo     id: 'RD', >> upload_drivers.js
echo     name: 'RD - Gusa-Cugman-Cogon-Limketkai', >> upload_drivers.js
echo     routeCode: 'RD', >> upload_drivers.js
echo     waypoints: [ >> upload_drivers.js
echo       {lat: 8.469899, lng: 124.705196}, // cugman >> upload_drivers.js
echo       {lat: 8.477536, lng: 124.676559}, // Gusa >> upload_drivers.js
echo       {lat: 8.486028, lng: 124.650684}, // Gaisano >> upload_drivers.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> upload_drivers.js
echo       {lat: 8.485627, lng: 124.646200}, // capistrano >> upload_drivers.js
echo       {lat: 8.477565, lng: 124.642297}, // Divisoria >> upload_drivers.js
echo       {lat: 8.476425, lng: 124.645800}, // Xavier >> upload_drivers.js
echo       {lat: 8.476817, lng: 124.652773}, // borja >> upload_drivers.js
echo       {lat: 8.477595, lng: 124.653591}, // yacapin >> upload_drivers.js
echo       {lat: 8.484484, lng: 124.657109}, // ketkai >> upload_drivers.js
echo       {lat: 8.469899, lng: 124.705196}, // cugman >> upload_drivers.js
echo     ] >> upload_drivers.js
echo   } >> upload_drivers.js
echo ]; >> upload_drivers.js
echo. >> upload_drivers.js
echo // Filipino driver names >> upload_drivers.js
echo const firstNames = [ >> upload_drivers.js
echo   'Juan', 'Pedro', 'Miguel', 'Jose', 'Antonio', 'Ricardo', 'Eduardo', 'Francisco', >> upload_drivers.js
echo   'Roberto', 'Manuel', 'Danilo', 'Rodrigo', 'Ernesto', 'Fernando', 'Andres', >> upload_drivers.js
echo   'Maria', 'Rosa', 'Ana', 'Luisa', 'Elena', 'Josefa', 'Margarita', 'Teresita', >> upload_drivers.js
echo   'Juana', 'Rosario', 'Corazon', 'Gloria', 'Lourdes', 'Natividad', 'Remedios' >> upload_drivers.js
echo ]; >> upload_drivers.js
echo. >> upload_drivers.js
echo const lastNames = [ >> upload_drivers.js
echo   'Garcia', 'Santos', 'Reyes', 'Cruz', 'Bautista', 'Gonzales', 'Ramos', 'Aquino', >> upload_drivers.js
echo   'Diaz', 'Castro', 'Mendoza', 'Torres', 'Flores', 'Villanueva', 'Fernandez', >> upload_drivers.js
echo   'Morales', 'Perez', 'Ramirez', 'Hernandez', 'Pascual', 'Delos Santos', 'Tolentino', >> upload_drivers.js
echo   'Valdez', 'Gutierrez', 'Navarro', 'Domingo', 'Salazar', 'Del Rosario', 'Mercado' >> upload_drivers.js
echo ]; >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate a random driver name >> upload_drivers.js
echo function generateDriverName() { >> upload_drivers.js
echo   const firstName = firstNames[Math.floor(Math.random() * firstNames.length)]; >> upload_drivers.js
echo   const lastName = lastNames[Math.floor(Math.random() * lastNames.length)]; >> upload_drivers.js
echo   return `${firstName} ${lastName}`; >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate a random plate number for jeepneys >> upload_drivers.js
echo function generatePlateNumber() { >> upload_drivers.js
echo   // Format: JPN-123 >> upload_drivers.js
echo   const number = 100 + Math.floor(Math.random() * 900); >> upload_drivers.js
echo   return `JPN-${number}`; >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate a random rating between 3.0 and 5.0 >> upload_drivers.js
echo function generateRating() { >> upload_drivers.js
echo   return (3.0 + Math.random() * 2.0).toFixed(1); >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate a random capacity >> upload_drivers.js
echo function generateCapacity() { >> upload_drivers.js
echo   const maxCapacity = 20; // Jeepney max capacity >> upload_drivers.js
echo   const currentPassengers = Math.floor(Math.random() * (maxCapacity + 1)); >> upload_drivers.js
echo   return `${currentPassengers}/${maxCapacity}`; >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate a random status >> upload_drivers.js
echo function generateStatus() { >> upload_drivers.js
echo   const statuses = ['Available', 'En Route', 'Full', 'On Break']; >> upload_drivers.js
echo   return statuses[Math.floor(Math.random() * statuses.length)]; >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate a random ETA >> upload_drivers.js
echo function generateETA() { >> upload_drivers.js
echo   return 5 + Math.floor(Math.random() * 26); // 5-30 minutes >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Calculate heading based on current and next point >> upload_drivers.js
echo function calculateHeading(current, next) { >> upload_drivers.js
echo   const dLng = next.lng - current.lng; >> upload_drivers.js
echo   const y = Math.sin(dLng) * Math.cos(next.lat); >> upload_drivers.js
echo   const x = Math.cos(current.lat) * Math.sin(next.lat) - >> upload_drivers.js
echo     Math.sin(current.lat) * Math.cos(next.lat) * Math.cos(dLng); >> upload_drivers.js
echo   const bearing = Math.atan2(y, x) * 180 / Math.PI; >> upload_drivers.js
echo   return (bearing + 360) %% 360; >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate a random speed (10-40 km/h) >> upload_drivers.js
echo function generateSpeed() { >> upload_drivers.js
echo   return 2.8 + Math.random() * 8.3; // 10-40 km/h in m/s >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Generate mock drivers along routes >> upload_drivers.js
echo async function generateMockDrivers() { >> upload_drivers.js
echo   try { >> upload_drivers.js
echo     // Clear existing mock drivers >> upload_drivers.js
echo     const existingDrivers = await db.collection('driver_locations').where('isMockData', '==', true).get(); >> upload_drivers.js
echo     console.log(`Removing ${existingDrivers.size} existing mock drivers...`); >> upload_drivers.js
echo     const batch = db.batch(); >> upload_drivers.js
echo     existingDrivers.forEach(doc => { >> upload_drivers.js
echo       batch.delete(doc.ref); >> upload_drivers.js
echo     }); >> upload_drivers.js
echo     await batch.commit(); >> upload_drivers.js
echo. >> upload_drivers.js
echo     // Number of drivers per route >> upload_drivers.js
echo     const driversPerRoute = 5; >> upload_drivers.js
echo     let driverIndex = 0; >> upload_drivers.js
echo. >> upload_drivers.js
echo     // Create mock drivers for each route >> upload_drivers.js
echo     for (const route of routes) { >> upload_drivers.js
echo       console.log(`Creating ${driversPerRoute} drivers for route ${route.routeCode}...`); >> upload_drivers.js
echo. >> upload_drivers.js
echo       for (let i = 0; i < driversPerRoute; i++) { >> upload_drivers.js
echo         // Place driver at a random position along the route >> upload_drivers.js
echo         const waypointIndex = Math.floor(Math.random() * route.waypoints.length); >> upload_drivers.js
echo         const location = route.waypoints[waypointIndex]; >> upload_drivers.js
echo. >> upload_drivers.js
echo         // Calculate heading based on next waypoint >> upload_drivers.js
echo         let heading = 0; >> upload_drivers.js
echo         if (route.waypoints.length > 1) { >> upload_drivers.js
echo           const nextIndex = (waypointIndex + 1) %% route.waypoints.length; >> upload_drivers.js
echo           const nextPoint = route.waypoints[nextIndex]; >> upload_drivers.js
echo           heading = calculateHeading(location, nextPoint); >> upload_drivers.js
echo         } >> upload_drivers.js
echo. >> upload_drivers.js
echo         // Generate driver data >> upload_drivers.js
echo         const driverName = generateDriverName(); >> upload_drivers.js
echo         const plateNumber = generatePlateNumber(); >> upload_drivers.js
echo         const rating = generateRating(); >> upload_drivers.js
echo         const capacity = generateCapacity(); >> upload_drivers.js
echo         const status = generateStatus(); >> upload_drivers.js
echo         const etaMinutes = generateETA(); >> upload_drivers.js
echo         const speed = generateSpeed(); >> upload_drivers.js
echo. >> upload_drivers.js
echo         // Create a unique ID for this driver >> upload_drivers.js
echo         const docId = `mock_driver_${driverIndex++}`; >> upload_drivers.js
echo. >> upload_drivers.js
echo         // Create driver document >> upload_drivers.js
echo         await db.collection('driver_locations').doc(docId).set({ >> upload_drivers.js
echo           userId: docId, >> upload_drivers.js
echo           location: new admin.firestore.GeoPoint(location.lat, location.lng), >> upload_drivers.js
echo           heading: heading, >> upload_drivers.js
echo           speed: speed, >> upload_drivers.js
echo           isLocationVisible: true, >> upload_drivers.js
echo           isOnline: true, >> upload_drivers.js
echo           lastUpdated: admin.firestore.FieldValue.serverTimestamp(), >> upload_drivers.js
echo           puvType: 'Jeepney', >> upload_drivers.js
echo           plateNumber: plateNumber, >> upload_drivers.js
echo           capacity: capacity, >> upload_drivers.js
echo           driverName: driverName, >> upload_drivers.js
echo           rating: parseFloat(rating), >> upload_drivers.js
echo           status: status, >> upload_drivers.js
echo           etaMinutes: etaMinutes, >> upload_drivers.js
echo           isMockData: true, >> upload_drivers.js
echo           routeId: route.id, >> upload_drivers.js
echo           routeCode: route.routeCode, >> upload_drivers.js
echo           iconType: route.puvType.toLowerCase(), >> upload_drivers.js
echo           photoUrl: `https://randomuser.me/api/portraits/${Math.random() > 0.7 ? 'women' : 'men'}/${Math.floor(Math.random() * 70) + 1}.jpg` >> upload_drivers.js
echo         }); >> upload_drivers.js
echo       } >> upload_drivers.js
echo     } >> upload_drivers.js
echo. >> upload_drivers.js
echo     console.log(`Successfully created ${driverIndex} mock drivers!`); >> upload_drivers.js
echo   } catch (error) { >> upload_drivers.js
echo     console.error('Error generating mock drivers:', error); >> upload_drivers.js
echo   } >> upload_drivers.js
echo } >> upload_drivers.js
echo. >> upload_drivers.js
echo // Run the generator >> upload_drivers.js
echo generateMockDrivers().then(() => { >> upload_drivers.js
echo   console.log('Done!'); >> upload_drivers.js
echo   process.exit(0); >> upload_drivers.js
echo }).catch(error => { >> upload_drivers.js
echo   console.error('Fatal error:', error); >> upload_drivers.js
echo   process.exit(1); >> upload_drivers.js
echo }); >> upload_drivers.js

echo.
echo Script files created successfully!
echo.
echo IMPORTANT: Before running this script, you need to:
echo 1. Download your Firebase service account key from the Firebase console
echo 2. Save it as 'serviceAccountKey.json' in the 'temp' folder
echo.
echo To download your service account key:
echo 1. Go to Firebase Console: https://console.firebase.google.com/
echo 2. Select your project: ipara-fd373
echo 3. Go to Project Settings ^> Service accounts
echo 4. Click "Generate new private key"
echo 5. Save the file as "serviceAccountKey.json" in the temp folder
echo.
echo Press any key when you have added the service account key...
pause > nul

:: Check if the service account key exists
if not exist "serviceAccountKey.json" (
    echo ERROR: serviceAccountKey.json not found!
    echo Please download your Firebase service account key and try again.
    cd ..
    exit /b 1
)

echo.
echo Running the script to upload mock drivers...
echo.

:: Run the Node.js script
node upload_drivers.js

echo.
echo Script execution completed!
echo.
echo If there were no errors, mock drivers have been uploaded to your Firebase database.
echo You can now use these mock drivers in your app.
echo.

:: Clean up
cd ..
echo Do you want to keep the temporary files? (Y/N)
set /p KEEP_FILES=
if /i "%KEEP_FILES%" NEQ "Y" (
    echo Cleaning up temporary files...
    rmdir /s /q temp
)

echo.
echo Thank you for using the iPara Mock Driver Data Generator!
echo.
pause
