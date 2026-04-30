# Firebase Cloud Functions Setup & Deployment Guide

## Overview
This guide explains how to deploy the Monnify Firebase Cloud Functions and set up the Flutter app to use them.

## Architecture
```
Flutter Web App (Flutter Web Browser)
    ↓ (HTTPS - No CORS issues)
Firebase Cloud Functions
    ↓ (Backend-to-Backend - Fully allowed)
Monnify API
```

## Prerequisites
1. Firebase project set up
2. Node.js 18+ installed
3. Firebase CLI installed (`npm install -g firebase-tools`)
4. Monnify API credentials (API Key, API Secret, Contract Code)

## Step 1: Set Up Firebase Environment Variables

### 1.1 Store Monnify Credentials in Firebase
```bash
cd functions

# Set Monnify API key
firebase functions:config:set monnify.api_key="MK_TEST_R284ZF2W8Y"

# Set Monnify API secret
firebase functions:config:set monnify.api_secret="8E4TK6XZ41UVDJ3705PPHGSDLQK7PS07"

# Set Monnify contract code
firebase functions:config:set monnify.contract_code="9529108403"
```

### 1.2 Verify Configuration
```bash
firebase functions:config:get
```

You should see:
```json
{
  "monnify": {
    "api_key": "MK_TEST_R284ZF2W8Y",
    "api_secret": "8E4TK6XZ41UVDJ3705PPHGSDLQK7PS07",
    "contract_code": "9529108403"
  }
}
```

## Step 2: Install Firebase Functions Dependencies

```bash
cd functions
npm install
```

Dependencies installed:
- `firebase-functions`: Firebase Cloud Functions runtime
- `firebase-admin`: Firebase Admin SDK for Firestore
- `axios`: HTTP client for calling Monnify API

## Step 3: Test Locally (Optional)

```bash
npm run serve
```

This starts the Firebase emulator. You can test functions locally before deployment.

## Step 4: Deploy to Firebase

### 4.1 Deploy Functions Only
```bash
firebase deploy --only functions
```

### 4.2 Deploy Specific Function
```bash
firebase deploy --only functions:createVirtualAccount
```

### 4.3 View Deployment Logs
```bash
firebase functions:log
```

## Step 5: Update Flutter App

### 5.1 Add cloud_functions to pubspec.yaml
```yaml
dependencies:
  cloud_functions: ^4.5.0
```

### 5.2 Initialize Service in main.dart
```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:vtu_app/services/monnify_firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Monnify Firebase Service
  MonnifyFirebaseService().init(region: 'us-central1');
  
  runApp(const VtuApp());
}
```

### 5.3 Use Service in Screens
```dart
import 'package:vtu_app/services/monnify_firebase_service.dart';

// In your widget
final monnifyService = MonnifyFirebaseService();

// Create virtual account
final account = await monnifyService.createVirtualAccount(
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '+2348012345678',
  bvn: '12345678901',
);

print('Account: ${account['accountNumber']}');
```

## Firebase Functions API Reference

### createVirtualAccount
Creates a virtual account for an authenticated user.

**Parameters:**
- `firstName` (string, required): User's first name
- `lastName` (string, required): User's last name
- `email` (string, required): User's email
- `phone` (string, required): User's phone number
- `bvn` (string, optional): Bank Verification Number (11 digits)
- `nin` (string, optional): National ID Number (11 digits)

**Returns:**
```json
{
  "success": true,
  "message": "Virtual account created successfully",
  "account": {
    "accountNumber": "1234567890",
    "accountName": "John Doe",
    "bankName": "Access Bank",
    "bankCode": "044",
    "accountReference": "user-uid-123",
    "createdAt": "2024-01-15T10:30:00.000Z"
  }
}
```

**Error Handling:**
- `unauthenticated`: User not logged in
- `invalid-argument`: Missing or invalid fields
- `internal`: Monnify API error

### getVirtualAccount
Retrieves existing virtual account details.

**Parameters:**
- `accountReference` (string, required): Account reference (Firebase UID)

**Returns:**
```json
{
  "success": true,
  "account": {
    "accountNumber": "1234567890",
    "accountName": "John Doe",
    "bankName": "Access Bank"
  }
}
```

### verifyTransaction
Verifies a transaction with Monnify.

**Parameters:**
- `transactionReference` (string, required): Transaction reference

**Returns:**
```json
{
  "success": true,
  "transaction": {
    "transactionReference": "REF123",
    "status": "successful",
    "amount": 50000,
    "currency": "NGN"
  }
}
```

## Security Best Practices

✅ **What we did right:**
1. API credentials stored in Firebase environment config (not in code)
2. User authentication required before creating accounts
3. No direct API calls from Flutter Web
4. Backend validates all input
5. Firestore security rules can limit access

⚠️ **Additional Security (Recommended):**
1. Set up Firestore security rules:
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only allow users to access their own documents
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

2. Enable Firebase App Check to prevent abuse:
```bash
firebase firestore:create-indexes
```

3. Set rate limiting on functions (in firebase.json):
```json
{
  "functions": {
    "memory": 256,
    "timeoutSeconds": 30,
    "maxInstances": 100
  }
}
```

## Troubleshooting

### Issue: "Function not found" error
**Solution:** Make sure functions are deployed
```bash
firebase deploy --only functions
firebase functions:log
```

### Issue: "CORS error" still appearing
**Solution:** Verify you're calling Firebase functions, not direct APIs
```dart
// ✅ Correct - Uses Firebase Functions
final callable = _functions.httpsCallable('createVirtualAccount');

// ❌ Wrong - Direct API call (will have CORS issues)
// final response = await dio.post('https://api.monnify.com/...');
```

### Issue: "Monnify authentication failed"
**Solution:** Verify credentials in Firebase environment config
```bash
firebase functions:config:get
```

### Issue: Function timeout
**Solution:** Increase timeout in functions/index.js
```javascript
exports.createVirtualAccount = functions
  .runWith({ timeoutSeconds: 60 })
  .https.onCall(async (data, context) => {
    // ...
  });
```

## Monitoring & Logging

### View Function Logs
```bash
firebase functions:log --limit 50
```

### Set Up CloudWatch Monitoring
In Google Cloud Console:
1. Go to Cloud Functions
2. Select your function
3. Go to "Logs" tab
4. View execution logs, errors, and performance

### Monitor Monnify API Status
```javascript
// In index.js - Add monitoring
console.log(`[${new Date().toISOString()}] Function called by user: ${uid}`);
```

## Production Checklist

- [ ] Set environment variables for production Monnify credentials
- [ ] Enable Firebase App Check
- [ ] Set up Firestore security rules
- [ ] Configure rate limiting
- [ ] Set up error monitoring (Firebase Crashlytics)
- [ ] Test on web, iOS, and Android
- [ ] Set up monitoring alerts
- [ ] Document API changes for team
- [ ] Set up CI/CD for function deployment

## CI/CD Deployment (GitHub Actions)

Create `.github/workflows/deploy-functions.yml`:
```yaml
name: Deploy Firebase Functions

on:
  push:
    branches:
      - main
    paths:
      - 'functions/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Firebase
        uses: w9jds/firebase-action@master
        with:
          args: deploy --only functions
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

## References

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Monnify API Documentation](https://docs.monnify.com)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Cloud Functions Best Practices](https://cloud.google.com/functions/docs/bestpractices)
