# 🚀 Deploy to Render (Free)

## Quick Start - Deploy in 5 minutes

### Step 1: Prepare Your Code
```bash
cd functions
npm install
```

### Step 2: Create Render Account
1. Visit https://render.com
2. Sign up (free account)
3. Click "New +"

### Step 3: Create Web Service
1. Select **Web Service**
2. Choose **Deploy from Git**
3. Connect your GitHub repository (or use public repo)
4. Fill in the following:
   - **Name:** `vtu-app-backend`
   - **Environment:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Instance Type:** `Free`

### Step 4: Configure Environment Variables
In Render dashboard, go to **Environment**:
```
MONNIFY_API_KEY=MK_TEST_GC3B8XG2XX
MONNIFY_API_SECRET=A663NRZA544DDPEM7KDN7Z8HRV6YXD8S
MONNIFY_CONTRACT_CODE=5867418298
PORT=3000
NODE_ENV=production
```

### Step 5: Deploy
1. Click **Create Web Service**
2. Render will automatically deploy
3. Wait for "Live" status (2-3 minutes)
4. Copy your URL (e.g., `https://vtu-app-backend.onrender.com`)

---

## Test Deployment

### Health Check
```bash
curl https://vtu-app-backend.onrender.com/health
```

Expected response:
```json
{"status":"ok","message":"Backend server is running"}
```

### Test Create Virtual Account
```bash
curl -X POST https://vtu-app-backend.onrender.com/api/createVirtualAccount \
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

Open `lib/services/monnify_firebase_service.dart` and change:

```dart
// OLD: Uses Firebase Cloud Functions
final callable = functions.httpsCallable('createVirtualAccount');

// NEW: Use HTTP to your Render backend
final response = await http.post(
  Uri.parse('https://vtu-app-backend.onrender.com/api/createVirtualAccount'),
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
```

---

## Monitoring

### View Logs
- Click **Logs** in Render dashboard
- Real-time log streaming

### Set Alerts
- Render free tier includes basic monitoring
- Go to Settings → Notifications

---

## Limits

**Free Tier:**
- ✅ 750 hours/month (always-on)
- ✅ 100GB bandwidth/month
- ✅ 5GB storage
- ✅ Auto-spin down after 15 min inactivity (restarts on first request)

**Paid Tier (if needed):**
- $7/month for always-on
- No spin-down
- Priority support

---

## Troubleshooting

### 500 Error
1. Check Logs in Render dashboard
2. Verify environment variables are set
3. Check Monnify credentials are correct

### Timeout
- Free tier may spin down after 15 min
- First request after spin-down takes 10-30 seconds
- Consider paid tier for production

### Deployment Failed
1. Check build logs
2. Verify `npm start` works locally: `npm start`
3. Check for syntax errors: `node server.js`

---

## Next Steps

1. **Test all endpoints** from your Flutter app
2. **Monitor logs** for errors
3. **Add error handling** in Flutter app
4. **Consider paid tier** for production (continuous running)

---

**Status: Ready to deploy! 🎉**
