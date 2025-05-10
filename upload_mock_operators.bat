@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo iPara Mock Operator Data Generator for Firebase
echo ===================================================
echo.
echo This script will upload mock operators and vehicles
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
if not exist "temp_operators" mkdir temp_operators
cd temp_operators

:: Create package.json
echo Creating package.json...
echo {^
  "name": "ipara-mock-operators-uploader",^
  "version": "1.0.0",^
  "description": "Upload mock operator data to Firebase",^
  "main": "upload_operators.js",^
  "dependencies": {^
    "firebase-admin": "^11.10.1"^
  }^
} > package.json

:: Install dependencies
echo Installing dependencies...
call npm install

:: Create the Firebase admin script
echo Creating upload script...
echo // Firebase Admin SDK setup for iPara mock data uploader > upload_operators.js
echo const admin = require('firebase-admin'); >> upload_operators.js
echo. >> upload_operators.js
echo // Initialize Firebase Admin with service account >> upload_operators.js
echo const serviceAccount = require('./serviceAccountKey.json'); >> upload_operators.js
echo admin.initializeApp({ >> upload_operators.js
echo   credential: admin.credential.cert(serviceAccount) >> upload_operators.js
echo }); >> upload_operators.js
echo. >> upload_operators.js
echo const db = admin.firestore(); >> upload_operators.js
echo. >> upload_operators.js
echo // Define jeepney routes >> upload_operators.js
echo const routes = [ >> upload_operators.js
echo   { id: 'r2', routeCode: 'R2', name: 'R2 - Gaisano-Agora-Cogon-Carmen' }, >> upload_operators.js
echo   { id: 'C2', routeCode: 'C2', name: 'C2 - Patag-Gaisano-Limketkai-Cogon' }, >> upload_operators.js
echo   { id: 'RA', routeCode: 'RA', name: 'RA - Pier-Gaisano-Ayala-Cogon' }, >> upload_operators.js
echo   { id: 'RD', routeCode: 'RD', name: 'RD - Gusa-Cugman-Cogon-Limketkai' } >> upload_operators.js
echo ]; >> upload_operators.js
echo. >> upload_operators.js
echo // Filipino operator names >> upload_operators.js
echo const firstNames = [ >> upload_operators.js
echo   'Juan', 'Pedro', 'Miguel', 'Jose', 'Antonio', 'Ricardo', 'Eduardo', 'Francisco', >> upload_operators.js
echo   'Roberto', 'Manuel', 'Danilo', 'Rodrigo', 'Ernesto', 'Fernando', 'Andres', >> upload_operators.js
echo   'Maria', 'Rosa', 'Ana', 'Luisa', 'Elena', 'Josefa', 'Margarita', 'Teresita', >> upload_operators.js
echo   'Juana', 'Rosario', 'Corazon', 'Gloria', 'Lourdes', 'Natividad', 'Remedios' >> upload_operators.js
echo ]; >> upload_operators.js
echo. >> upload_operators.js
echo const lastNames = [ >> upload_operators.js
echo   'Garcia', 'Santos', 'Reyes', 'Cruz', 'Bautista', 'Gonzales', 'Ramos', 'Aquino', >> upload_operators.js
echo   'Diaz', 'Castro', 'Mendoza', 'Torres', 'Flores', 'Villanueva', 'Fernandez', >> upload_operators.js
echo   'Morales', 'Perez', 'Ramirez', 'Hernandez', 'Pascual', 'Delos Santos', 'Tolentino', >> upload_operators.js
echo   'Valdez', 'Gutierrez', 'Navarro', 'Domingo', 'Salazar', 'Del Rosario', 'Mercado' >> upload_operators.js
echo ]; >> upload_operators.js
echo. >> upload_operators.js
echo // Generate a random operator name >> upload_operators.js
echo function generateOperatorName() { >> upload_operators.js
echo   const firstName = firstNames[Math.floor(Math.random() * firstNames.length)]; >> upload_operators.js
echo   const lastName = lastNames[Math.floor(Math.random() * lastNames.length)]; >> upload_operators.js
echo   return `${firstName} ${lastName}`; >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate a random plate number for jeepneys >> upload_operators.js
echo function generatePlateNumber() { >> upload_operators.js
echo   // Format: JPN-123 >> upload_operators.js
echo   const number = 100 + Math.floor(Math.random() * 900); >> upload_operators.js
echo   return `JPN-${number}`; >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate a random email >> upload_operators.js
echo function generateEmail(name) { >> upload_operators.js
echo   const nameParts = name.toLowerCase().split(' '); >> upload_operators.js
echo   const domains = ['gmail.com', 'yahoo.com', 'outlook.com']; >> upload_operators.js
echo   const domain = domains[Math.floor(Math.random() * domains.length)]; >> upload_operators.js
echo   return `${nameParts[0]}.${nameParts[1]}@${domain}`; >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate a random phone number >> upload_operators.js
echo function generatePhoneNumber() { >> upload_operators.js
echo   // Philippine mobile number format >> upload_operators.js
echo   const prefix = ['0917', '0918', '0919', '0920', '0921', '0922', '0923', '0927', '0928', '0929', '0930', '0938', '0939', '0945', '0946', '0947', '0948', '0949', '0950', '0966', '0967', '0973', '0975', '0977', '0978', '0979', '0995', '0996', '0997', '0998', '0999']; >> upload_operators.js
echo   const selectedPrefix = prefix[Math.floor(Math.random() * prefix.length)]; >> upload_operators.js
echo   const number = Math.floor(Math.random() * 10000000).toString().padStart(7, '0'); >> upload_operators.js
echo   return `${selectedPrefix}${number}`; >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate a random jeepney model >> upload_operators.js
echo function generateJeepneyModel() { >> upload_operators.js
echo   const manufacturers = ['Sarao', 'Francisco', 'Orlina', 'Morales', 'MD Jeepney', 'Celestial']; >> upload_operators.js
echo   const models = ['Traditional', 'Modern', 'Customized', 'Standard', 'Deluxe']; >> upload_operators.js
echo   const manufacturer = manufacturers[Math.floor(Math.random() * manufacturers.length)]; >> upload_operators.js
echo   const model = models[Math.floor(Math.random() * models.length)]; >> upload_operators.js
echo   return `${manufacturer} ${model}`; >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate a random year between 2000 and 2023 >> upload_operators.js
echo function generateYear() { >> upload_operators.js
echo   return 2000 + Math.floor(Math.random() * 24); >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate a random odometer reading >> upload_operators.js
echo function generateOdometerReading() { >> upload_operators.js
echo   return 10000 + Math.floor(Math.random() * 190000); >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate maintenance reminders >> upload_operators.js
echo function generateMaintenanceReminders() { >> upload_operators.js
echo   const maintenanceTypes = [ >> upload_operators.js
echo     'Oil Change', 'Brake Check', 'Tire Rotation', 'Engine Tune-up', >> upload_operators.js
echo     'Transmission Service', 'Air Filter Replacement', 'Spark Plug Replacement', >> upload_operators.js
echo     'Battery Check', 'Cooling System Service', 'Suspension Check' >> upload_operators.js
echo   ]; >> upload_operators.js
echo. >> upload_operators.js
echo   const reminders = []; >> upload_operators.js
echo   const numReminders = 1 + Math.floor(Math.random() * 3); // 1-3 reminders >> upload_operators.js
echo. >> upload_operators.js
echo   for (let i = 0; i < numReminders; i++) { >> upload_operators.js
echo     const type = maintenanceTypes[Math.floor(Math.random() * maintenanceTypes.length)]; >> upload_operators.js
echo     const now = new Date(); >> upload_operators.js
echo     const dueDate = new Date(now.getTime() + (Math.random() * 30 * 24 * 60 * 60 * 1000)); // Random date within 30 days >> upload_operators.js
echo. >> upload_operators.js
echo     reminders.push({ >> upload_operators.js
echo       type: type, >> upload_operators.js
echo       description: `Regular ${type.toLowerCase()} maintenance`, >> upload_operators.js
echo       dueDate: admin.firestore.Timestamp.fromDate(dueDate), >> upload_operators.js
echo       isCompleted: Math.random() > 0.7, // 30% chance of being completed >> upload_operators.js
echo       completedDate: Math.random() > 0.7 ? admin.firestore.Timestamp.fromDate(new Date()) : null, >> upload_operators.js
echo       odometerDue: Math.floor(Math.random() * 5000) + 1000, >> upload_operators.js
echo     }); >> upload_operators.js
echo   } >> upload_operators.js
echo. >> upload_operators.js
echo   return reminders; >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Generate mock operators and vehicles >> upload_operators.js
echo async function generateMockOperatorsAndVehicles() { >> upload_operators.js
echo   try { >> upload_operators.js
echo     // Clear existing mock operators and vehicles >> upload_operators.js
echo     const existingOperators = await db.collection('users').where('isMockData', '==', true).get(); >> upload_operators.js
echo     console.log(`Removing ${existingOperators.size} existing mock operators...`); >> upload_operators.js
echo     let batch = db.batch(); >> upload_operators.js
echo     existingOperators.forEach(doc => { >> upload_operators.js
echo       batch.delete(doc.ref); >> upload_operators.js
echo     }); >> upload_operators.js
echo     await batch.commit(); >> upload_operators.js
echo. >> upload_operators.js
echo     const existingVehicles = await db.collection('vehicles').where('isMockData', '==', true).get(); >> upload_operators.js
echo     console.log(`Removing ${existingVehicles.size} existing mock vehicles...`); >> upload_operators.js
echo     batch = db.batch(); >> upload_operators.js
echo     existingVehicles.forEach(doc => { >> upload_operators.js
echo       batch.delete(doc.ref); >> upload_operators.js
echo     }); >> upload_operators.js
echo     await batch.commit(); >> upload_operators.js
echo. >> upload_operators.js
echo     // Number of operators to create >> upload_operators.js
echo     const numOperators = 10; >> upload_operators.js
echo     const vehiclesPerOperator = 2; // Each operator has 1-3 vehicles >> upload_operators.js
echo. >> upload_operators.js
echo     console.log(`Creating ${numOperators} mock operators...`); >> upload_operators.js
echo. >> upload_operators.js
echo     // Create mock operators >> upload_operators.js
echo     for (let i = 0; i < numOperators; i++) { >> upload_operators.js
echo       const operatorName = generateOperatorName(); >> upload_operators.js
echo       const operatorEmail = generateEmail(operatorName); >> upload_operators.js
echo       const operatorPhone = generatePhoneNumber(); >> upload_operators.js
echo       const operatorId = `mock_operator_${i}`; >> upload_operators.js
echo. >> upload_operators.js
echo       // Create operator document >> upload_operators.js
echo       await db.collection('users').doc(operatorId).set({ >> upload_operators.js
echo         uid: operatorId, >> upload_operators.js
echo         displayName: operatorName, >> upload_operators.js
echo         email: operatorEmail, >> upload_operators.js
echo         phoneNumber: operatorPhone, >> upload_operators.js
echo         role: 2, // 2 = operator >> upload_operators.js
echo         createdAt: admin.firestore.FieldValue.serverTimestamp(), >> upload_operators.js
echo         updatedAt: admin.firestore.FieldValue.serverTimestamp(), >> upload_operators.js
echo         isMockData: true, >> upload_operators.js
echo         photoUrl: `https://randomuser.me/api/portraits/${Math.random() > 0.7 ? 'women' : 'men'}/${Math.floor(Math.random() * 70) + 1}.jpg` >> upload_operators.js
echo       }); >> upload_operators.js
echo. >> upload_operators.js
echo       // Create vehicles for this operator >> upload_operators.js
echo       for (let j = 0; j < vehiclesPerOperator; j++) { >> upload_operators.js
echo         const vehicleId = `mock_vehicle_${i}_${j}`; >> upload_operators.js
echo         const plateNumber = generatePlateNumber(); >> upload_operators.js
echo         const model = generateJeepneyModel(); >> upload_operators.js
echo         const year = generateYear(); >> upload_operators.js
echo         const odometerReading = generateOdometerReading(); >> upload_operators.js
echo         const maintenanceReminders = generateMaintenanceReminders(); >> upload_operators.js
echo. >> upload_operators.js
echo         // Assign to a random route >> upload_operators.js
echo         const route = routes[Math.floor(Math.random() * routes.length)]; >> upload_operators.js
echo. >> upload_operators.js
echo         // Create vehicle document >> upload_operators.js
echo         await db.collection('vehicles').doc(vehicleId).set({ >> upload_operators.js
echo           plateNumber: plateNumber, >> upload_operators.js
echo           vehicleType: 'Jeepney', >> upload_operators.js
echo           model: model, >> upload_operators.js
echo           year: year, >> upload_operators.js
echo           odometerReading: odometerReading, >> upload_operators.js
echo           operatorId: operatorId, >> upload_operators.js
echo           routeId: route.id, >> upload_operators.js
echo           routeCode: route.routeCode, >> upload_operators.js
echo           isActive: true, >> upload_operators.js
echo           maintenanceReminders: maintenanceReminders, >> upload_operators.js
echo           updatedAt: admin.firestore.FieldValue.serverTimestamp(), >> upload_operators.js
echo           isMockData: true >> upload_operators.js
echo         }); >> upload_operators.js
echo       } >> upload_operators.js
echo     } >> upload_operators.js
echo. >> upload_operators.js
echo     console.log(`Successfully created ${numOperators} mock operators with ${numOperators * vehiclesPerOperator} vehicles!`); >> upload_operators.js
echo   } catch (error) { >> upload_operators.js
echo     console.error('Error generating mock operators and vehicles:', error); >> upload_operators.js
echo   } >> upload_operators.js
echo } >> upload_operators.js
echo. >> upload_operators.js
echo // Run the generator >> upload_operators.js
echo generateMockOperatorsAndVehicles().then(() => { >> upload_operators.js
echo   console.log('Done!'); >> upload_operators.js
echo   process.exit(0); >> upload_operators.js
echo }).catch(error => { >> upload_operators.js
echo   console.error('Fatal error:', error); >> upload_operators.js
echo   process.exit(1); >> upload_operators.js
echo }); >> upload_operators.js

echo.
echo Script files created successfully!
echo.
echo IMPORTANT: Before running this script, you need to:
echo 1. Download your Firebase service account key from the Firebase console
echo 2. Save it as 'serviceAccountKey.json' in the 'temp_operators' folder
echo.
echo To download your service account key:
echo 1. Go to Firebase Console: https://console.firebase.google.com/
echo 2. Select your project: ipara-fd373
echo 3. Go to Project Settings ^> Service accounts
echo 4. Click "Generate new private key"
echo 5. Save the file as "serviceAccountKey.json" in the temp_operators folder
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
echo Running the script to upload mock operators and vehicles...
echo.

:: Run the Node.js script
node upload_operators.js

echo.
echo Script execution completed!
echo.
echo If there were no errors, mock operators and vehicles have been uploaded to your Firebase database.
echo You can now use these mock operators and vehicles in your app.
echo.

:: Clean up
cd ..
echo Do you want to keep the temporary files? (Y/N)
set /p KEEP_FILES=
if /i "%KEEP_FILES%" NEQ "Y" (
    echo Cleaning up temporary files...
    rmdir /s /q temp_operators
)

echo.
echo Thank you for using the iPara Mock Operator Data Generator!
echo.
pause
