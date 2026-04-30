// server.js - Express.js wrapper for Render/Railway deployment
// This wraps the Firebase Cloud Functions as HTTP endpoints

const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

// Middleware
app.use(express.json());
app.use(cors({
  origin: '*', // Allow all origins (or restrict to your app domain)
  credentials: true
}));

// ============================================================================
// MONNIFY CONFIGURATION
// ============================================================================
const axios = require('axios');

const MONNIFY_AUTH_URL = "https://sandbox.monnify.com/api/v1/auth/login";
const MONNIFY_RESERVED_ACCOUNT_URL = "https://sandbox.monnify.com/api/v2/bank-transfer/reserved-accounts";
const MONNIFY_API_KEY = process.env.MONNIFY_API_KEY || "MK_TEST_GC3B8XG2XX";
const MONNIFY_API_SECRET = process.env.MONNIFY_API_SECRET || "A663NRZA544DDPEM7KDN7Z8HRV6YXD8S";
const MONNIFY_CONTRACT_CODE = process.env.MONNIFY_CONTRACT_CODE || "5867418298";

// ============================================================================
// HELPER: Convert to JSON-safe values (fix Int64 issue)
// ============================================================================
function toJSONSafe(obj) {
  if (obj === null || obj === undefined) return obj;
  
  if (obj.toDate && typeof obj.toDate === 'function') {
    return obj.toDate().toISOString();
  }
  
  if (obj.latitude !== undefined && obj.longitude !== undefined) {
    return { latitude: obj.latitude, longitude: obj.longitude };
  }
  
  if (Array.isArray(obj)) {
    return obj.map(item => toJSONSafe(item));
  }
  
  if (typeof obj === 'object') {
    const result = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        const value = obj[key];
        if (typeof value !== 'function' && value !== undefined) {
          result[key] = toJSONSafe(value);
        }
      }
    }
    return result;
  }
  
  return obj;
}

// ============================================================================
// HELPER: Get Monnify Access Token
// ============================================================================
async function getMonnifyAccessToken() {
  try {
    const credentials = Buffer.from(
      `${MONNIFY_API_KEY}:${MONNIFY_API_SECRET}`
    ).toString("base64");

    const response = await axios.post(
      MONNIFY_AUTH_URL,
      {},
      {
        headers: {
          Authorization: `Basic ${credentials}`,
          "Content-Type": "application/json",
        },
        timeout: 10000,
      }
    );

    if (response.data?.responseBody?.accessToken) {
      console.log("✅ Monnify access token obtained successfully");
      return response.data.responseBody.accessToken;
    } else {
      throw new Error("No access token in response");
    }
  } catch (error) {
    console.error("❌ Failed to get Monnify access token:", error.message);
    throw new Error(`Monnify authentication failed: ${error.message}`);
  }
}

// ============================================================================
// ENDPOINT: Create Virtual Account
// ============================================================================
app.post('/api/createVirtualAccount', async (req, res) => {
  try {
    const { firstName, lastName, email, phone, bvn, nin, userId } = req.body;

    // Validate required fields
    if (!firstName || !lastName || !email || !phone) {
      return res.status(400).json({
        success: false,
        error: "Missing required fields: firstName, lastName, email, phone"
      });
    }

    // Validate that at least BVN or NIN is provided (CBN KYC requirement)
    if ((!bvn || bvn.trim() === "") && (!nin || nin.trim() === "")) {
      return res.status(400).json({
        success: false,
        error: "Either BVN or NIN is required for account creation (CBN KYC regulation)"
      });
    }

    // Basic format validation for BVN/NIN (should be 11 digits)
    if (bvn && bvn.trim() && !/^\d{11}$/.test(bvn.trim())) {
      return res.status(400).json({
        success: false,
        error: "BVN must be 11 digits"
      });
    }
    if (nin && nin.trim() && !/^\d{11}$/.test(nin.trim())) {
      return res.status(400).json({
        success: false,
        error: "NIN must be 11 digits"
      });
    }

    console.log(`📝 Input validated - Creating account for: ${firstName} ${lastName}`);

    // Get Monnify access token
    let accessToken;
    try {
      accessToken = await getMonnifyAccessToken();
    } catch (error) {
      console.error("❌ Failed to authenticate with Monnify:", error);
      return res.status(500).json({
        success: false,
        error: `Failed to authenticate with Monnify: ${error.message}`
      });
    }

    // Prepare account request data
    const accountRequestData = {
      contractCode: MONNIFY_CONTRACT_CODE,
      accountReference: userId || new Date().getTime().toString(),
      accountName: `${firstName} ${lastName}`,
      currencyCode: "NGN",
      customerEmail: email,
      customerName: `${firstName} ${lastName}`,
      incomeSplitConfig: [],
      allocationRules: [],
    };

    // Add KYC credentials if provided
    if (bvn && bvn.trim()) {
      accountRequestData.bvn = bvn.trim();
      console.log(`📝 BVN provided`);
    }
    if (nin && nin.trim()) {
      accountRequestData.nin = nin.trim();
      console.log(`📝 NIN provided`);
    }

    // Create reserved account with Monnify
    console.log("🔵 Calling Monnify API to create reserved account...");

    const response = await axios.post(
      MONNIFY_RESERVED_ACCOUNT_URL,
      accountRequestData,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        timeout: 15000,
      }
    );

    if (response.status === 200 || response.status === 201) {
      const accountDetails = response.data;
      console.log(`✅ Virtual account created successfully: ${accountDetails.responseBody?.accountNumber}`);

      const accountBody = accountDetails.responseBody || accountDetails;
      return res.status(200).json(toJSONSafe({
        success: true,
        message: "Virtual account created successfully",
        account: {
          accountNumber: accountBody.accountNumber,
          accountName: accountBody.accountName,
          bankName: accountBody.bankName,
          bankCode: accountBody.bankCode,
          accountReference: accountBody.accountReference,
          createdAt: new Date().toISOString(),
        },
      }));
    } else {
      throw new Error(`Unexpected status code: ${response.status}`);
    }

  } catch (error) {
    console.error("❌ Error creating virtual account:", error.message);
    
    // Extract error details from Monnify response
    if (error.response?.data?.responseBody?.errors) {
      const monnifyError = error.response.data.responseBody.errors[0];
      return res.status(500).json({
        success: false,
        error: `Monnify error: ${monnifyError.message || monnifyError}`
      });
    }

    return res.status(500).json({
      success: false,
      error: `Failed to create virtual account: ${error.message}`
    });
  }
});

