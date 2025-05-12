# iPara Route Data Uploader

This tool uploads route data to Firebase Firestore for the iPara app. It ensures that the route management feature in the operator mode can fetch and display real data from Firestore instead of using mock data.

## Prerequisites

1. Node.js installed on your computer
2. Firebase project with Firestore enabled
3. Firebase service account key (JSON file)

## Setup Instructions

1. Download your Firebase service account key:
   - Go to the Firebase Console: https://console.firebase.google.com/
   - Select your project
   - Go to Project Settings > Service Accounts
   - Click "Generate new private key"
   - Save the JSON file as `serviceAccountKey.json` in the `temp_routes` folder

2. Run the batch file:
   - Double-click on `upload_routes.bat` or run it from the command line
   - The script will install the necessary dependencies and upload the routes to Firestore

## What This Tool Does

1. Clears any existing routes in the Firestore `routes` collection
2. Uploads all the routes defined in the script to Firestore
3. Each route includes:
   - Route name, code, and description
   - PUV type (Jeepney, Bus, Multicab, Motorela)
   - Waypoints (latitude/longitude coordinates)
   - Start and end point names
   - Estimated travel time and fare price
   - Color value for display
   - Active status

## Routes Included

The following routes are included in this uploader:

1. **R2** - Gaisano-Agora-Cogon-Carmen (Jeepney)
2. **C2** - Patag-Gaisano-Limketkai-Cogon (Jeepney)
3. **RA** - Pier-Gaisano-Ayala-Cogon (Jeepney)
4. **RD** - Gusa-Cugman-Cogon-Limketkai (Jeepney)
5. **LA** - Lapasan to Divisoria (Jeepney)
6. **R3** - Lapasan-Cogon Market (Loop) (Bus)
7. **RC** - Cugman-Velez-Divisoria-Cogon (Bus)
8. **RB** - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan (Multicab)
9. **BLUE** - Agora-Osmena-Cogon (Loop) (Motorela)

## After Running

After running this tool, the route management feature in the operator mode of the iPara app will be able to fetch and display these routes from Firestore. You can then:

1. View all routes in the route management screen
2. Filter routes by PUV type
3. Edit existing routes
4. Create new routes
5. Delete routes (which sets their `isActive` flag to false)

## Troubleshooting

If you encounter any issues:

1. Make sure your `serviceAccountKey.json` file is in the correct location
2. Check that your Firebase project has Firestore enabled
3. Verify that your service account has write access to Firestore
4. Check the console output for any error messages
