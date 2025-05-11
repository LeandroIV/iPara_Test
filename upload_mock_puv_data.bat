@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Mock Data Generator for Buses, Multicabs, and Motorelas
echo ===================================================
echo.
echo This script will upload mock data to your Firebase database:
echo 1. Bus drivers aligned with R3 route
echo 2. Multicab drivers aligned with RB route
echo 3. Motorela drivers aligned with BLUE route
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

:: Create temp directory if it doesn't exist
if not exist temp_puv (
    mkdir temp_puv
    echo Created temp_puv directory
)

:: Install required packages
echo Installing required packages...
cd temp_puv
call npm init -y
call npm install firebase-admin

:: Create the Firebase admin script
echo Creating upload script...
echo // Firebase Admin SDK setup for iPara mock PUV data uploader > upload_puv_drivers.js
echo const admin = require('firebase-admin'); >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Initialize Firebase Admin with service account >> upload_puv_drivers.js
echo const serviceAccount = require('./serviceAccountKey.json'); >> upload_puv_drivers.js
echo admin.initializeApp({ >> upload_puv_drivers.js
echo   credential: admin.credential.cert(serviceAccount) >> upload_puv_drivers.js
echo }); >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo const db = admin.firestore(); >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Define PUV routes with waypoints >> upload_puv_drivers.js
echo const routes = [ >> upload_puv_drivers.js
echo   { >> upload_puv_drivers.js
echo     id: 'R3', >> upload_puv_drivers.js
echo     name: 'R3 - Lapasan-Cogon Market (Loop)', >> upload_puv_drivers.js
echo     routeCode: 'R3', >> upload_puv_drivers.js
echo     puvType: 'Bus', >> upload_puv_drivers.js
echo     waypoints: [ >> upload_puv_drivers.js
echo       {lat: 8.490123, lng: 124.652781}, // Lapasan >> upload_puv_drivers.js
echo       {lat: 8.486028, lng: 124.650684}, // Gaisano >> upload_puv_drivers.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon Market >> upload_puv_drivers.js
echo       {lat: 8.477595, lng: 124.653591}, // Yacapin >> upload_puv_drivers.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> upload_puv_drivers.js
echo       {lat: 8.490123, lng: 124.652781}, // Back to Lapasan >> upload_puv_drivers.js
echo     ] >> upload_puv_drivers.js
echo   }, >> upload_puv_drivers.js
echo   { >> upload_puv_drivers.js
echo     id: 'RB', >> upload_puv_drivers.js
echo     name: 'RB - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan', >> upload_puv_drivers.js
echo     routeCode: 'RB', >> upload_puv_drivers.js
echo     puvType: 'Multicab', >> upload_puv_drivers.js
echo     waypoints: [ >> upload_puv_drivers.js
echo       {lat: 8.498177, lng: 124.660786}, // Pier >> upload_puv_drivers.js
echo       {lat: 8.486684, lng: 124.650807}, // Puregold/Gaisano >> upload_puv_drivers.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> upload_puv_drivers.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> upload_puv_drivers.js
echo       {lat: 8.498178, lng: 124.660057}, // Julio Pacana St >> upload_puv_drivers.js
echo       {lat: 8.503708, lng: 124.659001}, // Macabalan >> upload_puv_drivers.js
echo     ] >> upload_puv_drivers.js
echo   }, >> upload_puv_drivers.js
echo   { >> upload_puv_drivers.js
echo     id: 'BLUE', >> upload_puv_drivers.js
echo     name: 'BLUE - Agora-Osmena-Cogon (Loop)', >> upload_puv_drivers.js
echo     routeCode: 'BLUE', >> upload_puv_drivers.js
echo     puvType: 'Motorela', >> upload_puv_drivers.js
echo     waypoints: [ >> upload_puv_drivers.js
echo       {lat: 8.488257, lng: 124.657648}, // Agora Market >> upload_puv_drivers.js
echo       {lat: 8.488737, lng: 124.654004}, // Osmena >> upload_puv_drivers.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> upload_puv_drivers.js
echo       {lat: 8.484704, lng: 124.656401}, // USTP >> upload_puv_drivers.js
echo       {lat: 8.488257, lng: 124.657648}, // Back to Agora >> upload_puv_drivers.js
echo     ] >> upload_puv_drivers.js
echo   } >> upload_puv_drivers.js
echo ]; >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Filipino driver names >> upload_puv_drivers.js
echo const firstNames = [ >> upload_puv_drivers.js
echo   'Juan', 'Pedro', 'Miguel', 'Jose', 'Antonio', 'Ricardo', 'Eduardo', 'Francisco', >> upload_puv_drivers.js
echo   'Roberto', 'Manuel', 'Danilo', 'Rodrigo', 'Ernesto', 'Fernando', 'Andres', >> upload_puv_drivers.js
echo   'Maria', 'Rosa', 'Ana', 'Luisa', 'Elena', 'Josefa', 'Margarita', 'Teresita', >> upload_puv_drivers.js
echo   'Juana', 'Rosario', 'Corazon', 'Gloria', 'Lourdes', 'Natividad', 'Remedios' >> upload_puv_drivers.js
echo ]; >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo const lastNames = [ >> upload_puv_drivers.js
echo   'Garcia', 'Santos', 'Reyes', 'Cruz', 'Bautista', 'Gonzales', 'Ramos', 'Aquino', >> upload_puv_drivers.js
echo   'Diaz', 'Castro', 'Mendoza', 'Torres', 'Flores', 'Villanueva', 'Fernandez', >> upload_puv_drivers.js
echo   'Morales', 'Perez', 'Ramirez', 'Hernandez', 'Pascual', 'Delos Santos', 'Tolentino', >> upload_puv_drivers.js
echo   'Valdez', 'Gutierrez', 'Navarro', 'Domingo', 'Salazar', 'Del Rosario', 'Mercado' >> upload_puv_drivers.js
echo ]; >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate a random driver name >> upload_puv_drivers.js
echo function generateDriverName() { >> upload_puv_drivers.js
echo   const firstName = firstNames[Math.floor(Math.random() * firstNames.length)]; >> upload_puv_drivers.js
echo   const lastName = lastNames[Math.floor(Math.random() * lastNames.length)]; >> upload_puv_drivers.js
echo   return `${firstName} ${lastName}`; >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate a random plate number based on PUV type >> upload_puv_drivers.js
echo function generatePlateNumber(puvType) { >> upload_puv_drivers.js
echo   let prefix; >> upload_puv_drivers.js
echo   switch(puvType) { >> upload_puv_drivers.js
echo     case 'Bus': >> upload_puv_drivers.js
echo       prefix = 'BUS'; >> upload_puv_drivers.js
echo       break; >> upload_puv_drivers.js
echo     case 'Multicab': >> upload_puv_drivers.js
echo       prefix = 'MCB'; >> upload_puv_drivers.js
echo       break; >> upload_puv_drivers.js
echo     case 'Motorela': >> upload_puv_drivers.js
echo       prefix = 'MTR'; >> upload_puv_drivers.js
echo       break; >> upload_puv_drivers.js
echo     default: >> upload_puv_drivers.js
echo       prefix = 'PUV'; >> upload_puv_drivers.js
echo   } >> upload_puv_drivers.js
echo   const number = 100 + Math.floor(Math.random() * 900); >> upload_puv_drivers.js
echo   return `${prefix}-${number}`; >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate a random speed (10-40 km/h) >> upload_puv_drivers.js
echo function generateSpeed() { >> upload_puv_drivers.js
echo   return 2.8 + Math.random() * 8.3; // 10-40 km/h in m/s >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate a random rating between 3.0 and 5.0 >> upload_puv_drivers.js
echo function generateRating() { >> upload_puv_drivers.js
echo   return (3.0 + Math.random() * 2.0).toFixed(1); >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate a random capacity based on PUV type >> upload_puv_drivers.js
echo function generateCapacity(puvType) { >> upload_puv_drivers.js
echo   let maxCapacity; >> upload_puv_drivers.js
echo   switch(puvType) { >> upload_puv_drivers.js
echo     case 'Bus': >> upload_puv_drivers.js
echo       maxCapacity = 50; >> upload_puv_drivers.js
echo       break; >> upload_puv_drivers.js
echo     case 'Multicab': >> upload_puv_drivers.js
echo       maxCapacity = 12; >> upload_puv_drivers.js
echo       break; >> upload_puv_drivers.js
echo     case 'Motorela': >> upload_puv_drivers.js
echo       maxCapacity = 8; >> upload_puv_drivers.js
echo       break; >> upload_puv_drivers.js
echo     default: >> upload_puv_drivers.js
echo       maxCapacity = 10; >> upload_puv_drivers.js
echo   } >> upload_puv_drivers.js
echo   const currentPassengers = Math.floor(Math.random() * (maxCapacity + 1)); >> upload_puv_drivers.js
echo   return `${currentPassengers}/${maxCapacity}`; >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate a random status >> upload_puv_drivers.js
echo function generateStatus() { >> upload_puv_drivers.js
echo   const statuses = ['Available', 'En Route', 'Full', 'On Break']; >> upload_puv_drivers.js
echo   return statuses[Math.floor(Math.random() * statuses.length)]; >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate a random ETA >> upload_puv_drivers.js
echo function generateETA() { >> upload_puv_drivers.js
echo   return 5 + Math.floor(Math.random() * 26); // 5-30 minutes >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Calculate heading based on current and next point >> upload_puv_drivers.js
echo function calculateHeading(current, next) { >> upload_puv_drivers.js
echo   const dLng = next.lng - current.lng; >> upload_puv_drivers.js
echo   const y = Math.sin(dLng * (Math.PI / 180)) * Math.cos(next.lat * (Math.PI / 180)); >> upload_puv_drivers.js
echo   const x = Math.cos(current.lat * (Math.PI / 180)) * Math.sin(next.lat * (Math.PI / 180)) - >> upload_puv_drivers.js
echo           Math.sin(current.lat * (Math.PI / 180)) * Math.cos(next.lat * (Math.PI / 180)) * Math.cos(dLng * (Math.PI / 180)); >> upload_puv_drivers.js
echo   let heading = Math.atan2(y, x) * (180 / Math.PI); >> upload_puv_drivers.js
echo   if (heading < 0) { >> upload_puv_drivers.js
echo     heading += 360; >> upload_puv_drivers.js
echo   } >> upload_puv_drivers.js
echo   return heading; >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Generate mock PUV drivers >> upload_puv_drivers.js
echo async function generateMockPUVDrivers() { >> upload_puv_drivers.js
echo   try { >> upload_puv_drivers.js
echo     // Clear existing mock drivers for these PUV types >> upload_puv_drivers.js
echo     const puvTypes = ['Bus', 'Multicab', 'Motorela']; >> upload_puv_drivers.js
echo     for (const puvType of puvTypes) { >> upload_puv_drivers.js
echo       const existingDrivers = await db.collection('driver_locations') >> upload_puv_drivers.js
echo         .where('isMockData', '==', true) >> upload_puv_drivers.js
echo         .where('puvType', '==', puvType) >> upload_puv_drivers.js
echo         .get(); >> upload_puv_drivers.js
echo       console.log(`Removing ${existingDrivers.size} existing mock ${puvType} drivers...`); >> upload_puv_drivers.js
echo       const batch = db.batch(); >> upload_puv_drivers.js
echo       existingDrivers.forEach(doc => { >> upload_puv_drivers.js
echo         batch.delete(doc.ref); >> upload_puv_drivers.js
echo       }); >> upload_puv_drivers.js
echo       await batch.commit(); >> upload_puv_drivers.js
echo     } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo     // Number of drivers per route >> upload_puv_drivers.js
echo     const driversPerRoute = 5; >> upload_puv_drivers.js
echo     let driverIndex = 0; >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo     // Create mock drivers for each route >> upload_puv_drivers.js
echo     for (const route of routes) { >> upload_puv_drivers.js
echo       console.log(`Creating ${driversPerRoute} ${route.puvType} drivers for route ${route.routeCode}...`); >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo       for (let i = 0; i < driversPerRoute; i++) { >> upload_puv_drivers.js
echo         // Place driver at a random position along the route >> upload_puv_drivers.js
echo         const waypointIndex = Math.floor(Math.random() * route.waypoints.length); >> upload_puv_drivers.js
echo         const location = route.waypoints[waypointIndex]; >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo         // Calculate heading based on next waypoint >> upload_puv_drivers.js
echo         let heading = 0; >> upload_puv_drivers.js
echo         if (route.waypoints.length > 1) { >> upload_puv_drivers.js
echo           const nextIndex = (waypointIndex + 1) % route.waypoints.length; >> upload_puv_drivers.js
echo           const nextPoint = route.waypoints[nextIndex]; >> upload_puv_drivers.js
echo           heading = calculateHeading(location, nextPoint); >> upload_puv_drivers.js
echo         } else { >> upload_puv_drivers.js
echo           heading = Math.random() * 360; >> upload_puv_drivers.js
echo         } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo         // Generate driver details >> upload_puv_drivers.js
echo         const driverName = generateDriverName(); >> upload_puv_drivers.js
echo         const plateNumber = generatePlateNumber(route.puvType); >> upload_puv_drivers.js
echo         const rating = generateRating(); >> upload_puv_drivers.js
echo         const capacity = generateCapacity(route.puvType); >> upload_puv_drivers.js
echo         const status = generateStatus(); >> upload_puv_drivers.js
echo         const etaMinutes = generateETA(); >> upload_puv_drivers.js
echo         const speed = generateSpeed(); >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo         // Create a unique ID for this driver >> upload_puv_drivers.js
echo         const docId = `mock_${route.puvType.toLowerCase()}_${driverIndex++}`; >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo         // Create driver document >> upload_puv_drivers.js
echo         await db.collection('driver_locations').doc(docId).set({ >> upload_puv_drivers.js
echo           userId: docId, >> upload_puv_drivers.js
echo           location: new admin.firestore.GeoPoint(location.lat, location.lng), >> upload_puv_drivers.js
echo           heading: heading, >> upload_puv_drivers.js
echo           speed: speed, >> upload_puv_drivers.js
echo           isLocationVisible: true, >> upload_puv_drivers.js
echo           isOnline: true, >> upload_puv_drivers.js
echo           lastUpdated: admin.firestore.FieldValue.serverTimestamp(), >> upload_puv_drivers.js
echo           puvType: route.puvType, >> upload_puv_drivers.js
echo           plateNumber: plateNumber, >> upload_puv_drivers.js
echo           capacity: capacity, >> upload_puv_drivers.js
echo           driverName: driverName, >> upload_puv_drivers.js
echo           rating: rating, >> upload_puv_drivers.js
echo           status: status, >> upload_puv_drivers.js
echo           etaMinutes: etaMinutes, >> upload_puv_drivers.js
echo           isMockData: true, >> upload_puv_drivers.js
echo           routeId: route.id, >> upload_puv_drivers.js
echo           routeCode: route.routeCode, >> upload_puv_drivers.js
echo           iconType: route.puvType.toLowerCase(), >> upload_puv_drivers.js
echo           photoUrl: `https://randomuser.me/api/portraits/${Math.random() > 0.7 ? 'women' : 'men'}/${Math.floor(Math.random() * 70) + 1}.jpg` >> upload_puv_drivers.js
echo         }); >> upload_puv_drivers.js
echo       } >> upload_puv_drivers.js
echo     } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo     console.log(`Successfully created ${driverIndex} mock PUV drivers!`); >> upload_puv_drivers.js
echo   } catch (error) { >> upload_puv_drivers.js
echo     console.error('Error generating mock PUV drivers:', error); >> upload_puv_drivers.js
echo   } >> upload_puv_drivers.js
echo } >> upload_puv_drivers.js
echo. >> upload_puv_drivers.js
echo // Run the generator >> upload_puv_drivers.js
echo generateMockPUVDrivers(); >> upload_puv_drivers.js

echo.
echo IMPORTANT: Before continuing, make sure you have:
echo 1. Downloaded your Firebase service account key
echo 2. Saved it as 'serviceAccountKey.json' in the 'temp_puv' folder
echo.

:: Check if serviceAccountKey.json exists
if not exist temp_puv\serviceAccountKey.json (
    echo ERROR: serviceAccountKey.json not found in temp_puv folder.
    echo Please download your Firebase service account key and save it as 'serviceAccountKey.json' in the 'temp_puv' folder.
    cd ..
    exit /b 1
)

echo Press any key when you're ready...
pause > nul

echo.
echo Uploading mock PUV drivers...
node upload_puv_drivers.js
cd ..

echo.
echo Process completed!
echo.
echo Thank you for using the iPara Mock PUV Data Generator!
echo.
pause
