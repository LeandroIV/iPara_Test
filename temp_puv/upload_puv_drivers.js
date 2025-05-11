// Firebase Admin SDK setup for iPara mock PUV data uploader
const admin = require('firebase-admin');

// Initialize Firebase Admin with service account
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define PUV routes with waypoints
const routes = [
  {
    id: 'R3',
    name: 'R3 - Lapasan-Cogon Market (Loop)',
    routeCode: 'R3',
    puvType: 'Bus',
    waypoints: [
      {lat: 8.490123, lng: 124.652781}, // Lapasan
      {lat: 8.486028, lng: 124.650684}, // Gaisano
      {lat: 8.479595, lng: 124.649240}, // Cogon Market
      {lat: 8.477595, lng: 124.653591}, // Yacapin
      {lat: 8.485010, lng: 124.647179}, // Velez
      {lat: 8.490123, lng: 124.652781}, // Back to Lapasan
    ]
  },
  {
    id: 'RB',
    name: 'RB - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan',
    routeCode: 'RB',
    puvType: 'Multicab',
    waypoints: [
      {lat: 8.498177, lng: 124.660786}, // Pier
      {lat: 8.486684, lng: 124.650807}, // Puregold/Gaisano
      {lat: 8.479595, lng: 124.649240}, // Cogon
      {lat: 8.485010, lng: 124.647179}, // Velez
      {lat: 8.498178, lng: 124.660057}, // Julio Pacana St
      {lat: 8.503708, lng: 124.659001}, // Macabalan
    ]
  },
  {
    id: 'BLUE',
    name: 'BLUE - Agora-Osmena-Cogon (Loop)',
    routeCode: 'BLUE',
    puvType: 'Motorela',
    waypoints: [
      {lat: 8.488257, lng: 124.657648}, // Agora Market
      {lat: 8.488737, lng: 124.654004}, // Osmena
      {lat: 8.479595, lng: 124.649240}, // Cogon
      {lat: 8.484704, lng: 124.656401}, // USTP
      {lat: 8.488257, lng: 124.657648}, // Back to Agora
    ]
  }
];

// Filipino driver names
const firstNames = [
  'Juan', 'Pedro', 'Miguel', 'Jose', 'Antonio', 'Ricardo', 'Eduardo', 'Francisco',
  'Roberto', 'Manuel', 'Danilo', 'Rodrigo', 'Ernesto', 'Fernando', 'Andres',
  'Maria', 'Rosa', 'Ana', 'Luisa', 'Elena', 'Josefa', 'Margarita', 'Teresita',
  'Juana', 'Rosario', 'Corazon', 'Gloria', 'Lourdes', 'Natividad', 'Remedios'
];

const lastNames = [
  'Garcia', 'Santos', 'Reyes', 'Cruz', 'Bautista', 'Gonzales', 'Ramos', 'Aquino',
  'Diaz', 'Castro', 'Mendoza', 'Torres', 'Flores', 'Villanueva', 'Fernandez',
  'Morales', 'Perez', 'Ramirez', 'Hernandez', 'Pascual', 'Delos Santos', 'Tolentino',
  'Valdez', 'Gutierrez', 'Navarro', 'Domingo', 'Salazar', 'Del Rosario', 'Mercado'
];

// Generate a random driver name
function generateDriverName() {
  const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
  const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
  return `${firstName} ${lastName}`;
}

// Generate a random plate number based on PUV type
function generatePlateNumber(puvType) {
  let prefix;
  switch(puvType) {
    case 'Bus':
      prefix = 'BUS';
      break;
    case 'Multicab':
      prefix = 'MCB';
      break;
    case 'Motorela':
      prefix = 'MTR';
      break;
    default:
      prefix = 'PUV';
  }
  const number = 100 + Math.floor(Math.random() * 900);
  return `${prefix}-${number}`;
}

// Generate a random speed (10-40 km/h)
function generateSpeed() {
  return 2.8 + Math.random() * 8.3; // 10-40 km/h in m/s
}

// Generate a random rating between 3.0 and 5.0
function generateRating() {
  return (3.0 + Math.random() * 2.0).toFixed(1);
}

