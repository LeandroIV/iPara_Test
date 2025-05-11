@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Mock Commuter Data Generator
echo ===================================================
echo.
echo This script will upload mock commuter data to your Firebase database:
echo 1. Commuters looking for Bus (R3)
echo 2. Commuters looking for Multicab (RB)
echo 3. Commuters looking for Motorela (BLUE)
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

:: Check for existing directories with different naming conventions
if exist temp_commuters (
    echo Using existing temp_commuters directory
    set TEMP_DIR=temp_commuters
) else if exist temp_commuters (
    echo Using existing temp_commuters directory
    set TEMP_DIR=temp_commuters
) else (
    mkdir temp_commuters
    echo Created temp_commuters directory
    set TEMP_DIR=temp_commuters
)

:: Install required packages
echo Installing required packages...
cd temp_commuters
call npm init -y
call npm install firebase-admin

:: Create the Firebase admin script
echo Creating upload script...
echo // Firebase Admin SDK setup for iPara mock commuter data uploader > upload_commuters.js
echo const admin = require('firebase-admin'); >> upload_commuters.js
echo. >> upload_commuters.js
echo // Initialize Firebase Admin with service account >> upload_commuters.js
echo const serviceAccount = require('./serviceAccountKey.json'); >> upload_commuters.js
echo admin.initializeApp({ >> upload_commuters.js
echo   credential: admin.credential.cert(serviceAccount) >> upload_commuters.js
echo }); >> upload_commuters.js
echo. >> upload_commuters.js
echo const db = admin.firestore(); >> upload_commuters.js
echo. >> upload_commuters.js
echo // Define PUV routes with waypoints >> upload_commuters.js
echo const routes = [ >> upload_commuters.js
echo   { >> upload_commuters.js
echo     id: 'R3', >> upload_commuters.js
echo     name: 'R3 - Lapasan-Cogon Market (Loop)', >> upload_commuters.js
echo     routeCode: 'R3', >> upload_commuters.js
echo     puvType: 'Bus', >> upload_commuters.js
echo     waypoints: [ >> upload_commuters.js
echo       {lat: 8.490123, lng: 124.652781}, // Lapasan >> upload_commuters.js
echo       {lat: 8.486028, lng: 124.650684}, // Gaisano >> upload_commuters.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon Market >> upload_commuters.js
echo       {lat: 8.477595, lng: 124.653591}, // Yacapin >> upload_commuters.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> upload_commuters.js
echo       {lat: 8.490123, lng: 124.652781}, // Back to Lapasan >> upload_commuters.js
echo     ] >> upload_commuters.js
echo   }, >> upload_commuters.js
echo   { >> upload_commuters.js
echo     id: 'RB', >> upload_commuters.js
echo     name: 'RB - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan', >> upload_commuters.js
echo     routeCode: 'RB', >> upload_commuters.js
echo     puvType: 'Multicab', >> upload_commuters.js
echo     waypoints: [ >> upload_commuters.js
echo       {lat: 8.498177, lng: 124.660786}, // Pier >> upload_commuters.js
echo       {lat: 8.486684, lng: 124.650807}, // Puregold/Gaisano >> upload_commuters.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> upload_commuters.js
echo       {lat: 8.485010, lng: 124.647179}, // Velez >> upload_commuters.js
echo       {lat: 8.498178, lng: 124.660057}, // Julio Pacana St >> upload_commuters.js
echo       {lat: 8.503708, lng: 124.659001}, // Macabalan >> upload_commuters.js
echo     ] >> upload_commuters.js
echo   }, >> upload_commuters.js
echo   { >> upload_commuters.js
echo     id: 'BLUE', >> upload_commuters.js
echo     name: 'BLUE - Agora-Osmena-Cogon (Loop)', >> upload_commuters.js
echo     routeCode: 'BLUE', >> upload_commuters.js
echo     puvType: 'Motorela', >> upload_commuters.js
echo     waypoints: [ >> upload_commuters.js
echo       {lat: 8.488257, lng: 124.657648}, // Agora Market >> upload_commuters.js
echo       {lat: 8.488737, lng: 124.654004}, // Osmena >> upload_commuters.js
echo       {lat: 8.479595, lng: 124.649240}, // Cogon >> upload_commuters.js
echo       {lat: 8.484704, lng: 124.656401}, // USTP >> upload_commuters.js
echo       {lat: 8.488257, lng: 124.657648}, // Back to Agora >> upload_commuters.js
echo     ] >> upload_commuters.js
echo   } >> upload_commuters.js
echo ]; >> upload_commuters.js
echo. >> upload_commuters.js
echo // Filipino commuter names >> upload_commuters.js
echo const firstNames = [ >> upload_commuters.js
echo   'Juan', 'Pedro', 'Miguel', 'Jose', 'Antonio', 'Ricardo', 'Eduardo', 'Francisco', >> upload_commuters.js
echo   'Roberto', 'Manuel', 'Danilo', 'Rodrigo', 'Ernesto', 'Fernando', 'Andres', >> upload_commuters.js
echo   'Maria', 'Rosa', 'Ana', 'Luisa', 'Elena', 'Josefa', 'Margarita', 'Teresita', >> upload_commuters.js
echo   'Juana', 'Rosario', 'Corazon', 'Gloria', 'Lourdes', 'Natividad', 'Remedios' >> upload_commuters.js
echo ]; >> upload_commuters.js
echo. >> upload_commuters.js
echo const lastNames = [ >> upload_commuters.js
echo   'Garcia', 'Santos', 'Reyes', 'Cruz', 'Bautista', 'Gonzales', 'Ramos', 'Aquino', >> upload_commuters.js
echo   'Diaz', 'Castro', 'Mendoza', 'Torres', 'Flores', 'Villanueva', 'Fernandez', >> upload_commuters.js
echo   'Morales', 'Perez', 'Ramirez', 'Hernandez', 'Pascual', 'Delos Santos', 'Tolentino', >> upload_commuters.js
echo   'Valdez', 'Gutierrez', 'Navarro', 'Domingo', 'Salazar', 'Del Rosario', 'Mercado' >> upload_commuters.js
echo ]; >> upload_commuters.js
echo. >> upload_commuters.js
echo // Generate a random commuter name >> upload_commuters.js
echo function generateCommuterName() { >> upload_commuters.js
echo   const firstName = firstNames[Math.floor(Math.random() * firstNames.length)]; >> upload_commuters.js
echo   const lastName = lastNames[Math.floor(Math.random() * lastNames.length)]; >> upload_commuters.js
echo   return `${firstName} ${lastName}`; >> upload_commuters.js
echo } >> upload_commuters.js
echo. >> upload_commuters.js
echo // Generate a random location near a route >> upload_commuters.js
echo function generateLocationNearRoute(route) { >> upload_commuters.js
echo   // Pick a random waypoint from the route >> upload_commuters.js
echo   const waypoint = route.waypoints[Math.floor(Math.random() * route.waypoints.length)]; >> upload_commuters.js
echo   >> upload_commuters.js
echo   // Add a small random offset (up to ~100 meters) >> upload_commuters.js
echo   const latOffset = (Math.random() - 0.5) * 0.002; // ~100m in latitude >> upload_commuters.js
echo   const lngOffset = (Math.random() - 0.5) * 0.002; // ~100m in longitude >> upload_commuters.js
echo   >> upload_commuters.js
echo   return { >> upload_commuters.js
echo     lat: waypoint.lat + latOffset, >> upload_commuters.js
echo     lng: waypoint.lng + lngOffset >> upload_commuters.js
echo   }; >> upload_commuters.js
echo } >> upload_commuters.js
echo. >> upload_commuters.js
echo // Generate mock commuters >> upload_commuters.js
echo async function generateMockCommuters() { >> upload_commuters.js
echo   try { >> upload_commuters.js
echo     // Clear existing mock commuters >> upload_commuters.js
echo     const existingCommuters = await db.collection('commuter_locations').where('isMockData', '==', true).get(); >> upload_commuters.js
echo     console.log(`Removing ${existingCommuters.size} existing mock commuters...`); >> upload_commuters.js
echo     const batch = db.batch(); >> upload_commuters.js
echo     existingCommuters.forEach(doc => { >> upload_commuters.js
echo       batch.delete(doc.ref); >> upload_commuters.js
echo     }); >> upload_commuters.js
echo     await batch.commit(); >> upload_commuters.js
echo. >> upload_commuters.js
echo     // Number of commuters per route >> upload_commuters.js
echo     const commutersPerRoute = 5; >> upload_commuters.js
echo     let commuterIndex = 0; >> upload_commuters.js
echo. >> upload_commuters.js
echo     // Create mock commuters for each route >> upload_commuters.js
echo     for (const route of routes) { >> upload_commuters.js
echo       console.log(`Creating ${commutersPerRoute} commuters for ${route.puvType} route ${route.routeCode}...`); >> upload_commuters.js
echo. >> upload_commuters.js
echo       for (let i = 0; i < commutersPerRoute; i++) { >> upload_commuters.js
echo         // Generate commuter details >> upload_commuters.js
echo         const commuterName = generateCommuterName(); >> upload_commuters.js
echo         const location = generateLocationNearRoute(route); >> upload_commuters.js
echo. >> upload_commuters.js
echo         // Create a unique ID for this commuter >> upload_commuters.js
echo         const docId = `mock_commuter_${route.routeCode}_${commuterIndex++}`; >> upload_commuters.js
echo. >> upload_commuters.js
echo         // Create commuter document >> upload_commuters.js
echo         await db.collection('commuter_locations').doc(docId).set({ >> upload_commuters.js
echo           userId: docId, >> upload_commuters.js
echo           userName: commuterName, >> upload_commuters.js
echo           location: new admin.firestore.GeoPoint(location.lat, location.lng), >> upload_commuters.js
echo           isLocationVisible: true, >> upload_commuters.js
echo           lastUpdated: admin.firestore.FieldValue.serverTimestamp(), >> upload_commuters.js
echo           selectedPuvType: route.puvType, >> upload_commuters.js
echo           routeCode: route.routeCode, >> upload_commuters.js
echo           routeId: route.id, >> upload_commuters.js
echo           isMockData: true, >> upload_commuters.js
echo           iconType: 'person' >> upload_commuters.js
echo         }); >> upload_commuters.js
echo       } >> upload_commuters.js
echo     } >> upload_commuters.js
echo. >> upload_commuters.js
echo     console.log(`Successfully created ${commuterIndex} mock commuters!`); >> upload_commuters.js
echo   } catch (error) { >> upload_commuters.js
echo     console.error('Error generating mock commuters:', error); >> upload_commuters.js
echo   } >> upload_commuters.js
echo } >> upload_commuters.js
echo. >> upload_commuters.js
echo // Run the generator >> upload_commuters.js
echo generateMockCommuters(); >> upload_commuters.js

echo.
echo IMPORTANT: Before continuing, make sure you have:
echo 1. Downloaded your Firebase service account key
echo 2. Saved it as 'serviceAccountKey.json' in the 'temp_commuters' folder
echo.

:: Check if serviceAccountKey.json exists
if not exist temp_commuters\serviceAccountKey.json (
    echo ERROR: serviceAccountKey.json not found in temp_commuters folder.
    echo Please download your Firebase service account key and save it as 'serviceAccountKey.json' in the 'temp_commuters' folder.
    cd ..
    exit /b 1
)

echo Press any key when you're ready...
pause > nul

echo.
echo Uploading mock commuters...
node upload_commuters.js
cd ..

echo.
echo Process completed!
echo.
echo Thank you for using the iPara Mock Commuter Data Generator!
echo.
pause
