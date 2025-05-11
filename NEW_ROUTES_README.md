# iPara New Routes and Mock Data

This document explains the new routes added to the iPara app and how to generate mock data for them.

## New Routes Added

The following new routes have been added to the iPara app:

1. **Bus Route (R3)**: Lapasan - Cogon Market (Loop)
   - Route Code: R3
   - PUV Type: Bus
   - Waypoints: Lapasan → Gaisano → Cogon Market → Yacapin → Velez → Lapasan

2. **Multicab Route (RB)**: Pier - Puregold - Cogon - Velez - Julio Pacana - Macabalan
   - Route Code: RB
   - PUV Type: Multicab
   - Waypoints: Pier → Puregold/Gaisano → Cogon → Velez → Julio Pacana St → Macabalan

3. **Motorela Route (BLUE)**: Agora - Osmena - Cogon (Loop)
   - Route Code: BLUE
   - PUV Type: Motorela
   - Waypoints: Agora Market → Osmena → Cogon → USTP → Agora Market

## Generating Mock Data

To populate your Firebase database with mock data for these new routes, you can use the provided batch scripts:

### 1. `upload_mock_puv_data.bat`

This script generates and uploads mock drivers for the new routes:
- 5 Bus drivers on the R3 route
- 5 Multicab drivers on the RB route
- 5 Motorela drivers on the BLUE route

### 2. `upload_mock_commuters.bat`

This script generates and uploads mock commuters looking for the new PUV types:
- 5 commuters looking for Bus (R3)
- 5 commuters looking for Multicab (RB)
- 5 commuters looking for Motorela (BLUE)

### 3. `upload_all_mock_data.bat`

This is a master script that provides a menu to run either or both of the above scripts.

## How to Use the Scripts

1. **Prerequisites**:
   - Node.js installed on your computer
   - Firebase service account key (serviceAccountKey.json)

2. **Setup Service Account Key**:
   - Run `setup_service_account.bat`
   - Choose option 3 to open the Firebase console
   - Download your service account key from Project settings > Service accounts
   - Choose option 2 to copy your service account key to the required locations

3. **Generate Mock Data**:
   - Run `upload_all_mock_data.bat`
   - Choose option 3 to upload both drivers and commuters
   - Wait for the scripts to complete

3. **Testing in the App**:
   - Launch the iPara app
   - In commuter mode, select Bus, Multicab, or Motorela to see the new routes
   - In driver mode, select Bus, Multicab, or Motorela to see commuters looking for these PUV types

## Troubleshooting

If you encounter any issues:

1. **Script Errors**:
   - Make sure Node.js is installed and in your PATH
   - Ensure your serviceAccountKey.json is valid and has the correct permissions
   - Check the console output for specific error messages

2. **Data Not Appearing in the App**:
   - Verify that the data was successfully uploaded to Firebase
   - Check the app's debug console for any error messages
   - Make sure you're within the radius of the mock data (5km by default)
   - Ensure your location services are enabled and working

## Notes

- The mock data includes Filipino names and realistic details
- Drivers are placed at random points along their assigned routes
- Commuters are placed near the route waypoints
- All mock data is marked with `isMockData: true` in Firestore
