const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

// Initialize Firebase Admin SDK
admin.initializeApp();

// ============================================================================
// HELPER: Convert Firestore types to JSON-safe values (fix Int64 issue)
// ============================================================================
/**
 * Converts Firestore and other non-JSON-serializable types to JSON-safe values
 * Fixes "Int64 accessor not supported by dart2js" error
 * @param {any} obj Object to convert
 * @returns {any} JSON-safe object
 */
function toJSONSafe(obj) {
  if (obj === null || obj === undefined) return obj;
  
  // Handle Firestore Timestamp
  if (obj.toDate && typeof obj.toDate === 'function') {
    return obj.toDate().toISOString();
  }
  
  // Handle Firestore GeoPoint
  if (obj.latitude !== undefined && obj.longitude !== undefined) {
    return { latitude: obj.latitude, longitude: obj.longitude };
  }
  
  // Handle arrays
  if (Array.isArray(obj)) {
    return obj.map(item => toJSONSafe(item));
  }
  
  // Handle objects
  if (typeof obj === 'object') {
    const result = {};
    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        const value = obj[key];
        // Skip functions and undefined values
        if (typeof value !== 'function' && value !== undefined) {
          result[key] = toJSONSafe(value);
        }
      }
    }
    return result;
  }
  
  // Return primitive types as-is
  return obj;
}

// ============================================================================
// MONNIFY CONFIGURATION
// ============================================================================
// These should be stored in Firebase Environment Config (firebase functions:config:set)
// Example: firebase functions:config:set monnify.api_key="..." monnify.api_secret="..."
// These are test credentials - update in Firebase config for production

const MONNIFY_AUTH_URL = "https://sandbox.monnify.com/api/v1/auth/login";
const MONNIFY_RESERVED_ACCOUNT_URL =
  "https://sandbox.monnify.com/api/v2/bank-transfer/reserved-accounts";
const MONNIFY_API_KEY = process.env.MONNIFY_API_KEY || "MK_TEST_GC3B8XG2XX";
const MONNIFY_API_SECRET =
  process.env.MONNIFY_API_SECRET || "A663NRZA544DDPEM7KDN7Z8HRV6YXD8S";
const MONNIFY_CONTRACT_CODE =
  process.env.MONNIFY_CONTRACT_CODE || "5867418298";

// ============================================================================
// HELPER: Get Monnify Access Token
// ============================================================================
/**
 * Authenticates with Monnify API to get an access token for subsequent requests
 * @returns {Promise<string>} Access token
 * @throws {Error} If authentication fails
 */
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
    throw new functions.https.HttpsError(
      "internal",
      `Monnify authentication failed: ${error.message}`
    );
  }
}

// ============================================================================
// CALLABLE FUNCTION: Create Virtual Account
// ============================================================================
/**
 * Creates a virtual account with Monnify for a user
 * Requires authenticated user (Firebase Auth)
 *
 * @param {Object} data Request data
 * @param {string} data.firstName User's first name
 * @param {string} data.lastName User's last name
 * @param {string} data.email User's email address
 * @param {string} data.phone User's phone number
 * @param {string} [data.bvn] Bank Verification Number (BVN) - optional
 * @param {string} [data.nin] National ID Number (NIN) - optional
 * @param {Object} context Firebase Cloud Functions context
 * @returns {Promise<Object>} Virtual account details
 *
 * @example
 * const result = await firebase.functions().httpsCallable('createVirtualAccount')({
 *   firstName: 'John',
 *   lastName: 'Doe',
 *   email: 'john@example.com',
 *   phone: '+2348012345678',
 *   bvn: '12345678901'
 * });
 */
