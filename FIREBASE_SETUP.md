# Firebase Setup for Pet Clinic App

This guide will help you set up Firebase for your Pet Clinic Flutter app.

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter a project name (e.g., "Pet Clinic")
4. Optionally enable Google Analytics
5. Click "Create project"

## Step 2: Register your app with Firebase

### For Web:

1. In the Firebase console, click the web icon (</>) to add a web app
2. Enter a nickname for your app (e.g., "Pet Clinic Web")
3. Register the app
4. Copy the Firebase configuration

### Update your Firebase configuration

1. Open `web/index.html` and replace the placeholder values in the Firebase configuration:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_AUTH_DOMAIN",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_STORAGE_BUCKET",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID"
};
```

2. Open `lib/main.dart` and replace the placeholder values in the `Firebase.initializeApp()` function:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    appId: "YOUR_APP_ID",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    projectId: "YOUR_PROJECT_ID",
  ),
);
```

## Step 3: Set up Firestore Database

1. In the Firebase console, go to "Firestore Database"
2. Click "Create database" 
3. Start in test mode (allows anyone to read/write to the database)
4. Choose a location closest to your users
5. Click "Enable"

### Create a Collection for Appointments

1. In Firestore Database, click "Start collection"
2. Collection ID: `appointments`
3. Skip the document creation step for now (your app will create documents)

## Step 4: Deploy Your Application

1. Install Node.js from [nodejs.org](https://nodejs.org/)
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login to Firebase: `firebase login`
4. Initialize your project: `firebase use --add YOUR_PROJECT_ID`
5. Build your app: `flutter build web`
6. Deploy your app: `firebase deploy`

Your app will be available at: https://YOUR_PROJECT_ID.web.app

## Troubleshooting

If you encounter issues:

- Run `flutter clean` and then `flutter pub get` to clean the project
- Make sure all Firebase configuration values are correctly copied
- Ensure you're using compatible Firebase package versions in `pubspec.yaml`
- If you experience network image loading issues, consider using local assets instead
- For web deployment, ensure your index.html has the correct Firebase scripts
- Enable offline persistence in your Firebase service for better offline support

## Security Notes

- The current Firestore rules allow anyone to read/write to the database, which is fine for development
- For production, update the rules in `firestore.rules` to secure your data 