// ============================================================================
// ENDPOINT: Get Virtual Account Details
// ============================================================================
app.get('/api/getVirtualAccount', async (req, res) => {
  try {
    const { accountReference } = req.query;

    if (!accountReference) {
      return res.status(400).json({
        success: false,
        error: "accountReference is required"
      });
    }

    console.log(`🔄 Fetching virtual account details for: ${accountReference}`);

    // Get access token
    let accessToken;
    try {
      accessToken = await getMonnifyAccessToken();
    } catch (error) {
      return res.status(500).json({
        success: false,
        error: `Failed to authenticate with Monnify: ${error.message}`
      });
    }

    // Call Monnify API
    const response = await axios.get(
      `${MONNIFY_RESERVED_ACCOUNT_URL}/${accountReference}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
        timeout: 15000,
      }
    );

    if (response.status === 200) {
      console.log(`✅ Retrieved virtual account details`);
      const accountBody = response.data.responseBody || response.data;
      
      return res.status(200).json(toJSONSafe({
        success: true,
        account: {
          accountNumber: accountBody.accountNumber,
          accountName: accountBody.accountName,
          bankName: accountBody.bankName,
        },
      }));
    }

  } catch (error) {
    console.error("❌ Error retrieving account:", error.message);
    return res.status(500).json({
      success: false,
      error: `Failed to retrieve account details: ${error.message}`
    });
  }
});

// ============================================================================
// ENDPOINT: Verify Transaction
// ============================================================================
app.post('/api/verifyTransaction', async (req, res) => {
  try {
    const { transactionReference } = req.body;

    if (!transactionReference) {
      return res.status(400).json({
        success: false,
        error: "transactionReference is required"
      });
    }

    console.log(`🔄 Verifying transaction: ${transactionReference}`);

    // Get access token
    let accessToken;
    try {
      accessToken = await getMonnifyAccessToken();
    } catch (error) {
      return res.status(500).json({
        success: false,
        error: `Failed to authenticate with Monnify: ${error.message}`
      });
    }

    // Call Monnify API
    const response = await axios.get(
      `https://sandbox.monnify.com/api/v2/transactions/${transactionReference}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
        timeout: 15000,
      }
    );

    if (response.status === 200) {
      console.log(`✅ Transaction verified: ${transactionReference}`);
      
      return res.status(200).json(toJSONSafe({
        success: true,
        transaction: response.data.responseBody || response.data,
      }));
    }

  } catch (error) {
    console.error("❌ Error verifying transaction:", error.message);
    return res.status(500).json({
      success: false,
      error: `Failed to verify transaction: ${error.message}`
    });
  }
});

// ============================================================================
// HEALTH CHECK ENDPOINT
// ============================================================================
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Backend server is running' });
});

// ============================================================================
// START SERVER
// ============================================================================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
  console.log(`🌐 API available at http://localhost:${PORT}`);
});

module.exports = app;
