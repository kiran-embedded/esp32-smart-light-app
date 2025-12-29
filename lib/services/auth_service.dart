import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/persistence_service.dart';

class AuthService {
  GoogleSignIn? _googleSignIn;

  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase not initialized. Please configure your project.',
      );
    }
    return FirebaseAuth.instance;
  }

  User? get currentUser {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser;
  }

  Stream<User?> get authStateChanges {
    if (Firebase.apps.isEmpty) return Stream.value(null);
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<GoogleSignIn> _getGoogleSignIn() async {
    if (_googleSignIn != null) return _googleSignIn!;

    final clientId = await PersistenceService.getGoogleWebClientId();
    _googleSignIn = GoogleSignIn(serverClientId: clientId);
    return _googleSignIn!;
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = await _getGoogleSignIn();
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get authentication tokens from Google');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user == null) {
        throw Exception('Firebase sign-in returned null user');
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      String errorMessage = 'Firebase error: ';
      switch (e.code) {
        case 'network-request-failed':
          errorMessage += 'Network error. Check your internet connection.';
          break;
        case 'invalid-credential':
          errorMessage += 'Invalid credentials. Please try again.';
          break;
        case 'account-exists-with-different-credential':
          errorMessage += 'An account already exists with this email.';
          break;
        case 'operation-not-allowed':
          errorMessage += 'Google Sign-In is not enabled in Firebase Console.';
          break;
        default:
          errorMessage += '${e.code}: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Handle other errors
      final errorString = e.toString();
      if (errorString.contains('PlatformException')) {
        if (errorString.contains('SIGN_IN_CANCELLED')) {
          return null; // User canceled
        } else if (errorString.contains('SIGN_IN_FAILED')) {
          throw Exception(
            'Google Sign-In failed. Check SHA-1 fingerprint in Firebase Console.',
          );
        } else if (errorString.contains('DEVELOPER_ERROR')) {
          throw Exception(
            'Developer error. Check google-services.json and SHA-1 fingerprint.',
          );
        }
      }
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    final googleSignIn = await _getGoogleSignIn();
    try {
      await googleSignIn.disconnect();
    } catch (e) {
      debugPrint("Google disconnect failed (likely already disconnected): $e");
    }
    await googleSignIn.signOut();
    await _auth.signOut();
    _googleSignIn = null; // Force fresh instance next time
  }
}
