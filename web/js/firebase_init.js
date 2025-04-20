// Initialize Firebase
document.addEventListener('DOMContentLoaded', function() {
  // Firebase configuration - REPLACE WITH YOUR CONFIG
  const firebaseConfig = {
    apiKey: "AIzaSyDHz7mQgHKldkc7eiYHmivK42x7Gr24nAE", // Use your Firebase API key
    authDomain: "ipara-fd373.firebaseapp.com",
    projectId: "ipara-fd373",
    storageBucket: "ipara-fd373.firebasestorage.app",
    messagingSenderId: "911307464919",
    appId: "1:911307464919:web:fd6a88247d11cd8855d092",
    measurementId: "G-35L6RP8CXS"
  };

  // Initialize Firebase
  try {
    // Check if Firebase is already initialized
    if (firebase && firebase.apps && firebase.apps.length > 0) {
      console.log('Firebase already initialized');
      window.firebaseInitComplete = true;
      return;
    }
    
    firebase.initializeApp(firebaseConfig);
    console.log('Firebase initialized successfully');
    window.firebaseInitComplete = true;
  } catch (e) {
    console.error('Error initializing Firebase:', e);
    window.firebaseInitComplete = false;
  }
}); 