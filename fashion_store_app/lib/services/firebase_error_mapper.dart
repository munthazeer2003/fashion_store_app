import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

String mapFirebaseError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  if (error is FirebaseException) {
    return error.message ?? 'Firebase operation failed. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}
