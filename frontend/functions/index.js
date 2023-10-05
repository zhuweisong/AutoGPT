// Import the required modules
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

// Initialize the Firebase admin SDK
admin.initializeApp();

// Define the Firebase Cloud Function
exports.exchangeCodeForAccessToken = functions.https.onCall(
    async (data, context) => {
      // Extract the authorization code, redirect URI, provider
      const {code, redirectUri, provider} = data;

      // Validate the request data
      if (!code || !redirectUri || !provider) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The function must be called with valid arguments.",
        );
      }

      let tokenEndpoint;
      let clientCredentials;
      let params;

      // Handle the OAuth for Google
      if (provider === "google") {
        tokenEndpoint = "https://oauth2.googleapis.com/token";
        clientCredentials = {
          client_id: functions.config().google.client_id,
          client_secret: functions.config().google.client_secret,
        };
        params = {
          code,
          client_id: clientCredentials.client_id,
          client_secret: clientCredentials.client_secret,
          redirect_uri: redirectUri,
          grant_type: "authorization_code",
        };
      } else if (provider === "github") {
        tokenEndpoint = "https://github.com/login/oauth/access_token";
        clientCredentials = {
          client_id: functions.config().github.client_id,
          client_secret: functions.config().github.client_secret,
        };
        params = {
          client_id: clientCredentials.client_id,
          client_secret: clientCredentials.client_secret,
          code,
          redirect_uri: redirectUri,
        };
      } else {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "The provider is not supported.",
        );
      }

      try {
        const response = await axios.post(tokenEndpoint, null, {params});
        const {access_token: accessToken, id_token: idToken} = response.data;

        let firebaseToken;

        if (provider === "google") {
          const googleUser = await admin.auth().verifyIdToken(idToken);
          const custTok = await admin.auth().createCustomToken(googleUser.uid);
          firebaseToken = custTok;
        } else if (provider === "github") {
          const githubUser = await axios.get("https://api.github.com/user", {
            headers: {Authorization: `token ${accessToken}`},
          });
          const custTok = await admin.auth().createCustomToken(
              githubUser.data.id.toString(),
          );
          firebaseToken = custTok;
        }

        return {firebaseToken};
      } catch (error) {
        console.error("Error during token exchange", error);
        throw new functions.https.HttpsError(
            "internal",
            "Failed to exchange authorization code for access token",
        );
      }
    },
);
