import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Auth (+ Google Sign-In) so the UI layer
/// never talks to the Firebase SDKs directly.
class AuthService {
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService._() {
    // Explicitly keep users signed in across browser restarts (not just
    // page refreshes/tabs). This is the default on web already, but it's
    // made explicit here so "stay logged in" behavior doesn't silently
    // depend on an SDK default. Native platforms always persist via the
    // OS keychain/shared prefs and don't expose this setting.
    //
    // Private/incognito browsing often restricts persistent storage
    // (IndexedDB) more aggressively than normal browsing, so this call can
    // fail there. It's not awaited (this is a constructor), so a failure
    // would otherwise become an unhandled Future rejection -- catch it and
    // fall back silently instead of leaving the app in a broken state.
    if (kIsWeb) {
      _auth.setPersistence(Persistence.LOCAL).catchError((_) {});
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Resolves a pending `signInWithRedirect` result (web only; a no-op
  /// with a null result on other platforms). Must be awaited before
  /// trusting [currentUser] on app start, since the redirect flow reloads
  /// the whole page and Firebase needs a moment to finish processing the
  /// returning auth result.
  Future<UserCredential?> resolvePendingRedirect() async {
    if (!kIsWeb) return null;
    try {
      final result = await _auth.getRedirectResult();
      return result.user == null ? null : result;
    } catch (_) {
      return null;
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Uses a full-page redirect on web (popups get blocked inside embedded
  /// browser panels / webviews, e.g. an IDE's built-in preview) and the
  /// google_sign_in plugin + credential exchange on Android/iOS.
  ///
  /// On web this navigates away immediately; the caller will not see this
  /// future resolve on this page load. The app must instead pick up the
  /// signed-in user from [authStateChanges] after the redirect returns
  /// (see SplashScreen).
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithRedirect(GoogleAuthProvider());
      return null;
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Sends a password-reset email. This also works for accounts that were
  /// created via Google Sign-In and never had a password set -- resetting
  /// establishes a password credential on that same account, letting the
  /// user log in with email/password afterwards too.
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  /// Turns a Firebase error into copy that's safe to show a user.
  String messageForError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found with that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'email-already-in-use':
          return 'An account already exists with that email. Try logging in, '
              "or use 'Forgot password?' if you signed up with Google.";
        case 'weak-password':
          return 'Choose a stronger password (at least 6 characters).';
        case 'invalid-credential':
          return 'Invalid email or password.';
        case 'sign-in-cancelled':
          return 'Sign-in was cancelled.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        default:
          return error.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
