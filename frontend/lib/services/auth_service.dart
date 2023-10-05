import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamController<String> _oauthCodeController = StreamController();
  String? _expectedState;

  AuthService() {
    if (kIsWeb) {
      _handleWebOAuth();
    } else {
      linkStream.listen((String? link) {
        if (link != null) {
          final Uri url = Uri.parse(link);
          final String? code = url.queryParameters['code'];
          if (code != null) {
            _oauthCodeController.add(code);
          }
        }
      }, onError: (err) {
        print(err);
      });
    }
  }

  void _handleWebOAuth() {
    final currentUrl = html.window.location.href;
    final uri = Uri.parse(currentUrl);

    final String? code = uri.queryParameters['code'];
    final String? state = uri.queryParameters['state'];

    if (code != null && state != null) {
      _oauthCodeController.add(currentUrl);
    }
  }

  String getRedirectUri() {
    // Get the current URL
    String currentUrl = html.window.location.href;

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

  Future<String> _exchangeCodeForToken(
      String authCode, String redirectUri, String provider) async {
    const String functionUrl =
        'https://us-central1-prod-auto-gpt.cloudfunctions.net/exchangeCodeForAccessToken';

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        body: jsonEncode({
          'code': authCode,
          'redirectUri': redirectUri,
          'provider': provider,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['firebaseToken'] as String;
      } else {
        throw Exception('Failed to exchange auth code for token');
      }
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  // Sign in with Google using redirect
  Future<UserCredential?> signInWithGoogle() async {
    try {
      String redirectUri = getRedirectUri();
      String googleOAuthUrl = generateGoogleOAuthUrl(redirectUri);
      await _launchURL(googleOAuthUrl);
      final String? authCode = await _handleOAuthRedirect();
      if (authCode != null) {
        final String firebaseToken =
            await _exchangeCodeForToken(authCode, redirectUri, 'google');
        final UserCredential userCredential =
            await _auth.signInWithCustomToken(firebaseToken);
        return userCredential;
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
        final String firebaseToken =
            await _exchangeCodeForToken(authCode, redirectUri, 'github');
        final UserCredential userCredential =
            await _auth.signInWithCustomToken(firebaseToken);
        return userCredential;
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
