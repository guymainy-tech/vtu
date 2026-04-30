// NETWORK ERROR FIX - Setup Instructions

## Problem
The app was returning "Network error" because the API was trying to connect to `localhost:8000`, which doesn't exist on mobile devices.

## Solution

### 1. UPDATE BACKEND URL IN API SERVICE

Edit `lib/services/api_service.dart` and update the `_backendUrl`:

**For Production:**
```dart
static const String _backendUrl = 'https://your-production-api.com/api';
```

**For Development (Local Network):**
```dart
// Use your machine's local IP address (e.g., 192.168.1.100)
static const String _backendUrl = 'http://192.168.1.100:8000/api';
```

To find your local IP:
- **Windows**: Open Command Prompt and run `ipconfig`, look for IPv4 Address
- **Mac/Linux**: Run `ifconfig` in terminal

### 2. ENSURE BACKEND IS RUNNING

Make sure your backend server is:
- Running on the configured IP and port
- Accessible from your device (same network)
- Has proper CORS headers configured

### 3. CONNECTIVITY CHECKS

The app now includes automatic connectivity checks:
- Checks internet connection before API calls
- Provides specific error messages (timeout, no connection, etc.)
- Better error handling and logging

### 4. TEST THE CONNECTION

1. Make sure your device is on the same network as backend
2. Enable developer logs to see API requests/responses
3. Try registering or logging in
4. Check app logs for detailed error messages

## Files Modified
- `lib/services/api_service.dart` - Updated with connectivity checks
- `lib/services/connectivity_service.dart` - New service for network status
- `lib/screens/onboarding/register_screen.dart` - Better error handling

## Error Messages

Users will now see specific error messages:
- "No internet connection" - Device is offline
- "Connection timeout" - Backend took too long to respond
- "Server error" - Backend returned an error (500, 400, etc.)
- Specific validation errors from backend

