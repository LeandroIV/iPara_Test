// Firebase Admin SDK setup for iPara route data uploader
const admin = require('firebase-admin');

// Initialize Firebase Admin with service account
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define PUV routes with all details from route_service.dart
const routes = [
  {
    id: 'R2',
    name: 'R2 - Gaisano-Agora-Cogon-Carmen',
    description: 'Route from Carmen to Divisoria via Corrales Avenue',
    puvType: 'Jeepney',
    routeCode: 'R2',
    waypoints: [
      {latitude: 8.486261, longitude: 124.649210}, // gaisano
      {latitude: 8.488737, longitude: 124.654004}, //osmena
      {latitude: 8.488257, longitude: 124.657648}, // agora market
      {latitude: 8.484704, longitude: 124.656401}, // ustp
      {latitude: 8.484704, longitude: 124.656401}, // ustp
      {latitude: 8.478534, longitude: 124.654355}, // pearl mont
      {latitude: 8.478744, longitude: 124.652822}, // pearl mont unahan
      {latitude: 8.479595, longitude: 124.649240}, // cogon
      {latitude: 8.477819, longitude: 124.642316}, // capistrano
      {latitude: 8.476322, longitude: 124.640128}, // yselina bridge
      {latitude: 8.481712, longitude: 124.637232}, // coc terminal
      {latitude: 8.484994, longitude: 124.637248}, // mango st
      {latitude: 8.486158, longitude: 124.638827}, // liceo
      {latitude: 8.486261, longitude: 124.649210}, // gaisano
    ],
    startPointName: 'Gaisano',
    endPointName: 'Carmen',
    estimatedTravelTime: 25,
    farePrice: 12.0,
    colorValue: 0xFFFF6D00, // Deep Orange
    isActive: true,
  },
  {
    id: 'C2',
    name: 'C2 - Patag-Gaisano-Limketkai-Cogon',
    description: 'Route from Patag to Cogon via Gaisano',
    puvType: 'Jeepney',
    routeCode: 'C2',
    waypoints: [
      {latitude: 8.477434, longitude: 124.649630}, // Cogon
      {latitude: 8.476343, longitude: 124.639981}, // ysalina bridge
      {latitude: 8.480251, longitude: 124.637131}, // carmen cogon
      {latitude: 8.485040, longitude: 124.637276}, // mango st
      {latitude: 8.487765, longitude: 124.626766}, // Patag
      {latitude: 8.486605, longitude: 124.638888}, // lieo
      {latitude: 8.486261, longitude: 124.649210}, // gaisano
      {latitude: 8.477434, longitude: 124.649630}, // Cogon
    ],
    startPointName: 'Patag',
    endPointName: 'Cogon',
    estimatedTravelTime: 30,
    farePrice: 13.0,
    colorValue: 0xFF2196F3, // Blue
    isActive: true,
  },
  {
    id: 'RA',
    name: 'RA - Pier-Gaisano-Ayala-Cogon',
    description: 'Route from Pier to Cogon via Gaisano',
    puvType: 'Jeepney',
    routeCode: 'RA',
    waypoints: [
      {latitude: 8.486684, longitude: 124.650807}, // Gaisano main
      {latitude: 8.498177, longitude: 124.660786}, // Pier
      {latitude: 8.504380, longitude: 124.661618}, // Macabalan Edge
      {latitude: 8.503708, longitude: 124.659001}, // Macabalan
      {latitude: 8.498178, longitude: 124.660057}, // Juliu Pacana St
      {latitude: 8.476927, longitude: 124.644083}, // Divisoria Plaza
      {latitude: 8.476425, longitude: 124.645800}, // Xavier
      {latitude: 8.476817, longitude: 124.652773}, // borja st
      {latitude: 8.477448, longitude: 124.652930}, // Roxas St
      {latitude: 8.477855, longitude: 124.651483}, // yacapin to vicente
      {latitude: 8.480664, longitude: 124.650289}, // Ebarle st
      {latitude: 8.485169, longitude: 124.650207}, // Ayala
      {latitude: 8.486684, longitude: 124.650807}, // Gaisano main
    ],
    startPointName: 'Pier',
    endPointName: 'Cogon',
    estimatedTravelTime: 45,
    farePrice: 15.0,
    colorValue: 0xFF4CAF50, // Green
    isActive: true,
  },
  {
    id: 'RD',
    name: 'RD - Gusa-Cugman-Cogon-Limketkai',
    description: 'Route from Cugman to Limketkai via Gusa',
    puvType: 'Jeepney',
    routeCode: 'RD',
    waypoints: [
      {latitude: 8.469899, longitude: 124.705196}, // cugman
      {latitude: 8.477536, longitude: 124.676559}, // Gusa
      {latitude: 8.486028, longitude: 124.650684}, // Gaisano
      {latitude: 8.485010, longitude: 124.647179}, // Velez
      {latitude: 8.485627, longitude: 124.646200}, // capistrano
      {latitude: 8.477565, longitude: 124.642297}, // Divisoria
      {latitude: 8.476425, longitude: 124.645800}, // Xavier
      {latitude: 8.476817, longitude: 124.652773}, // borja
      {latitude: 8.477595, longitude: 124.653591}, // yacapin
      {latitude: 8.484484, longitude: 124.657109}, // ketkai
      {latitude: 8.469899, longitude: 124.705196}, // cugman
    ],
    startPointName: 'Cugman',
    endPointName: 'Limketkai',
    estimatedTravelTime: 35,
    farePrice: 14.0,
    colorValue: 0xFFE91E63, // Pink
    isActive: true,
  },
  {
    id: 'LA',
    name: 'LA - Lapasan to Divisoria',
    description: 'Route from Lapasan to Divisoria',
    puvType: 'Jeepney',
    routeCode: 'LA',
    waypoints: [
      {latitude: 8.479595, longitude: 124.649240}, // Cogon
      {latitude: 8.481712, longitude: 124.637232}, // Carmen terminal
      {latitude: 8.490123, longitude: 124.652781}, // Lapasan
      {latitude: 8.498177, longitude: 124.660786}, // Pier
      {latitude: 8.490123, longitude: 124.652781}, // Lapasan
      {latitude: 8.481712, longitude: 124.637232}, // Carmen terminal
      {latitude: 8.479595, longitude: 124.649240}, // Cogon
    ],
    startPointName: 'Pier',
    endPointName: 'Cogon',
    estimatedTravelTime: 45,
    farePrice: 15.0,
    colorValue: 0xFF9C27B0, // Purple
    isActive: true,
  },
  // New Bus Route: R3 - Lapasan to Cogon Market (Loop)
  {
    id: 'R3',
    name: 'R3 - Lapasan-Cogon Market (Loop)',
    description: 'Route from Lapasan to Cogon Market and back in a loop',
    puvType: 'Bus',
    routeCode: 'R3',
    waypoints: [
      {latitude: 8.482776, longitude: 124.664608}, // Lapasan
      {latitude: 8.486510, longitude: 124.648319}, // Gaisano
      {latitude: 8.477458, longitude: 124.644200}, // Cogon Market
      {latitude: 8.477023, longitude: 124.645975}, // Yacapin
      {latitude: 8.478459, longitude: 124.646503}, // Velez
      {latitude: 8.480728, longitude: 124.657680}, // Back to Lapasan
      {latitude: 8.482776, longitude: 124.664608}, // Lapasan
    ],
    startPointName: 'Lapasan',
    endPointName: 'Cogon Market',
    estimatedTravelTime: 40,
    farePrice: 15.0,
    colorValue: 0xFF3F51B5, // Indigo
    isActive: true,
  },
  {
    id: 'RC',
    name: 'RC - Cugman - Velez - Divisoria - Cogon',
    description: 'Route from Cugman to Cogon via Velez',
    puvType: 'Bus',
    routeCode: 'RC',
    waypoints: [
      {latitude: 8.469449, longitude: 124.705358}, // Cugman
      {latitude: 8.469031, longitude: 124.703102}, // U-turn
      {latitude: 8.482910, longitude: 124.646112}, // Velez_main
      {latitude: 8.486411, longitude: 124.648293}, // Velez
      {latitude: 8.480066, longitude: 124.644827}, // D-Morvie
      {latitude: 8.480302, longitude: 124.643627}, // Rizal
      {latitude: 8.477783, longitude: 124.643120}, // Divisoria
      {latitude: 8.477131, longitude: 124.646014}, // xavier
      {latitude: 8.477219, longitude: 124.649640}, // Borja
      {latitude: 8.476823, longitude: 124.652875}, // Cogon
      {latitude: 8.477613, longitude: 124.653608}, // pearlmont
      {latitude: 8.484305, longitude: 124.657059}, // Shakeys
      {latitude: 8.469449, longitude: 124.705358}, // Cugman
    ],
    startPointName: 'Cugman',
    endPointName: 'Cogon Market',
    estimatedTravelTime: 40,
    farePrice: 12.0,
    colorValue: 0xFFFFC0CB, // Pink
    isActive: true,
  },
  // New Multicab Route: RB - Pier to Macabalan
  {
    id: 'RBC',
    name: 'RBC - Pier-Puregold-Cogon-Velez-Julio Pacana-Macabalan',
    description: 'Route from Pier through city center to Macabalan',
    puvType: 'Multicab',
    routeCode: 'RBC',
    waypoints: [
      {latitude: 8.498177, longitude: 124.660786}, // Pier
      {latitude: 8.489390, longitude: 124.657666}, // Agora
      {latitude: 8.484315, longitude: 124.658291}, // Puregold
      {latitude: 8.480585, longitude: 124.657328}, // limketkai
      {latitude: 8.478014, longitude: 124.650861}, // Cogon
      {latitude: 8.480090, longitude: 124.644857}, // Velez
      {latitude: 8.498178, longitude: 124.660057}, // Julio Pacana St
      {latitude: 8.502677, longitude: 124.664270}, // Macabalan
      {latitude: 8.503693, longitude: 124.659047}, // Macabalan
      {latitude: 8.498177, longitude: 124.660786}, // Pier
    ],
    startPointName: 'Pier',
    endPointName: 'Cogon',
    estimatedTravelTime: 35,
    farePrice: 12.0,
    colorValue: 0xFFFF5722, // Deep Orange
    isActive: true,
  },
  // New Motorela Route: BLUE - Agora to Cogon (Loop)
  {
    id: 'BLUE',
    name: 'BLUE - Agora-Osmena-Cogon (Loop)',
    description: 'Route from Agora through Osmena to Cogon in a loop',
    puvType: 'Motorela',
    routeCode: 'BLUE',
    waypoints: [
      {latitude: 8.489290, longitude: 124.657606}, // Agora Market
      {latitude: 8.488186, longitude: 124.659699}, // Agora - tulay semento
      {latitude: 8.490775, longitude: 124.655332}, // Osmena
      {latitude: 8.484709, longitude: 124.653492}, // Osmena
      {latitude: 8.477754, longitude: 124.652605}, // Cogon
      {latitude: 8.485069, longitude: 124.653629}, // U-Turn
      {latitude: 8.490868, longitude: 124.655387}, // Osmena
      {latitude: 8.489290, longitude: 124.657606}, // Agora Market
    ],
    startPointName: 'Agora',
    endPointName: 'Cogon',
    estimatedTravelTime: 25,
    farePrice: 10.0,
    colorValue: 0xFF03A9F4, // Light Blue
    isActive: true,
  }
];

// Function to upload routes to Firestore
async function uploadRoutesToFirestore() {
  try {
    // Clear existing routes first
    console.log('Checking for existing routes...');
    const existingRoutes = await db.collection('routes').get();

    if (!existingRoutes.empty) {
      console.log(`Found ${existingRoutes.size} existing routes. Removing...`);
      const batch = db.batch();
      existingRoutes.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log('Existing routes removed successfully.');
    } else {
      console.log('No existing routes found.');
    }

    // Upload each route
    console.log('Uploading routes to Firestore...');
    for (const route of routes) {
      const { id, ...routeData } = route;

      // Add timestamp and ensure isActive is true
      routeData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      routeData.isActive = true;

      // Use the routeCode as the document ID to ensure consistency
      const docId = route.routeCode;

      // Use set with merge to handle existing documents
      await db.collection('routes').doc(docId).set(routeData, { merge: true });
      console.log(`Route ${route.routeCode} (${route.name}) uploaded successfully.`);
    }

    console.log('All routes uploaded successfully!');
  } catch (error) {
    console.error('Error uploading routes:', error);
  }
}

// Execute the upload function
uploadRoutesToFirestore();
