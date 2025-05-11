@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Mock Data Generator for New Routes
echo ===================================================
echo.
echo This script will generate mock data for:
echo 1. Bus drivers on R3 route
echo 2. Multicab drivers on RB route
echo 3. Motorela drivers on BLUE route
echo 4. Commuters looking for these PUV types
echo.

:: Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed or not in PATH.
    echo Please install Node.js from https://nodejs.org/
    exit /b 1
)

:: Check for existing directories
echo Checking for existing directories...

:: For drivers
if exist temp_puv (
    echo Found temp_puv directory
    set DRIVER_DIR=temp_puv
) else (
    echo Creating temp_puv directory
    mkdir temp_puv
    set DRIVER_DIR=temp_puv
)

:: For commuters
if exist temp_commuters (
    echo Found temp_commuters directory
    set COMMUTER_DIR=temp_commuters
) else (
    echo Creating temp_commuters directory
    mkdir temp_commuters
    set COMMUTER_DIR=temp_commuters
)

echo.
echo IMPORTANT: Before continuing, make sure you have:
echo 1. Downloaded your Firebase service account key
echo 2. Saved it as 'serviceAccountKey.json' in both:
echo    - %DRIVER_DIR% folder
echo    - %COMMUTER_DIR% folder
echo.
echo Press any key when you're ready...
pause > nul

