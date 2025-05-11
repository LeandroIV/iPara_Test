// Firebase Admin SDK setup for iPara mock commuter data uploader
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
  },
  // Jeepney Routes
  {
    id: 'r2',
    name: 'R2 - Gaisano-Agora-Cogon-Carmen',
    routeCode: 'R2',
    puvType: 'Jeepney',
    waypoints: [
      {lat: 8.486261, lng: 124.649210}, // gaisano
      {lat: 8.488737, lng: 124.654004}, // osmena
      {lat: 8.488257, lng: 124.657648}, // agora market
      {lat: 8.484704, lng: 124.656401}, // ustp
      {lat: 8.478534, lng: 124.654355}, // pearl mont
      {lat: 8.478744, lng: 124.652822}, // pearl mont unahan
      {lat: 8.479595, lng: 124.649240}, // cogon
      {lat: 8.477819, lng: 124.642316}, // capistrano
    ]
  },
  {
    id: 'C2',
    name: 'C2 - Patag-Gaisano-Limketkai-Cogon',
    routeCode: 'C2',
    puvType: 'Jeepney',
    waypoints: [
      {lat: 8.477434, lng: 124.649630}, // Cogon
      {lat: 8.476343, lng: 124.639981}, // ysalina bridge
      {lat: 8.480251, lng: 124.637131}, // carmen cogon
      {lat: 8.485040, lng: 124.637276}, // mango st
      {lat: 8.487765, lng: 124.626766}, // Patag
      {lat: 8.486605, lng: 124.638888}, // lieo
      {lat: 8.486261, lng: 124.649210}, // gaisano
      {lat: 8.477434, lng: 124.649630}, // Cogon
    ]
  },
  {
    id: 'RA',
    name: 'RA - Pier-Gaisano-Ayala-Cogon',
    routeCode: 'RA',
    puvType: 'Jeepney',
    waypoints: [
      {lat: 8.486684, lng: 124.650807}, // Gaisano main
      {lat: 8.498177, lng: 124.660786}, // Pier
      {lat: 8.504380, lng: 124.661618}, // Macabalan Edge
      {lat: 8.503708, lng: 124.659001}, // Macabalan
      {lat: 8.498178, lng: 124.660057}, // Juliu Pacana St
      {lat: 8.476927, lng: 124.644083}, // Divisoria Plaza
      {lat: 8.476425, lng: 124.645800}, // Xavier
      {lat: 8.476817, lng: 124.652773}, // borja st
      {lat: 8.477448, lng: 124.652930}, // Roxas St
      {lat: 8.477855, lng: 124.651483}, // yacapin to vicente
      {lat: 8.480664, lng: 124.650289}, // Ebarle st
      {lat: 8.485169, lng: 124.650207}, // Ayala
    ]
  },
  {
    id: 'RD',
    name: 'RD - Gusa-Cugman-Cogon-Limketkai',
    routeCode: 'RD',
    puvType: 'Jeepney',
    waypoints: [
      {lat: 8.469899, lng: 124.705196}, // cugman
      {lat: 8.477536, lng: 124.676559}, // Gusa
      {lat: 8.486028, lng: 124.650684}, // Gaisano
      {lat: 8.485010, lng: 124.647179}, // Velez
      {lat: 8.485627, lng: 124.646200}, // capistrano
      {lat: 8.477565, lng: 124.642297}, // Divisoria
      {lat: 8.476425, lng: 124.645800}, // Xavier
      {lat: 8.476817, lng: 124.652773}, // borja
      {lat: 8.477595, lng: 124.653591}, // yacapin
      {lat: 8.484484, lng: 124.657109}, // ketkai
      {lat: 8.469899, lng: 124.705196}, // cugman
    ]
  },
  {
    id: 'LA',
    name: 'LA - Lapasan to Divisoria',
    routeCode: 'LA',
    puvType: 'Jeepney',
    waypoints: [
      {lat: 8.479595, lng: 124.649240}, // Cogon
      {lat: 8.481712, lng: 124.637232}, // Carmen terminal
      {lat: 8.490123, lng: 124.652781}, // Lapasan
      {lat: 8.498177, lng: 124.660786}, // Pier
      {lat: 8.490123, lng: 124.652781}, // Lapasan
      {lat: 8.481712, lng: 124.637232}, // Carmen terminal
      {lat: 8.479595, lng: 124.649240}, // Cogon
    ]
  }
];

// Filipino commuter names
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

// Generate a random commuter name
function generateCommuterName() {
  const firstName = firstNames[Math.floor(Math.random() * firstNames.length)];
  const lastName = lastNames[Math.floor(Math.random() * lastNames.length)];
  return `${firstName} ${lastName}`;
}

// Generate a random location near a route
function generateLocationNearRoute(route) {
  // Pick a random waypoint from the route
  const waypoint = route.waypoints[Math.floor(Math.random() * route.waypoints.length)];

  // Add a small random offset (up to ~100 meters)
  const latOffset = (Math.random() - 0.5) * 0.002; // ~100m in latitude
  const lngOffset = (Math.random() - 0.5) * 0.002; // ~100m in longitude
  return {
    lat: waypoint.lat + latOffset,
    lng: waypoint.lng + lngOffset
  };
}

// Generate mock commuters
async function generateMockCommuters() {
  try {
    // Clear existing mock commuters
    const existingCommuters = await db.collection('commuter_locations').where('isMockData', '==', true).get();
    console.log(`Removing ${existingCommuters.size} existing mock commuters...`);
    const batch = db.batch();
    existingCommuters.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    // Number of commuters per route
    const commutersPerRoute = 5;
    let commuterIndex = 0;

    // Create mock commuters for each route
    for (const route of routes) {
      console.log(`Creating ${commutersPerRoute} commuters for ${route.puvType} route ${route.routeCode}...`);

      for (let i = 0; i < commutersPerRoute; i++) {
        // Generate commuter details
        const commuterName = generateCommuterName();
        const location = generateLocationNearRoute(route);

        // Create a unique ID for this commuter
        const docId = `mock_commuter_${route.routeCode}_${commuterIndex++}`;

        // Create commuter document
        await db.collection('commuter_locations').doc(docId).set({
          userId: docId,
          userName: commuterName,
          location: new admin.firestore.GeoPoint(location.lat, location.lng),
          isLocationVisible: true,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          selectedPuvType: route.puvType,
          routeCode: route.routeCode,
          routeId: route.id,
          isMockData: true,
          iconType: 'person'
        });
      }
    }

    console.log(`Successfully created ${commuterIndex} mock commuters`);
  } catch (error) {
    console.error('Error generating mock commuters:', error);
  }
}

// Run the generator
generateMockCommuters();
