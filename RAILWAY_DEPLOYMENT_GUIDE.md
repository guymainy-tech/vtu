# 🚀 Deploy to Railway (Free Alternative)

## Quick Start - Deploy in 3 minutes

### Step 1: Create Railway Account
1. Visit https://railway.app
2. Sign up with GitHub (recommended)
3. Click **New Project**

### Step 2: Deploy from GitHub
1. Select **Deploy from GitHub repo**
2. Connect your GitHub account
3. Select your VTU app repository
4. Click **Deploy**

### Step 3: Configure Root Directory
1. Go to **Settings**
2. Set **Root Directory** to: `functions`

### Step 4: Set Start Command
1. Go to **Variables**
2. Add environment variables:
   ```
   MONNIFY_API_KEY=MK_TEST_GC3B8XG2XX
   MONNIFY_API_SECRET=A663NRZA544DDPEM7KDN7Z8HRV6YXD8S
   MONNIFY_CONTRACT_CODE=5867418298
   PORT=3000
   NODE_ENV=production
   ```
3. Railway automatically detects `package.json` and runs `npm start`

### Step 5: Get Your URL
1. Click on your project
2. Go to **Deployments**
3. Wait for "Live" status
4. Copy the deployment URL (e.g., `https://vtu-app-production.railway.app`)

---

## Test Deployment

### Health Check
```bash
curl https://vtu-app-production.railway.app/health
```

Expected response:
```json
{"status":"ok","message":"Backend server is running"}
```

### Test Create Virtual Account
```bash
curl -X POST https://vtu-app-production.railway.app/api/createVirtualAccount \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+2348012345678",
    "bvn": "12345678901",
    "userId": "test-user-123"
  }'
```

---

## Update Flutter App

Create new service file: `lib/services/monnify_http_service.dart`

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class MonnifyHttpService {
  static final MonnifyHttpService _instance = MonnifyHttpService._internal();
  
  factory MonnifyHttpService() => _instance;
  MonnifyHttpService._internal();

  final String _backendUrl = 'https://vtu-app-production.railway.app';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create Virtual Account
  Future<Map<String, dynamic>> createVirtualAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? bvn,
    String? nin,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      AppLogger.log('🔄 Creating virtual account via HTTP backend...');

      final response = await http.post(
        Uri.parse('$_backendUrl/api/createVirtualAccount'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          if (bvn != null && bvn.isNotEmpty) 'bvn': bvn,
          if (nin != null && nin.isNotEmpty) 'nin': nin,
          'userId': user.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          AppLogger.log('✅ Virtual account created successfully');
          return data['account'];
        } else {
          throw Exception(data['error'] ?? 'Failed to create account');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Error: $e');
      throw Exception('Failed to create virtual account: $e');
    }
  }

  /// Get Virtual Account Details
  Future<Map<String, dynamic>> getVirtualAccount(String accountReference) async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/api/getVirtualAccount?accountReference=$accountReference'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['account'];
        } else {
          throw Exception(data['error'] ?? 'Failed to get account');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Error: $e');
      throw Exception('Failed to get virtual account: $e');
    }
  }

  /// Verify Transaction
  Future<Map<String, dynamic>> verifyTransaction(String transactionReference) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/verifyTransaction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transactionReference': transactionReference}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['transaction'];
        } else {
          throw Exception(data['error'] ?? 'Failed to verify transaction');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Error: $e');
      throw Exception('Failed to verify transaction: $e');
    }
  }
}
```

---

## Monitoring

### View Logs
1. Go to your Railway project
2. Click **Logs**
3. Real-time log streaming

### Environment Variables
1. Go to **Variables**
2. Click **RAW Editor** to see all at once
3. Update as needed

---

## Free Tier Limits

**Railway Free Tier:**
- ✅ $5/month free credit
- ✅ Sufficient for development
- ✅ No card required initially
- ✅ Pay-as-you-go after free credit

**Typical VTU App Usage:**
- ~$2-3/month for moderate usage
- Includes 500GB bandwidth

---

## Troubleshooting

### 502 Bad Gateway
1. Check Logs in Railway
2. Verify `npm start` works: `node server.js`
3. Check environment variables are set

### Cannot Connect
1. Verify backend URL is correct
2. Check network connectivity
3. CORS should be enabled (configured in server.js)

### Deployment Fails
1. Check build logs
2. Ensure package.json is valid
3. Verify Node.js version compatibility (18+)

---

## Switch Between Backends

**Keep both working for easy switching:**

```dart
// In your Flutter service
const String BACKEND_URL = String.fromEnvironment('BACKEND_URL',
  defaultValue: 'https://vtu-app-production.railway.app');
```

---

## Next Steps

1. **Deploy to Railway**
2. **Test all endpoints**
3. **Update Flutter service**
4. **Monitor logs**
5. **Deploy Flutter app**

---

**Status: Ready to deploy! 🎉**