:: Create driver script
echo Creating driver script...
echo // Firebase Admin SDK setup for iPara mock PUV data uploader > %DRIVER_DIR%\generate_drivers.js
echo const admin = require('firebase-admin'); >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Initialize Firebase Admin with service account >> %DRIVER_DIR%\generate_drivers.js
echo const serviceAccount = require('./serviceAccountKey.json'); >> %DRIVER_DIR%\generate_drivers.js
echo admin.initializeApp({ >> %DRIVER_DIR%\generate_drivers.js
echo   credential: admin.credential.cert(serviceAccount) >> %DRIVER_DIR%\generate_drivers.js
echo }); >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo const db = admin.firestore(); >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Define PUV routes with waypoints >> %DRIVER_DIR%\generate_drivers.js
echo const routes = [ >> %DRIVER_DIR%\generate_drivers.js
echo   { >> %DRIVER_DIR%\generate_drivers.js
echo     id: 'R3', >> %DRIVER_DIR%\generate_drivers.js
echo     name: 'R3 - Lapasan-Cogon Market (Loop)', >> %DRIVER_DIR%\generate_drivers.js
echo     routeCode: 'R3', >> %DRIVER_DIR%\generate_drivers.js
echo     puvType: 'Bus', >> %DRIVER_DIR%\generate_drivers.js
echo     waypoints: [ >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.490123, lng: 124.652781}, // Lapasan >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.486028, lng: 124.650684}, // Gaisano >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon Market >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.477595, lng: 124.653591}, // Yacapin >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.490123, lng: 124.652781}, // Back to Lapasan >> %DRIVER_DIR%\generate_drivers.js
echo     ] >> %DRIVER_DIR%\generate_drivers.js
echo   }, >> %DRIVER_DIR%\generate_drivers.js
echo   { >> %DRIVER_DIR%\generate_drivers.js
echo     id: 'RB', >> %DRIVER_DIR%\generate_drivers.js
echo     name: 'RB - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan', >> %DRIVER_DIR%\generate_drivers.js
echo     routeCode: 'RB', >> %DRIVER_DIR%\generate_drivers.js
echo     puvType: 'Multicab', >> %DRIVER_DIR%\generate_drivers.js
echo     waypoints: [ >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.498177, lng: 124.660786}, // Pier >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.486684, lng: 124.650807}, // Puregold/Gaisano >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.498178, lng: 124.660057}, // Julio Pacana St >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.503708, lng: 124.659001}, // Macabalan >> %DRIVER_DIR%\generate_drivers.js
echo     ] >> %DRIVER_DIR%\generate_drivers.js
echo   }, >> %DRIVER_DIR%\generate_drivers.js
echo   { >> %DRIVER_DIR%\generate_drivers.js
echo     id: 'BLUE', >> %DRIVER_DIR%\generate_drivers.js
echo     name: 'BLUE - Agora-Osmena-Cogon (Loop)', >> %DRIVER_DIR%\generate_drivers.js
echo     routeCode: 'BLUE', >> %DRIVER_DIR%\generate_drivers.js
echo     puvType: 'Motorela', >> %DRIVER_DIR%\generate_drivers.js
echo     waypoints: [ >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.488257, lng: 124.657648}, // Agora Market >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.488737, lng: 124.654004}, // Osmena >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.484704, lng: 124.656401}, // USTP >> %DRIVER_DIR%\generate_drivers.js
echo       {lat: 8.488257, lng: 124.657648}, // Back to Agora >> %DRIVER_DIR%\generate_drivers.js
echo     ] >> %DRIVER_DIR%\generate_drivers.js
echo   } >> %DRIVER_DIR%\generate_drivers.js
echo ]; >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Filipino driver names >> %DRIVER_DIR%\generate_drivers.js
echo const firstNames = [ >> %DRIVER_DIR%\generate_drivers.js
echo   'Juan', 'Pedro', 'Miguel', 'Jose', 'Antonio', 'Ricardo', 'Eduardo', 'Francisco', >> %DRIVER_DIR%\generate_drivers.js
echo   'Roberto', 'Manuel', 'Danilo', 'Rodrigo', 'Ernesto', 'Fernando', 'Andres', >> %DRIVER_DIR%\generate_drivers.js
echo   'Maria', 'Rosa', 'Ana', 'Luisa', 'Elena', 'Josefa', 'Margarita', 'Teresita', >> %DRIVER_DIR%\generate_drivers.js
echo   'Juana', 'Rosario', 'Corazon', 'Gloria', 'Lourdes', 'Natividad', 'Remedios' >> %DRIVER_DIR%\generate_drivers.js
echo ]; >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo const lastNames = [ >> %DRIVER_DIR%\generate_drivers.js
echo   'Garcia', 'Santos', 'Reyes', 'Cruz', 'Bautista', 'Gonzales', 'Ramos', 'Aquino', >> %DRIVER_DIR%\generate_drivers.js
echo   'Diaz', 'Castro', 'Mendoza', 'Torres', 'Flores', 'Villanueva', 'Fernandez', >> %DRIVER_DIR%\generate_drivers.js
echo   'Morales', 'Perez', 'Ramirez', 'Hernandez', 'Pascual', 'Delos Santos', 'Tolentino', >> %DRIVER_DIR%\generate_drivers.js
echo   'Valdez', 'Gutierrez', 'Navarro', 'Domingo', 'Salazar', 'Del Rosario', 'Mercado' >> %DRIVER_DIR%\generate_drivers.js
echo ]; >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate a random driver name >> %DRIVER_DIR%\generate_drivers.js
echo function generateDriverName() { >> %DRIVER_DIR%\generate_drivers.js
echo   const firstName = firstNames[Math.floor(Math.random() * firstNames.length)]; >> %DRIVER_DIR%\generate_drivers.js
echo   const lastName = lastNames[Math.floor(Math.random() * lastNames.length)]; >> %DRIVER_DIR%\generate_drivers.js
echo   return `${firstName} ${lastName}`; >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate a random plate number based on PUV type (Cagayan de Oro style) >> %DRIVER_DIR%\generate_drivers.js
echo function generatePlateNumber(puvType) { >> %DRIVER_DIR%\generate_drivers.js
echo   // For Cagayan de Oro City: >> %DRIVER_DIR%\generate_drivers.js
echo   // Buses: AAA-1234 format >> %DRIVER_DIR%\generate_drivers.js
echo   // Multicabs: MV-1234 format (UV Express/Multicab) >> %DRIVER_DIR%\generate_drivers.js
echo   // Motorelas: MC-1234 format (Motorized tricycle) >> %DRIVER_DIR%\generate_drivers.js
echo   let prefix; >> %DRIVER_DIR%\generate_drivers.js
echo   let numberFormat; >> %DRIVER_DIR%\generate_drivers.js
echo   >> %DRIVER_DIR%\generate_drivers.js
echo   switch(puvType) { >> %DRIVER_DIR%\generate_drivers.js
echo     case 'Bus': >> %DRIVER_DIR%\generate_drivers.js
echo       // Generate random 3-letter prefix for buses >> %DRIVER_DIR%\generate_drivers.js
echo       const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // Excluding I and O which can be confused with 1 and 0 >> %DRIVER_DIR%\generate_drivers.js
echo       prefix = ''; >> %DRIVER_DIR%\generate_drivers.js
echo       for (let i = 0; i < 3; i++) { >> %DRIVER_DIR%\generate_drivers.js
echo         prefix += letters.charAt(Math.floor(Math.random() * letters.length)); >> %DRIVER_DIR%\generate_drivers.js
echo       } >> %DRIVER_DIR%\generate_drivers.js
echo       numberFormat = 1000 + Math.floor(Math.random() * 9000); // 1000-9999 >> %DRIVER_DIR%\generate_drivers.js
echo       return `${prefix}-${numberFormat}`; >> %DRIVER_DIR%\generate_drivers.js
echo       >> %DRIVER_DIR%\generate_drivers.js
echo     case 'Multicab': >> %DRIVER_DIR%\generate_drivers.js
echo       prefix = 'MV'; // UV Express/Multicab >> %DRIVER_DIR%\generate_drivers.js
echo       numberFormat = 1000 + Math.floor(Math.random() * 9000); // 1000-9999 >> %DRIVER_DIR%\generate_drivers.js
echo       return `${prefix}-${numberFormat}`; >> %DRIVER_DIR%\generate_drivers.js
echo       >> %DRIVER_DIR%\generate_drivers.js
echo     case 'Motorela': >> %DRIVER_DIR%\generate_drivers.js
echo       prefix = 'MC'; // Motorized tricycle >> %DRIVER_DIR%\generate_drivers.js
echo       numberFormat = 1000 + Math.floor(Math.random() * 9000); // 1000-9999 >> %DRIVER_DIR%\generate_drivers.js
echo       return `${prefix}-${numberFormat}`; >> %DRIVER_DIR%\generate_drivers.js
echo       >> %DRIVER_DIR%\generate_drivers.js
echo     default: >> %DRIVER_DIR%\generate_drivers.js
echo       prefix = 'CDO'; >> %DRIVER_DIR%\generate_drivers.js
echo       numberFormat = 100 + Math.floor(Math.random() * 900); // 100-999 >> %DRIVER_DIR%\generate_drivers.js
echo       return `${prefix}-${numberFormat}`; >> %DRIVER_DIR%\generate_drivers.js
echo   } >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate a random speed (10-40 km/h) >> %DRIVER_DIR%\generate_drivers.js
echo function generateSpeed() { >> %DRIVER_DIR%\generate_drivers.js
echo   return 2.8 + Math.random() * 8.3; // 10-40 km/h in m/s >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate a random rating between 3.0 and 5.0 >> %DRIVER_DIR%\generate_drivers.js
echo function generateRating() { >> %DRIVER_DIR%\generate_drivers.js
echo   return (3.0 + Math.random() * 2.0).toFixed(1); >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate a random capacity based on PUV type >> %DRIVER_DIR%\generate_drivers.js
echo function generateCapacity(puvType) { >> %DRIVER_DIR%\generate_drivers.js
echo   let maxCapacity; >> %DRIVER_DIR%\generate_drivers.js
echo   switch(puvType) { >> %DRIVER_DIR%\generate_drivers.js
echo     case 'Bus': >> %DRIVER_DIR%\generate_drivers.js
echo       maxCapacity = 50; >> %DRIVER_DIR%\generate_drivers.js
echo       break; >> %DRIVER_DIR%\generate_drivers.js
echo     case 'Multicab': >> %DRIVER_DIR%\generate_drivers.js
echo       maxCapacity = 12; >> %DRIVER_DIR%\generate_drivers.js
echo       break; >> %DRIVER_DIR%\generate_drivers.js
echo     case 'Motorela': >> %DRIVER_DIR%\generate_drivers.js
echo       maxCapacity = 8; >> %DRIVER_DIR%\generate_drivers.js
echo       break; >> %DRIVER_DIR%\generate_drivers.js
echo     default: >> %DRIVER_DIR%\generate_drivers.js
echo       maxCapacity = 10; >> %DRIVER_DIR%\generate_drivers.js
echo   } >> %DRIVER_DIR%\generate_drivers.js
echo   const currentPassengers = Math.floor(Math.random() * (maxCapacity + 1)); >> %DRIVER_DIR%\generate_drivers.js
echo   return `${currentPassengers}/${maxCapacity}`; >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate a random status >> %DRIVER_DIR%\generate_drivers.js
echo function generateStatus() { >> %DRIVER_DIR%\generate_drivers.js
echo   const statuses = ['Available', 'En Route', 'Full', 'On Break']; >> %DRIVER_DIR%\generate_drivers.js
echo   return statuses[Math.floor(Math.random() * statuses.length)]; >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate a random ETA >> %DRIVER_DIR%\generate_drivers.js
echo function generateETA() { >> %DRIVER_DIR%\generate_drivers.js
echo   return 5 + Math.floor(Math.random() * 26); // 5-30 minutes >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Calculate heading based on current and next point >> %DRIVER_DIR%\generate_drivers.js
echo function calculateHeading(current, next) { >> %DRIVER_DIR%\generate_drivers.js
echo   const dLng = next.lng - current.lng; >> %DRIVER_DIR%\generate_drivers.js
echo   const y = Math.sin(dLng * (Math.PI / 180)) * Math.cos(next.lat * (Math.PI / 180)); >> %DRIVER_DIR%\generate_drivers.js
echo   const x = Math.cos(current.lat * (Math.PI / 180)) * Math.sin(next.lat * (Math.PI / 180)) - >> %DRIVER_DIR%\generate_drivers.js
echo           Math.sin(current.lat * (Math.PI / 180)) * Math.cos(next.lat * (Math.PI / 180)) * Math.cos(dLng * (Math.PI / 180)); >> %DRIVER_DIR%\generate_drivers.js
echo   let heading = Math.atan2(y, x) * (180 / Math.PI); >> %DRIVER_DIR%\generate_drivers.js
echo   if (heading < 0) { >> %DRIVER_DIR%\generate_drivers.js
echo     heading += 360; >> %DRIVER_DIR%\generate_drivers.js
echo   } >> %DRIVER_DIR%\generate_drivers.js
echo   return heading; >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Generate mock PUV drivers >> %DRIVER_DIR%\generate_drivers.js
echo async function generateMockPUVDrivers() { >> %DRIVER_DIR%\generate_drivers.js
echo   try { >> %DRIVER_DIR%\generate_drivers.js
echo     // Clear existing mock drivers for these PUV types >> %DRIVER_DIR%\generate_drivers.js
echo     const puvTypes = ['Bus', 'Multicab', 'Motorela']; >> %DRIVER_DIR%\generate_drivers.js
echo     for (const puvType of puvTypes) { >> %DRIVER_DIR%\generate_drivers.js
echo       const existingDrivers = await db.collection('driver_locations') >> %DRIVER_DIR%\generate_drivers.js
echo         .where('isMockData', '==', true) >> %DRIVER_DIR%\generate_drivers.js
echo         .where('puvType', '==', puvType) >> %DRIVER_DIR%\generate_drivers.js
echo         .get(); >> %DRIVER_DIR%\generate_drivers.js
echo       console.log(`Removing ${existingDrivers.size} existing mock ${puvType} drivers...`); >> %DRIVER_DIR%\generate_drivers.js
echo       const batch = db.batch(); >> %DRIVER_DIR%\generate_drivers.js
echo       existingDrivers.forEach(doc => { >> %DRIVER_DIR%\generate_drivers.js
echo         batch.delete(doc.ref); >> %DRIVER_DIR%\generate_drivers.js
echo       }); >> %DRIVER_DIR%\generate_drivers.js
echo       await batch.commit(); >> %DRIVER_DIR%\generate_drivers.js
echo     } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo     // Number of drivers per route >> %DRIVER_DIR%\generate_drivers.js
echo     const driversPerRoute = 5; >> %DRIVER_DIR%\generate_drivers.js
echo     let driverIndex = 0; >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo     // Create mock drivers for each route >> %DRIVER_DIR%\generate_drivers.js
echo     for (const route of routes) { >> %DRIVER_DIR%\generate_drivers.js
echo       console.log(`Creating ${driversPerRoute} ${route.puvType} drivers for route ${route.routeCode}...`); >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo       for (let i = 0; i < driversPerRoute; i++) { >> %DRIVER_DIR%\generate_drivers.js
echo         // Place driver at a random position along the route >> %DRIVER_DIR%\generate_drivers.js
echo         const waypointIndex = Math.floor(Math.random() * route.waypoints.length); >> %DRIVER_DIR%\generate_drivers.js
echo         const location = route.waypoints[waypointIndex]; >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo         // Calculate heading based on next waypoint >> %DRIVER_DIR%\generate_drivers.js
echo         let heading = 0; >> %DRIVER_DIR%\generate_drivers.js
echo         if (route.waypoints.length > 1) { >> %DRIVER_DIR%\generate_drivers.js
echo           const nextIndex = (waypointIndex + 1) % route.waypoints.length; >> %DRIVER_DIR%\generate_drivers.js
echo           const nextPoint = route.waypoints[nextIndex]; >> %DRIVER_DIR%\generate_drivers.js
echo           heading = calculateHeading(location, nextPoint); >> %DRIVER_DIR%\generate_drivers.js
echo         } else { >> %DRIVER_DIR%\generate_drivers.js
echo           heading = Math.random() * 360; >> %DRIVER_DIR%\generate_drivers.js
echo         } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo         // Generate driver details >> %DRIVER_DIR%\generate_drivers.js
echo         const driverName = generateDriverName(); >> %DRIVER_DIR%\generate_drivers.js
echo         const plateNumber = generatePlateNumber(route.puvType); >> %DRIVER_DIR%\generate_drivers.js
echo         const rating = generateRating(); >> %DRIVER_DIR%\generate_drivers.js
echo         const capacity = generateCapacity(route.puvType); >> %DRIVER_DIR%\generate_drivers.js
echo         const status = generateStatus(); >> %DRIVER_DIR%\generate_drivers.js
echo         const etaMinutes = generateETA(); >> %DRIVER_DIR%\generate_drivers.js
echo         const speed = generateSpeed(); >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo         // Create a unique ID for this driver >> %DRIVER_DIR%\generate_drivers.js
echo         const docId = `mock_${route.puvType.toLowerCase()}_${driverIndex++}`; >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo         // Create driver document >> %DRIVER_DIR%\generate_drivers.js
echo         await db.collection('driver_locations').doc(docId).set({ >> %DRIVER_DIR%\generate_drivers.js
echo           userId: docId, >> %DRIVER_DIR%\generate_drivers.js
echo           location: new admin.firestore.GeoPoint(location.lat, location.lng), >> %DRIVER_DIR%\generate_drivers.js
echo           heading: heading, >> %DRIVER_DIR%\generate_drivers.js
echo           speed: speed, >> %DRIVER_DIR%\generate_drivers.js
echo           isLocationVisible: true, >> %DRIVER_DIR%\generate_drivers.js
echo           isOnline: true, >> %DRIVER_DIR%\generate_drivers.js
echo           lastUpdated: admin.firestore.FieldValue.serverTimestamp(), >> %DRIVER_DIR%\generate_drivers.js
echo           puvType: route.puvType, >> %DRIVER_DIR%\generate_drivers.js
echo           plateNumber: plateNumber, >> %DRIVER_DIR%\generate_drivers.js
echo           capacity: capacity, >> %DRIVER_DIR%\generate_drivers.js
echo           driverName: driverName, >> %DRIVER_DIR%\generate_drivers.js
echo           rating: rating, >> %DRIVER_DIR%\generate_drivers.js
echo           status: status, >> %DRIVER_DIR%\generate_drivers.js
echo           etaMinutes: etaMinutes, >> %DRIVER_DIR%\generate_drivers.js
echo           isMockData: true, >> %DRIVER_DIR%\generate_drivers.js
echo           routeId: route.id, >> %DRIVER_DIR%\generate_drivers.js
echo           routeCode: route.routeCode, >> %DRIVER_DIR%\generate_drivers.js
echo           iconType: 'car', >> %DRIVER_DIR%\generate_drivers.js
echo           photoUrl: `https://randomuser.me/api/portraits/${Math.random() > 0.7 ? 'women' : 'men'}/${Math.floor(Math.random() * 70) + 1}.jpg` >> %DRIVER_DIR%\generate_drivers.js
echo         }); >> %DRIVER_DIR%\generate_drivers.js
echo       } >> %DRIVER_DIR%\generate_drivers.js
echo     } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo     console.log(`Successfully created ${driverIndex} mock PUV drivers!`); >> %DRIVER_DIR%\generate_drivers.js
echo   } catch (error) { >> %DRIVER_DIR%\generate_drivers.js
echo     console.error('Error generating mock PUV drivers:', error); >> %DRIVER_DIR%\generate_drivers.js
echo   } >> %DRIVER_DIR%\generate_drivers.js
echo } >> %DRIVER_DIR%\generate_drivers.js
echo. >> %DRIVER_DIR%\generate_drivers.js
echo // Run the generator >> %DRIVER_DIR%\generate_drivers.js
echo generateMockPUVDrivers(); >> %DRIVER_DIR%\generate_drivers.js

:: Create commuter script
echo Creating commuter script...
echo // Firebase Admin SDK setup for iPara mock commuter data uploader > %COMMUTER_DIR%\generate_commuters.js
echo const admin = require('firebase-admin'); >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo // Initialize Firebase Admin with service account >> %COMMUTER_DIR%\generate_commuters.js
echo const serviceAccount = require('./serviceAccountKey.json'); >> %COMMUTER_DIR%\generate_commuters.js
echo admin.initializeApp({ >> %COMMUTER_DIR%\generate_commuters.js
echo   credential: admin.credential.cert(serviceAccount) >> %COMMUTER_DIR%\generate_commuters.js
echo }); >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo const db = admin.firestore(); >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo // Define PUV routes with waypoints >> %COMMUTER_DIR%\generate_commuters.js
echo const routes = [ >> %COMMUTER_DIR%\generate_commuters.js
echo   { >> %COMMUTER_DIR%\generate_commuters.js
echo     id: 'R3', >> %COMMUTER_DIR%\generate_commuters.js
echo     name: 'R3 - Lapasan-Cogon Market (Loop)', >> %COMMUTER_DIR%\generate_commuters.js
echo     routeCode: 'R3', >> %COMMUTER_DIR%\generate_commuters.js
echo     puvType: 'Bus', >> %COMMUTER_DIR%\generate_commuters.js
echo     waypoints: [ >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.490123, lng: 124.652781}, // Lapasan >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.486028, lng: 124.650684}, // Gaisano >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon Market >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.477595, lng: 124.653591}, // Yacapin >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.490123, lng: 124.652781}, // Back to Lapasan >> %COMMUTER_DIR%\generate_commuters.js
echo     ] >> %COMMUTER_DIR%\generate_commuters.js
echo   }, >> %COMMUTER_DIR%\generate_commuters.js
echo   { >> %COMMUTER_DIR%\generate_commuters.js
echo     id: 'RB', >> %COMMUTER_DIR%\generate_commuters.js
echo     name: 'RB - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan', >> %COMMUTER_DIR%\generate_commuters.js
echo     routeCode: 'RB', >> %COMMUTER_DIR%\generate_commuters.js
echo     puvType: 'Multicab', >> %COMMUTER_DIR%\generate_commuters.js
echo     waypoints: [ >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.498177, lng: 124.660786}, // Pier >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.486684, lng: 124.650807}, // Puregold/Gaisano >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.498178, lng: 124.660057}, // Julio Pacana St >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.503708, lng: 124.659001}, // Macabalan >> %COMMUTER_DIR%\generate_commuters.js
echo     ] >> %COMMUTER_DIR%\generate_commuters.js
echo   }, >> %COMMUTER_DIR%\generate_commuters.js
echo   { >> %COMMUTER_DIR%\generate_commuters.js
echo     id: 'BLUE', >> %COMMUTER_DIR%\generate_commuters.js
echo     name: 'BLUE - Agora-Osmena-Cogon (Loop)', >> %COMMUTER_DIR%\generate_commuters.js
echo     routeCode: 'BLUE', >> %COMMUTER_DIR%\generate_commuters.js
echo     puvType: 'Motorela', >> %COMMUTER_DIR%\generate_commuters.js
echo     waypoints: [ >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.488257, lng: 124.657648}, // Agora Market >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.488737, lng: 124.654004}, // Osmena >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.484704, lng: 124.656401}, // USTP >> %COMMUTER_DIR%\generate_commuters.js
echo       {lat: 8.488257, lng: 124.657648}, // Back to Agora >> %COMMUTER_DIR%\generate_commuters.js
echo     ] >> %COMMUTER_DIR%\generate_commuters.js
echo   } >> %COMMUTER_DIR%\generate_commuters.js
echo ]; >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo // Filipino commuter names >> %COMMUTER_DIR%\generate_commuters.js
echo const firstNames = [ >> %COMMUTER_DIR%\generate_commuters.js
echo   'Juan', 'Pedro', 'Miguel', 'Jose', 'Antonio', 'Ricardo', 'Eduardo', 'Francisco', >> %COMMUTER_DIR%\generate_commuters.js
echo   'Roberto', 'Manuel', 'Danilo', 'Rodrigo', 'Ernesto', 'Fernando', 'Andres', >> %COMMUTER_DIR%\generate_commuters.js
echo   'Maria', 'Rosa', 'Ana', 'Luisa', 'Elena', 'Josefa', 'Margarita', 'Teresita', >> %COMMUTER_DIR%\generate_commuters.js
echo   'Juana', 'Rosario', 'Corazon', 'Gloria', 'Lourdes', 'Natividad', 'Remedios' >> %COMMUTER_DIR%\generate_commuters.js
echo ]; >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo const lastNames = [ >> %COMMUTER_DIR%\generate_commuters.js
echo   'Garcia', 'Santos', 'Reyes', 'Cruz', 'Bautista', 'Gonzales', 'Ramos', 'Aquino', >> %COMMUTER_DIR%\generate_commuters.js
echo   'Diaz', 'Castro', 'Mendoza', 'Torres', 'Flores', 'Villanueva', 'Fernandez', >> %COMMUTER_DIR%\generate_commuters.js
echo   'Morales', 'Perez', 'Ramirez', 'Hernandez', 'Pascual', 'Delos Santos', 'Tolentino', >> %COMMUTER_DIR%\generate_commuters.js
echo   'Valdez', 'Gutierrez', 'Navarro', 'Domingo', 'Salazar', 'Del Rosario', 'Mercado' >> %COMMUTER_DIR%\generate_commuters.js
echo ]; >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo // Generate a random commuter name >> %COMMUTER_DIR%\generate_commuters.js
echo function generateCommuterName() { >> %COMMUTER_DIR%\generate_commuters.js
echo   const firstName = firstNames[Math.floor(Math.random() * firstNames.length)]; >> %COMMUTER_DIR%\generate_commuters.js
echo   const lastName = lastNames[Math.floor(Math.random() * lastNames.length)]; >> %COMMUTER_DIR%\generate_commuters.js
echo   return `${firstName} ${lastName}`; >> %COMMUTER_DIR%\generate_commuters.js
echo } >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo // Generate a random location near a route >> %COMMUTER_DIR%\generate_commuters.js
echo function generateLocationNearRoute(route) { >> %COMMUTER_DIR%\generate_commuters.js
echo   // Pick a random waypoint from the route >> %COMMUTER_DIR%\generate_commuters.js
echo   const waypoint = route.waypoints[Math.floor(Math.random() * route.waypoints.length)]; >> %COMMUTER_DIR%\generate_commuters.js
echo   >> %COMMUTER_DIR%\generate_commuters.js
echo   // Add a small random offset (up to ~100 meters) >> %COMMUTER_DIR%\generate_commuters.js
echo   const latOffset = (Math.random() - 0.5) * 0.002; // ~100m in latitude >> %COMMUTER_DIR%\generate_commuters.js
echo   const lngOffset = (Math.random() - 0.5) * 0.002; // ~100m in longitude >> %COMMUTER_DIR%\generate_commuters.js
echo   >> %COMMUTER_DIR%\generate_commuters.js
echo   return { >> %COMMUTER_DIR%\generate_commuters.js
echo     lat: waypoint.lat + latOffset, >> %COMMUTER_DIR%\generate_commuters.js
echo     lng: waypoint.lng + lngOffset >> %COMMUTER_DIR%\generate_commuters.js
echo   }; >> %COMMUTER_DIR%\generate_commuters.js
echo } >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo // Generate mock commuters >> %COMMUTER_DIR%\generate_commuters.js
echo async function generateMockCommuters() { >> %COMMUTER_DIR%\generate_commuters.js
echo   try { >> %COMMUTER_DIR%\generate_commuters.js
echo     // Clear existing mock commuters >> %COMMUTER_DIR%\generate_commuters.js
echo     const existingCommuters = await db.collection('commuter_locations').where('isMockData', '==', true).get(); >> %COMMUTER_DIR%\generate_commuters.js
echo     console.log(`Removing ${existingCommuters.size} existing mock commuters...`); >> %COMMUTER_DIR%\generate_commuters.js
echo     const batch = db.batch(); >> %COMMUTER_DIR%\generate_commuters.js
echo     existingCommuters.forEach(doc => { >> %COMMUTER_DIR%\generate_commuters.js
echo       batch.delete(doc.ref); >> %COMMUTER_DIR%\generate_commuters.js
echo     }); >> %COMMUTER_DIR%\generate_commuters.js
echo     await batch.commit(); >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo     // Number of commuters per route >> %COMMUTER_DIR%\generate_commuters.js
echo     const commutersPerRoute = 5; >> %COMMUTER_DIR%\generate_commuters.js
echo     let commuterIndex = 0; >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo     // Create mock commuters for each route >> %COMMUTER_DIR%\generate_commuters.js
echo     for (const route of routes) { >> %COMMUTER_DIR%\generate_commuters.js
echo       console.log(`Creating ${commutersPerRoute} commuters for ${route.puvType} route ${route.routeCode}...`); >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo       for (let i = 0; i < commutersPerRoute; i++) { >> %COMMUTER_DIR%\generate_commuters.js
echo         // Generate commuter details >> %COMMUTER_DIR%\generate_commuters.js
echo         const commuterName = generateCommuterName(); >> %COMMUTER_DIR%\generate_commuters.js
echo         const location = generateLocationNearRoute(route); >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo         // Create a unique ID for this commuter >> %COMMUTER_DIR%\generate_commuters.js
echo         const docId = `mock_commuter_${route.routeCode}_${commuterIndex++}`; >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo         // Create commuter document >> %COMMUTER_DIR%\generate_commuters.js
echo         await db.collection('commuter_locations').doc(docId).set({ >> %COMMUTER_DIR%\generate_commuters.js
echo           userId: docId, >> %COMMUTER_DIR%\generate_commuters.js
echo           userName: commuterName, >> %COMMUTER_DIR%\generate_commuters.js
echo           location: new admin.firestore.GeoPoint(location.lat, location.lng), >> %COMMUTER_DIR%\generate_commuters.js
echo           isLocationVisible: true, >> %COMMUTER_DIR%\generate_commuters.js
echo           lastUpdated: admin.firestore.FieldValue.serverTimestamp(), >> %COMMUTER_DIR%\generate_commuters.js
echo           selectedPuvType: route.puvType, >> %COMMUTER_DIR%\generate_commuters.js
echo           routeCode: route.routeCode, >> %COMMUTER_DIR%\generate_commuters.js
echo           routeId: route.id, >> %COMMUTER_DIR%\generate_commuters.js
echo           isMockData: true, >> %COMMUTER_DIR%\generate_commuters.js
echo           iconType: 'person' >> %COMMUTER_DIR%\generate_commuters.js
echo         }); >> %COMMUTER_DIR%\generate_commuters.js
echo       } >> %COMMUTER_DIR%\generate_commuters.js
echo     } >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo     console.log(`Successfully created ${commuterIndex} mock commuters!`); >> %COMMUTER_DIR%\generate_commuters.js
echo   } catch (error) { >> %COMMUTER_DIR%\generate_commuters.js
echo     console.error('Error generating mock commuters:', error); >> %COMMUTER_DIR%\generate_commuters.js
echo   } >> %COMMUTER_DIR%\generate_commuters.js
echo } >> %COMMUTER_DIR%\generate_commuters.js
echo. >> %COMMUTER_DIR%\generate_commuters.js
echo // Run the generator >> %COMMUTER_DIR%\generate_commuters.js
echo generateMockCommuters(); >> %COMMUTER_DIR%\generate_commuters.js

:: Install required packages
echo.
echo Installing required packages...
cd %DRIVER_DIR%
call npm init -y
call npm install firebase-admin
cd ..

cd %COMMUTER_DIR%
call npm init -y
call npm install firebase-admin
cd ..

:: Run the scripts
echo.
echo Running scripts to generate mock data...
echo.
echo 1. Generating mock PUV drivers...
cd %DRIVER_DIR%
node generate_drivers.js
cd ..

echo.
echo 2. Generating mock commuters...
cd %COMMUTER_DIR%
node generate_commuters.js
cd ..

echo.
echo All mock data has been generated successfully!
echo.
echo Press any key to exit...
pause > nul
