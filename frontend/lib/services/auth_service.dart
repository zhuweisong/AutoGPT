import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:html' as html;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // This stream controller will be used to publish the incoming OAuth codes.
  final StreamController<String> _oauthCodeController = StreamController();

  String? _expectedState;

  AuthService() {
    // This function will be invoked whenever a new link is opened with the app.
    linkStream.listen((String? link) {
      // Check if the link is not null before proceeding
      if (link != null) {
        // Extract the OAuth code from the link and add it to the stream.
        final Uri url = Uri.parse(link);
        final String? code = url.queryParameters['code'];
        if (code != null) {
          _oauthCodeController.add(code);
        }
      }
    }, onError: (err) {
      // Handle the error here
      print(err);
    });
  }

  String getRedirectUri() {
    // Get the current URL
    String currentUrl = html.window.location.href;

    print(currentUrl);
    return currentUrl;
  }

  // Function to launch the URL
  Future<void> _launchURL(String urlString) async {
    var url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String _generateState() {
    // Generate a random state string using a secure random number generator
    var random = Random.secure();
    var values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Future<String?> _handleOAuthRedirect() async {
    // Wait for the OAuth code to be published to the stream.
    final code = await _oauthCodeController.stream.first;
    final Uri url =
        Uri.parse(code); // Assuming the entire URL is being sent to the stream
    final receivedState = url.queryParameters['state'];

    if (receivedState != _expectedState) {
      throw Exception('Invalid OAuth state, possible CSRF detected');
    }

    return url.queryParameters['code']; // Return the auth code
  }

  String generateGoogleOAuthUrl(String redirectUri) {
    const String clientId =
        '387936576242-iejdacrjljds7hf99q0p6eqna8rju3sb.apps.googleusercontent.com';
    const String scope = 'email profile openid';
    const String responseType = 'code';
    _expectedState = _generateState();

    return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': responseType,
      'scope': scope,
      'state': _expectedState,
    }).toString();
  }

  String generateGithubOAuthUrl(String redirectUri, String clientId) {
    _expectedState = _generateState();

    return Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'scope': 'user',
      'state': _expectedState,
    }).toString();
  }

  // Sign in with Google using redirect
  Future<UserCredential?> signInWithGoogle() async {
    try {
      String redirectUri = getRedirectUri();
      String googleOAuthUrl = generateGoogleOAuthUrl(redirectUri);
      await _launchURL(googleOAuthUrl);
      final String? authCode = await _handleOAuthRedirect();
      if (authCode != null) {
        // TODO: Exchange the authorization code for an access token
        // and sign in the user with Firebase.
      }
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  // Sign in with GitHub using redirect
  Future<UserCredential?> signInWithGitHub() async {
    try {
      String redirectUri = getRedirectUri();
      String clientId = '445ad0e9d96f9ea59545';
      String githubOAuthUrl = generateGithubOAuthUrl(redirectUri, clientId);
      await _launchURL(githubOAuthUrl);
      final String? authCode = await _handleOAuthRedirect();
      if (authCode != null) {
        // TODO: Exchange the authorization code for an access token
        // and sign in the user with Firebase.
      }
    } catch (e) {
      print("Error during GitHub Sign-In: $e");
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  void dispose() {
    _oauthCodeController.close();
  }
}
