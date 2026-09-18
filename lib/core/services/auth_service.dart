import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth so the UI layer never talks to the
/// Supabase SDK directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoTrueClient _auth = Supabase.instance.client.auth;

  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((state) => state.session?.user);

  /// Raw auth state stream, event included -- needed to detect
  /// [AuthChangeEvent.passwordRecovery] specifically (clicking a "forgot
  /// password" email link signs the user in, but the app must show a
  /// "set a new password" screen at that point rather than just letting
  /// them into the app with their old/forgotten password still active).
  Stream<AuthState> get authStateEvents => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    // The `display_name` key here lands in raw_user_meta_data, which the
    // handle_new_user() Postgres trigger reads to seed the profiles row --
    // see supabase/migrations/.
    return _auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  /// Redirect-based (not popup-based) on every platform, so it isn't
  /// affected by popups being blocked inside embedded browser
  /// panels/webviews. On web this navigates the page away immediately;
  /// the app picks the signed-in user back up from [authStateChanges]
  /// once Supabase redirects back (see SplashScreen).
  Future<bool> signInWithGoogle() {
    return _auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  /// Sets a new password on the currently signed-in user -- used after a
  /// password-recovery link has already established a session (see
  /// [ResetPasswordScreen]).
  Future<void> updateOwnPassword(String newPassword) {
    return _auth.updateUser(UserAttributes(password: newPassword));
  }

  /// True if [error] is Supabase's "email not confirmed" rejection --
  /// callers use this to route to [VerifyEmailScreen] (see
  /// features/auth/verify_email_screen.dart) instead of just showing an
  /// error.
  bool isEmailNotConfirmed(Object error) {
    if (error is! AuthException) return false;
    return error.code == 'email_not_confirmed' || error.message.toLowerCase().contains('email not confirmed');
  }

  /// Confirms a pending sign-up using the 6-digit code emailed to the
  /// user. Returns an active session on success.
  Future<AuthResponse> verifySignupCode({
    required String email,
    required String code,
  }) {
    return _auth.verifyOTP(email: email, token: code, type: OtpType.signup);
  }

  /// Re-sends the signup verification code.
  Future<void> resendSignupCode(String email) {
    return _auth.resend(type: OtpType.signup, email: email);
  }

  /// Turns a Supabase error into copy that's safe to show a user.
  String messageForError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials') || message.contains('invalid_credentials')) {
        return 'Incorrect email or password.';
      }
      if (message.contains('user already registered') || message.contains('already exists')) {
        return 'An account already exists with that email. Try logging in, '
            "or use 'Forgot password?' if you signed up with Google.";
      }
      if (message.contains('email not confirmed')) {
        return 'Please confirm your email before logging in -- check your inbox.';
      }
      if (message.contains('password') && message.contains('least')) {
        return 'Choose a stronger password (at least 6 characters).';
      }
      if (message.contains('email') && message.contains('invalid')) {
        return 'That email address looks invalid.';
      }
      if (message.contains('rate limit')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (message.contains('network')) {
        return 'Network error. Check your connection and try again.';
      }
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
