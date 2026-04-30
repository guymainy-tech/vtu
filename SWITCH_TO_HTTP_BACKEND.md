# 🔄 Switch from Firebase to HTTP Backend

## Overview

This guide explains how to update your Flutter app to use the HTTP backend service (Render/Railway) instead of Firebase Cloud Functions.

## Files to Update

### 1. Update pubspec.yaml

Add the `http` package if not already present:

```yaml
dependencies:
  # ... existing dependencies
  http: ^1.1.0
  # Remove or keep: cloud_functions: ^6.2.0 (not needed for HTTP service)
```

Run:
```bash
flutter pub get
```

### 2. Update lib/main.dart

Change the service initialization:

```dart
// OLD: Firebase Cloud Functions
import 'package:vtu_app/services/monnify_firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MonnifyFirebaseService().init();  // ❌ Remove this
  
  // ... rest of main
}

// NEW: HTTP Backend
import 'package:vtu_app/services/monnify_http_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize with your backend URL (from Render or Railway)
  MonnifyHttpService().init(
    backendUrl: 'https://vtu-app-backend.onrender.com'  // Change to your URL
  );
  
  // ... rest of main
}
```

### 3. Update wallet_topup_screen.dart

Replace the service reference:

```dart
// OLD
import 'package:vtu_app/services/monnify_firebase_service.dart';

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final MonnifyFirebaseService _monnifyService = MonnifyFirebaseService();

// NEW
import 'package:vtu_app/services/monnify_http_service.dart';

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final MonnifyHttpService _monnifyService = MonnifyHttpService();
```

### 4. Update All Other Screens (if using the service)

Find all usages of `MonnifyFirebaseService` and replace with `MonnifyHttpService`:

```bash
# Search in VS Code
Find: MonnifyFirebaseService
Replace: MonnifyHttpService

Find: monnify_firebase_service
Replace: monnify_http_service
```

## Code Changes Summary

### What Stays the Same ✅
- Method signatures
- Parameter names
- Return types
- Error handling approach
- User authentication requirement

### What Changes ❌
- Service class name: `MonnifyFirebaseService` → `MonnifyHttpService`
- Init parameter: now takes `backendUrl` instead of `region`
- Under the hood: uses HTTP requests instead of Firebase Cloud Functions

## Example: Complete Screen Update

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vtu_app/services/monnify_http_service.dart';  // Changed
import 'package:vtu_app/widgets/virtual_account_display.dart';
import 'package:vtu_app/providers/auth_provider.dart';
import 'package:vtu_app/utils/logger.dart';

class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({Key? key}) : super(key: key);

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  final MonnifyHttpService _monnifyService = MonnifyHttpService();  // Changed
  
  bool _showKycForm = false;
  bool _isCreatingAccount = false;
  Map<String, dynamic>? _virtualAccount;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  Future<void> _checkExistingAccount() async {
    // Same as before - no changes needed
  }

  Future<void> _createVirtualAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? bvn,
    String? nin,
  }) async {
    setState(() {
      _isCreatingAccount = true;
      _error = null;
    });

    try {
      AppLogger.log('🔄 Starting virtual account creation via HTTP backend...');

      // This is the same code - no changes needed!
      final accountDetails = await _monnifyService.createVirtualAccount(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        bvn: bvn,
        nin: nin,
      );

      setState(() {
        _virtualAccount = accountDetails;
        _showKycForm = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Virtual account created!')),
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isCreatingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet Top-up')),
      body: Center(
        child: (_isCreatingAccount ?? false)
            ? const VirtualAccountLoading()
            : _error != null
                ? VirtualAccountError(
                    error: _error!,
                    onRetry: _checkExistingAccount,
                  )
                : _virtualAccount != null
                    ? VirtualAccountDisplay(account: _virtualAccount!)
                    : const Text('No account'),
      ),
    );
  }
}
```

## Testing After Update

### 1. Test Health Check
```dart
final response = await http.get(
  Uri.parse('https://vtu-app-backend.onrender.com/health'),
);
print(response.body); // Should print: {"status":"ok","message":"Backend server is running"}
```

### 2. Test Create Account
Run your app and test the create account flow:
1. Log in to the app
2. Navigate to wallet
3. Fill in form with:
   - Name: Test Name
   - Email: test@example.com
   - Phone: +2348012345678
   - BVN: 12345678901
4. Click Create
5. Check console logs

### 3. Monitor Backend Logs
- **Render:** Dashboard → Logs
- **Railway:** Dashboard → Logs

## Common Issues

### 1. Connection Error
**Error:** `Failed to create virtual account: Connection refused`

**Solution:**
- Check backend URL is correct
- Ensure backend is running (check Render/Railway dashboard)
- For Render free tier, first request takes 30 seconds (auto-spin up)

### 2. 404 Error
**Error:** `Server error (404)`

**Solution:**
- Verify backend URL is correct
- Check `server.js` endpoints match the calls

### 3. CORS Error (Web only)
**This should NOT happen** since your backend handles CORS

If it does:
- Check server.js has `cors()` middleware
- Check CORS_ORIGINS environment variable

### 4. 500 Internal Server Error
**Error:** `Server error (500)`

**Solution:**
- Check backend logs (Render/Railway)
- Verify Monnify credentials are correct
- Ensure all environment variables are set

## Rollback to Firebase (if needed)

If you want to go back to Firebase Cloud Functions:

1. Revert imports: `MonnifyHttpService` → `MonnifyFirebaseService`
2. Upgrade Firebase to Blaze plan
3. Deploy Cloud Functions: `firebase deploy --only functions`
4. Revert initialization in main.dart

## Next Steps

1. ✅ Update all imports
2. ✅ Test create account
3. ✅ Monitor backend logs
4. ✅ Deploy to production
5. ✅ Keep both services as backup

---

**Status: Ready to switch! 🎉**
