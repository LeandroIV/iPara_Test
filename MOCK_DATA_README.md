# iPara Mock Data Generator

This set of scripts helps you populate your Firebase database with realistic mock data for the iPara app, including:

1. **Mock Drivers** aligned with specific jeepney routes in CDO
2. **Mock Operators** who own vehicles
3. **Mock Vehicles** assigned to routes and operators
4. **Associations** between drivers and vehicles

## Prerequisites

Before using these scripts, make sure you have:

1. **Node.js** installed (download from https://nodejs.org/)
2. **Firebase Service Account Key** for your project

## Getting Your Firebase Service Account Key

To use these scripts, you'll need a service account key:

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `ipara-fd373`
3. Go to Project Settings > Service accounts
4. Click "Generate new private key"
5. Save the file as `serviceAccountKey.json`

## Available Scripts

### 1. `upload_mock_data.bat` (Main Script)

This is the master script that gives you options to:
- Upload operators and vehicles
- Upload drivers on routes
- Associate drivers with vehicles
- Run all steps in sequence

**Usage:**
```
upload_mock_data.bat
```

Follow the prompts to select which operation you want to perform.

### 2. `upload_mock_drivers.bat`

This script uploads mock drivers aligned with jeepney routes to your Firebase database.

**Usage:**
```
upload_mock_drivers.bat
```

The script will:
- Create 5 mock drivers for each of the 4 predefined routes (R2, C2, RA, RD)
- Position drivers at random points along their assigned routes
- Include realistic Filipino names, plate numbers, and other details
- Set appropriate headings based on the route direction

### 3. `upload_mock_operators.bat`

This script uploads mock operators and their vehicles to your Firebase database.

**Usage:**
```
upload_mock_operators.bat
```

The script will:
- Create 10 mock operators with Filipino names and contact details
- Create 2 vehicles for each operator
- Assign vehicles to random routes
- Include maintenance reminders for each vehicle

## Data Structure

### Drivers
- Stored in the `driver_locations` collection
- Include location, heading, speed, and other details
- Aligned with specific routes
- Have Filipino names and realistic ratings

### Operators
- Stored in the `users` collection with `role: 2`
- Own multiple vehicles
- Have Filipino names and contact details

### Vehicles
- Stored in the `vehicles` collection
- Associated with operators and routes
- Include maintenance reminders
- Have realistic plate numbers and models

## Using the Mock Data in the App

Once you've uploaded the mock data:

1. **Commuter Mode**: When a user selects a jeepney type and route, they will see the mock drivers positioned along that route.

2. **Driver Details**: When a user clicks on a driver icon, they will see details including:
   - Driver name and photo
   - Rating
   - ETA
   - Capacity
   - Status
   - Plate number

3. **Operator Mode**: Operators will see their vehicles and the drivers assigned to them.

## Cleaning Up

If you want to remove the mock data:

1. Use the Firebase console to delete documents with `isMockData: true`
2. Or create a new script based on these examples that removes all documents with this flag

## Troubleshooting

If you encounter issues:

1. **Script fails to run**: Make sure Node.js is installed and in your PATH
2. **Authentication errors**: Verify your serviceAccountKey.json is correct and in the right location
3. **No data appears**: Check the Firebase console to see if the data was uploaded correctly

## Customization

You can modify these scripts to:

- Change the number of mock drivers or operators
- Adjust the routes or add new ones
- Modify the Filipino names or other details
- Add more fields to the mock data

Look for the configuration variables at the top of each script's JavaScript file.
