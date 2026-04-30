# Migration Guide: From Direct Monnify API to Firebase Cloud Functions

## Overview
This guide walks through migrating from direct Dio/HTTP requests to Monnify API to using Firebase Cloud Functions as a backend proxy.

## What Changed

### Before (Direct API - ❌ CORS Issues on Web)
```dart
// ❌ OLD - Direct API calls (CORS blocked on web)
final response = await _dio.post(
  'https://sandbox.monnify.com/api/v2/bank-transfer/reserved-accounts',
  data: requestData,
  options: Options(
    headers: {'Authorization': 'Basic $credentials'},
  ),
);
```

### After (Firebase Cloud Functions - ✅ No CORS)
```dart
// ✅ NEW - Through Firebase backend
final account = await monnifyService.createVirtualAccount(
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  phone: '+2348012345678',
  bvn: '12345678901',
);
```

## Step-by-Step Migration

### Step 1: Update pubspec.yaml

Add the `cloud_functions` package:

```yaml
dependencies:
  cloud_functions: ^4.5.0  # Add this line
```

Remove or keep `dio` (may be used elsewhere in app):
```yaml
dependencies:
  dio: ^5.3.0  # Keep if used elsewhere
```

Run `flutter pub get`:
```bash
flutter pub get
```

### Step 2: Initialize Service in main.dart