exports.createVirtualAccount = functions.https.onCall(
  async (data, context) => {
    // ========================================================================
    // STEP 1: VALIDATE AUTHENTICATION
    // ========================================================================
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to create a virtual account"
      );
    }

    const uid = context.auth.uid;
    console.log(`👤 Processing virtual account creation for user: ${uid}`);

    // ========================================================================
    // STEP 2: VALIDATE INPUT DATA
    // ========================================================================
    const { firstName, lastName, email, phone, bvn, nin } = data;

    // Validate required fields
    if (!firstName || !lastName || !email || !phone) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: firstName, lastName, email, phone"
      );
    }

    // Validate that at least BVN or NIN is provided (CBN KYC requirement)
    if ((!bvn || bvn.trim() === "") && (!nin || nin.trim() === "")) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Either BVN or NIN is required for account creation (CBN KYC regulation)"
      );
    }

    // Basic format validation for BVN/NIN (should be 11 digits)
    if (bvn && bvn.trim() && !/^\d{11}$/.test(bvn.trim())) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "BVN must be 11 digits"
      );
    }
    if (nin && nin.trim() && !/^\d{11}$/.test(nin.trim())) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "NIN must be 11 digits"
      );
    }

    console.log(
      `📝 Input validated - Creating account for: ${firstName} ${lastName}`
    );

    // ========================================================================
    // STEP 3: GET MONNIFY ACCESS TOKEN
    // ========================================================================
    let accessToken;
    try {
      accessToken = await getMonnifyAccessToken();
    } catch (error) {
      console.error("❌ Failed to authenticate with Monnify:", error);
      throw error;
    }

    // ========================================================================
    // STEP 4: PREPARE ACCOUNT REQUEST DATA
    // ========================================================================
    const accountRequestData = {
      contractCode: MONNIFY_CONTRACT_CODE,
      accountReference: uid, // Use Firebase UID as unique account reference
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
      console.log(`📝 BVN provided: ${bvn.substring(0, 2)}${"*".repeat(7)}${bvn.substring(9)}`);
    }
    if (nin && nin.trim()) {
      accountRequestData.nin = nin.trim();
      console.log(`📝 NIN provided: ${nin.substring(0, 2)}${"*".repeat(7)}${nin.substring(9)}`);
    }

    // ========================================================================
    // STEP 5: CREATE RESERVED ACCOUNT WITH MONNIFY
    // ========================================================================
    let accountDetails;
    try {
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

      // Check if request was successful
      if (response.status === 200 || response.status === 201) {
        accountDetails = response.data;
        console.log(
          `✅ Virtual account created successfully: ${accountDetails.responseBody?.accountNumber}`
        );
      } else {
        throw new Error(
          `Unexpected status code: ${response.status} - ${response.statusText}`
        );
      }
    } catch (error) {
      console.error("❌ Monnify API Error:", error.message);

      // Extract error details from Monnify response
      if (error.response?.data?.responseBody?.errors) {
        const monnifyError = error.response.data.responseBody.errors[0];
        throw new functions.https.HttpsError(
          "internal",
          `Monnify error: ${monnifyError.message || monnifyError}`
        );
      }

      throw new functions.https.HttpsError(
        "internal",
        `Failed to create virtual account: ${error.message}`
      );
    }

    // ========================================================================
    // STEP 6: SAVE ACCOUNT DETAILS TO FIRESTORE
    // ========================================================================
    try {
      const db = admin.firestore();
      const userRef = db.collection("users").doc(uid);

      const accountData = accountDetails.responseBody || accountDetails;

      await userRef.update({
        has_virtual_account: true,
        virtual_account_number: accountData.accountNumber,
        virtual_account_name: accountData.accountName,
        virtual_account_bank: accountData.bankName,
        virtual_account_created_at: admin.firestore.FieldValue.serverTimestamp(),
        bvn: bvn ? bvn.trim() : null,
        nin: nin ? nin.trim() : null,
      });

      console.log(
        `💾 Virtual account details saved to Firestore for user: ${uid}`
      );
    } catch (error) {
      console.error("⚠️ Warning: Failed to save account to Firestore:", error);
      // Don't throw - account was created successfully, just not persisted to Firestore
      // Client can still use the returned account details
    }

    // ========================================================================
    // STEP 7: RETURN ACCOUNT DETAILS TO CLIENT
    // ========================================================================
    const accountBody = accountDetails.responseBody || accountDetails;
    return toJSONSafe({
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
    });
  }
);

// ============================================================================
// CALLABLE FUNCTION: Get Virtual Account Details
// ============================================================================
/**
 * Retrieves virtual account details for a user
 * @param {Object} data Request data
 * @param {string} data.accountReference Account reference (Firebase UID)
 * @param {Object} context Firebase Cloud Functions context
 * @returns {Promise<Object>} Virtual account details
 */
exports.getVirtualAccount = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const uid = context.auth.uid;
    const { accountReference } = data;

    if (!accountReference) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "accountReference is required"
      );
    }

    // Ensure user can only access their own account
    if (accountReference !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You do not have permission to access this account"
      );
    }

    try {
      const accessToken = await getMonnifyAccessToken();

      const response = await axios.get(
        `${MONNIFY_RESERVED_ACCOUNT_URL}/${accountReference}?contractCode=${MONNIFY_CONTRACT_CODE}`,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        }
      );

      if (response.status === 200) {
        console.log(
          `✅ Retrieved virtual account details for user: ${uid}`
        );
        const accountBody = response.data.responseBody || response.data;
        return toJSONSafe({
          success: true,
          account: {
            accountNumber: accountBody.accountNumber,
            accountName: accountBody.accountName,
            bankName: accountBody.bankName,
          },
        });
      }
    } catch (error) {
      console.error("❌ Error retrieving account:", error.message);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to retrieve account details: ${error.message}`
      );
    }
  }
);

// ============================================================================
// CALLABLE FUNCTION: Verify Transaction
// ============================================================================
/**
 * Verifies a transaction with Monnify
 * @param {Object} data Request data
 * @param {string} data.transactionReference Transaction reference to verify
 * @param {Object} context Firebase Cloud Functions context
 * @returns {Promise<Object>} Transaction status
 */
exports.verifyTransaction = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { transactionReference } = data;

    if (!transactionReference) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "transactionReference is required"
      );
    }

    try {
      const accessToken = await getMonnifyAccessToken();

      const response = await axios.get(
        `https://api.monnify.com/api/v2/transactions/query?transactionReference=${transactionReference}`,
        {
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        }
      );

      if (response.status === 200) {
        console.log(
          `✅ Transaction verified: ${transactionReference}`
        );
        return toJSONSafe({
          success: true,
          transaction: response.data.responseBody || response.data,
        });
      }
    } catch (error) {
      console.error("❌ Error verifying transaction:", error.message);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to verify transaction: ${error.message}`
      );
    }
  }
);

console.log("🚀 Monnify Firebase Cloud Functions initialized");