// Generate a random capacity based on PUV type
function generateCapacity(puvType) {
  let maxCapacity;
  switch(puvType) {
    case 'Bus':
      maxCapacity = 50;
      break;
    case 'Multicab':
      maxCapacity = 12;
      break;
    case 'Motorela':
      maxCapacity = 8;
      break;
    default:
      maxCapacity = 10;
  }
  const currentPassengers = Math.floor(Math.random() * (maxCapacity + 1));
  return `${currentPassengers}/${maxCapacity}`;
}

// Generate a random status
function generateStatus() {
  const statuses = ['Available', 'En Route', 'Full', 'On Break'];
  return statuses[Math.floor(Math.random() * statuses.length)];
}

// Generate a random ETA
function generateETA() {
  return 5 + Math.floor(Math.random() * 26); // 5-30 minutes
}

// Calculate heading based on current and next point
function calculateHeading(current, next) {
  const dLng = next.lng - current.lng;
  const y = Math.sin(dLng * (Math.PI / 180)) * Math.cos(next.lat * (Math.PI / 180));
  const x = Math.cos(current.lat * (Math.PI / 180)) * Math.sin(next.lat * (Math.PI / 180)) -
          Math.sin(current.lat * (Math.PI / 180)) * Math.cos(next.lat * (Math.PI / 180)) * Math.cos(dLng * (Math.PI / 180));
  let heading = Math.atan2(y, x) * (180 / Math.PI);
  if (heading < 0) {
    heading += 360;
  }
  return heading;
}

// Generate mock PUV drivers
async function generateMockPUVDrivers() {
  try {
    // Clear existing mock drivers for these PUV types
    const puvTypes = ['Bus', 'Multicab', 'Motorela'];
    for (const puvType of puvTypes) {
      const existingDrivers = await db.collection('driver_locations')
        .where('isMockData', '==', true)
        .where('puvType', '==', puvType)
        .get();
      console.log(`Removing ${existingDrivers.size} existing mock ${puvType} drivers...`);
      const batch = db.batch();
      existingDrivers.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
    }

    // Number of drivers per route
    const driversPerRoute = 5;
    let driverIndex = 0;

    // Create mock drivers for each route
    for (const route of routes) {
      console.log(`Creating ${driversPerRoute} ${route.puvType} drivers for route ${route.routeCode}...`);

      // Create multiple drivers for this route
      for (let i = 0; i < driversPerRoute; i++) {
        // Place driver at a random position along the route
        const waypointIndex = Math.floor(Math.random() * route.waypoints.length);
        const location = route.waypoints[waypointIndex];

        // Calculate heading based on next waypoint
        let heading = 0;
        if (route.waypoints.length > 1) {
          const nextIndex = (waypointIndex + 1) % route.waypoints.length;
          const nextPoint = route.waypoints[nextIndex];
          heading = calculateHeading(location, nextPoint);
        } else {
          heading = Math.random() * 360;
        }

        // Generate driver details
        const driverName = generateDriverName();
        const plateNumber = generatePlateNumber(route.puvType);
        const rating = generateRating();
        const capacity = generateCapacity(route.puvType);
        const status = generateStatus();
        const etaMinutes = generateETA();
        const speed = generateSpeed();

        // Create a unique ID for this driver
        const docId = `mock_${route.puvType.toLowerCase()}_${driverIndex++}`;

        // Create driver document
        await db.collection('driver_locations').doc(docId).set({
          userId: docId,
          location: new admin.firestore.GeoPoint(location.lat, location.lng),
          heading: heading,
          speed: speed,
          isLocationVisible: true,
          isOnline: true,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          puvType: route.puvType,
          plateNumber: plateNumber,
          capacity: capacity,
          driverName: driverName,
          rating: rating,
          status: status,
          etaMinutes: etaMinutes,
          isMockData: true,
          routeId: route.id,
          routeCode: route.routeCode,
          iconType: route.puvType.toLowerCase(),
          photoUrl: `https://randomuser.me/api/portraits/${Math.random() > 0.5 ? 'women' : 'men'}/${Math.floor(Math.random() * 70) + 1}.jpg`
        });
      }
    }

    console.log(`Successfully created ${driverIndex} mock PUV drivers`);
  } catch (error) {
    console.error('Error generating mock PUV drivers:', error);
  }
}

// Run the generator
generateMockPUVDrivers();
