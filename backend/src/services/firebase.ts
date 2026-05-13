// ============================================================
// Firebase Admin SDK Initialization
// ============================================================
// Setup instructions:
// 1. In the Firebase Console (https://console.firebase.google.com/):
//    - Go to Project Settings > Service Accounts
//    - Click "Generate New Private Key" to download the JSON file
// 2. Place the downloaded file at:
//    - backend/firebase-admin-sdk.json (add to .gitignore!)
// 3. Set the environment variable:
//    - FIREBASE_CREDENTIALS_PATH=./firebase-admin-sdk.json
//    - Or set GOOGLE_APPLICATION_CREDENTIALS to the full path
// 4. Run: npm install firebase-admin
// 5. Run: npx prisma generate (to pick up schema changes)
// ============================================================

import admin from "firebase-admin";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Determine the credential path
const credentialPath =
  process.env.FIREBASE_CREDENTIALS_PATH ||
  path.resolve(__dirname, "..", "..", "firebase-admin-sdk.json");

// Prevent double initialization
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(credentialPath as string),
    });
    console.log("Firebase Admin SDK initialized successfully");
  } catch (error) {
    console.error("Failed to initialize Firebase Admin SDK:", error);
    // In development without a service account file, we log a warning
    // but don't crash — notifications will fail gracefully at send time.
    if (process.env.NODE_ENV !== "production") {
      console.warn(
        "WARNING: Firebase Admin SDK not initialized. " +
          "Set FIREBASE_CREDENTIALS_PATH or place firebase-admin-sdk.json in the project root."
      );
    }
  }
}

export const firebaseApp = admin.apps.length > 0 ? admin.app() : null;
export const fcm = firebaseApp ? admin.messaging() : null;