**Before:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VtuApp());
}
```

**After:**
```dart
import 'package:vtu_app/services/monnify_firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ✅ Initialize Monnify Firebase Service
  MonnifyFirebaseService().init(
    region: 'us-central1', // Match your Firebase region
  );
  
  runApp(const VtuApp());
}
```

### Step 3: Update Screen/Widget Imports

**Before:**
```dart
import '../../services/monnify_service.dart';

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final MonnifyService _monnifyService = MonnifyService();
  // ...
}
```

**After:**
```dart
import '../../services/monnify_firebase_service.dart';

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final MonnifyFirebaseService _monnifyService = MonnifyFirebaseService();
  // ...
}
```

### Step 4: Update Account Creation Logic

**Before:**
```dart
Future<void> _createVirtualAccount(AuthProvider authProvider) async {
  try {
    final accountDetails = await _monnifyService.createVirtualAccount(
      userId: authProvider.userId!,  // ❌ No longer needed
      firstName: user['full_name']?.split(' ').first ?? 'User',
      lastName: user['full_name']?.split(' ').last ?? 'Account',
      email: user['email'] ?? 'user@example.com',
      phone: user['phone'] ?? '',
      bvn: _bvnController.text.isNotEmpty ? _bvnController.text : null,
      nin: _ninController.text.isNotEmpty ? _ninController.text : null,
    );

    if (accountDetails != null) {
      // Handle account created
    }
  } catch (e) {
    // Error handling
  }
}
```

**After:**
```dart
Future<void> _createVirtualAccount(AuthProvider authProvider) async {
  setState(() {
    _isCreatingAccount = true;
    _accountCreationError = null;
  });

  try {
    final user = authProvider.user;
    if (user == null) {
      throw Exception('User information not available');
    }

    // ✅ Firebase handles authentication automatically
    final accountDetails = await _monnifyService.createVirtualAccount(
      firstName: user['full_name']?.split(' ').first ?? 'User',
      lastName: user['full_name']?.split(' ').last ?? 'Account',
      email: user['email'] ?? 'user@example.com',
      phone: user['phone'] ?? '',
      bvn: _bvnController.text.isNotEmpty ? _bvnController.text : null,
      nin: _ninController.text.isNotEmpty ? _ninController.text : null,
    );

    setState(() {
      _virtualAccount = accountDetails;
      _isCreatingAccount = false;
      _showKycForm = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Virtual account created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    setState(() {
      _accountCreationError = e.toString();
      _isCreatingAccount = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Step 5: Delete Old Monnify Service

You can now delete or deprecate the old service:
```bash
# Option 1: Delete the file
rm lib/services/monnify_service.dart

# Option 2: Keep but mark as deprecated (for reference)
```

### Step 6: Verify Network Imports No Longer Needed

Remove these imports from screens that previously called Monnify directly:
```dart
// ❌ Remove these
import 'package:dio/dio.dart';
import 'dart:convert';
```

## Error Handling Comparison

### Before
```dart
try {
  final response = await _dio.post(...);
  if (response.statusCode == 200) {
    // Handle success
  }
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionError) {
    // CORS error here
  }
}
```

### After
```dart
try {
  final account = await monnifyService.createVirtualAccount(...);
  // Success - account created
} on FirebaseFunctionsException catch (e) {
  // Automatic user-friendly error messages
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(e.message)),
  );
} catch (e) {
  // General error handling
  print('Error: $e');
}
```

## Firebase Functions Deployment

After updating Flutter code, deploy the backend:

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy to Firebase
firebase deploy --only functions

# View logs
firebase functions:log
```

## Testing Checklist

- [ ] App builds without errors (`flutter pub get`)
- [ ] Firebase Cloud Functions deployed (`firebase deploy --only functions`)
- [ ] Test on Flutter Web (no CORS errors)
- [ ] Test on Android (verify it still works)
- [ ] Test on iOS (verify it still works)
- [ ] Test account creation with BVN
- [ ] Test account creation with NIN
- [ ] Test error handling (invalid BVN/NIN)
- [ ] Test unauthenticated user error
- [ ] Verify Firestore has account data
- [ ] Check Firebase functions logs for errors

## Troubleshooting

### Error: "Function not found"
```
FirebaseFunctionsException: Function not found
```

**Solution:**
1. Verify Firebase functions are deployed: `firebase deploy --only functions`
2. Check function name matches exactly: `createVirtualAccount`
3. Verify you're calling the right region

### Error: "User is not authenticated"
```
FirebaseFunctionsException: User must be authenticated to create virtual account
```

**Solution:**
1. Ensure user is logged in before calling
2. Check Firebase authentication is working
3. Verify user token is valid

### Error: "CORS error" still appearing
```
XMLHttpRequest error: The connection errored
```

**Solution:**
1. Verify you're using Firebase functions, not direct API
2. Check imports: `import 'monnify_firebase_service.dart'`
3. Not using `Dio` to call Monnify directly

### Error: "Monnify authentication failed"
```
FirebaseFunctionsException: Monnify authentication failed
```

**Solution:**
1. Verify credentials in Firebase config: `firebase functions:config:get`
2. Check Monnify credentials are correct
3. Verify contract code is valid

## Rollback Plan

If you need to rollback to direct API calls:

1. Keep backup of `monnify_service.dart`
2. Restore old imports in screens
3. Keep CORS workaround or proxy configuration
4. Re-enable direct Dio calls

But **NOT recommended** - Firebase functions approach is better for web!

## Performance Considerations

### Benefits
- ✅ No CORS delays
- ✅ Backend caching possible
- ✅ Better error handling
- ✅ Automatic retries
- ✅ Load balancing

### Metrics to Monitor
- Firebase function execution time
- Monnify API response time
- Number of timeouts
- Error rates

### Optimization Tips
```javascript
// In functions/index.js
exports.createVirtualAccount = functions
  .runWith({
    memory: '512MB',           // Increase if needed
    timeoutSeconds: 60,         // Max 540 for gen 2
    maxInstances: 100,          // Limit concurrent executions
  })
  .https.onCall(async (data, context) => {
    // ...
  });
```

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Architecture** | Direct API | Firebase → API |
| **CORS Issues** | ❌ Yes (Web) | ✅ No |
| **Security** | ❌ Keys exposed | ✅ Backend only |
| **Error Handling** | Manual | ✅ Automatic |
| **Retries** | Manual | ✅ Built-in |
| **Logging** | Manual | ✅ Firebase Logs |
| **Scalability** | Limited | ✅ Auto-scaling |
| **Maintenance** | Complex | ✅ Simplified |

## Next Steps

1. ✅ Deploy Firebase functions
2. ✅ Update Flutter app
3. ✅ Test thoroughly
4. ✅ Monitor logs
5. ✅ Gather user feedback
6. ✅ Optimize if needed

Great! You've successfully migrated to a scalable, secure backend architecture! 🎉
