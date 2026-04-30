# Firebase Backend Setup Guide

Your VTU app is now configured to use **Firebase** as the backend instead of a custom API server. This is much simpler and more secure.

## What Changed

### ✅ Updated Files
1. **login_screen.dart** - Now uses Firebase email/password authentication
2. **register_screen.dart** - Now uses Firebase to create accounts
3. **AuthProvider** - Already had Firebase integration (no changes needed)

### ✅ Removed
- Custom API calls via ApiService
- Phone number only authentication
- Referral code field (can be added to Firestore later)

### ✅ Added
- Email-based authentication via Firebase Auth
- Firestore user data storage
- Improved error handling

---

## Firebase Configuration

Your Firebase project is already initialized in `lib/firebase_options.dart`.

### Step 1: Verify Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your VTU App project
3. Confirm these services are enabled:
   - ✅ Authentication (Email/Password)
   - ✅ Cloud Firestore
   - ✅ Storage (optional, for profile pics)

### Step 2: Enable Email/Password Authentication
1. In Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password" provider
3. Click Save

### Step 3: Create Firestore Database
1. In Firebase Console → Firestore Database
2. Click "Create database"
3. Start in **Test mode** (for development)
4. Choose a region (preferably closest to your users)
5. Click Done

### Step 4: Set Firestore Rules (Security)
Copy this to your Firestore Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Transactions collection
    match /transactions/{transactionId} {
      allow read: if request.auth.uid == resource.data.user_id;
      allow write: if request.auth.uid == request.resource.data.user_id;
    }
  }
}
```

---

## Authentication Flow

### Registration
```
User Input (Email + Password)
    ↓
Firebase Auth (Creates account)
    ↓
Firebase Firestore (Saves user profile)
    ↓
Local Storage (Saves user data)
    ↓
Create PIN Screen
```

### Login
```
User Input (Email + Password)
    ↓
Firebase Auth (Authenticates)
    ↓
Load user data from Firestore
    ↓
Dashboard
```

---

## User Data Structure (Firestore)

Your users are stored in Firestore with this structure:

```
firestore
└── users/
    └── {uid} (Firebase auth ID)
        ├── full_name: "John Doe"
        ├── email: "john@example.com"
        ├── phone: "+2348123456789"
        ├── created_at: "2026-04-26T..."
        └── transaction_pin: "1234" (encrypted)
```

---

## Testing

### Test Registration
1. Open app and go to Register
2. Fill in:
   - Full Name: John Doe
   - Email: test@example.com
   - Phone: 8123456789
   - Password: Test123!@
   - Agree to terms
3. Click "Create Account"

Expected: User appears in Firebase Console → Authentication

### Test Login
1. Go to Login
2. Enter: test@example.com / Test123!@
3. Should see "Login successful!"

Expected: Redirected to dashboard

---

## Troubleshooting

### Issue: "Registration failed"
- **Solution**: Check Firebase Console for error logs
- Ensure email is valid
- Password must be 6+ characters

### Issue: "Login failed"
- **Solution**: Verify email/password are correct
- Check user exists in Firebase Authentication
- Clear app data and try again

### Issue: User data not saving
- **Solution**: Check Firestore rules are correct
- Verify collection is named "users"
- Check user ID matches Firebase auth UID

### Issue: App crashes on login
- **Solution**: Ensure FirebaseService.setup() is called in main.dart
- Check firebase_options.dart has correct config

---

## Next Steps

### Add Phone Number Verification
Currently, phone is stored but not verified. To add OTP:

1. Use Firebase Phone Auth or custom OTP service
2. Update `FirebaseAuthService` in `lib/services/`
3. Verify phone before allowing transactions

### Add Profile Picture Upload
1. Enable Firebase Storage
2. Add image picker dependency
3. Upload to `gs://bucket-name/users/{uid}/profile.jpg`

### Monitor Users
1. Firebase Console → Authentication → Users
2. See all registered users, sign-up dates, last login

---

## Security Tips

1. ✅ Never commit firebase_options.dart to public repos
2. ✅ Use strong password requirements in validator
3. ✅ Enable reCAPTCHA in Authentication settings
4. ✅ Set up backup codes for account recovery
5. ✅ Monitor suspicious login attempts

---

## Production Setup

Before going live:

1. **Upgrade from Test Mode**
   - Go to Firestore Rules
   - Update to production rules (shown above)
   - Deploy

2. **Enable Email Verification**
   - Auth → Templates → Email verification
   - Customize message

3. **Set up Password Reset**
   - Auth → Templates → Password reset
   - Customize message

4. **Enable Multi-factor Authentication (optional)**
   - Auth → Sign-in method → MFA

---

## Useful Links

- [Firebase Console](https://console.firebase.google.com)
- [Firebase Auth Docs](https://firebase.google.com/docs/auth)
- [Firestore Docs](https://firebase.google.com/docs/firestore)
- [FlutterFire Docs](https://firebase.flutter.dev)

