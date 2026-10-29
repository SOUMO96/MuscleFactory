import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase Auth so the UI layer never talks to the
/// Supabase SDK directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoTrueClient _auth = Supabase.instance.client.auth;

  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((state) => state.session?.user);

  /// Raw auth state stream. Needed to catch [AuthChangeEvent.passwordRecovery],
  /// so a reset-password link opens the new-password screen instead of the app.
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

  /// Redirect-based on every platform, since popups get blocked in embedded
  /// browsers. On web this leaves the page; the app picks the user back up from
  /// [authStateChanges] after the redirect (see SplashScreen).
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

  /// True if [error] is Supabase's "email not confirmed" rejection, so callers
  /// can route to [VerifyEmailScreen] instead of showing an error.
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

  /// Emails a one-time code for the second login step, sent after the password
  /// has already checked out. `shouldCreateUser: false` stops it creating accounts.
  Future<void> sendLoginCode(String email) {
    return _auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  /// Confirms the login one-time code and establishes the real session.
  Future<AuthResponse> verifyLoginCode({
    required String email,
    required String code,
  }) {
    return _auth.verifyOTP(email: email, token: code, type: OtpType.email);
  }

  /// Turns a Supabase error into copy that's safe to show a user.
  String messageForError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials') || message.contains('invalid_credentials')) {
        return 'Incorrect email or password.';
      }
      // Deliberately vague: saying an account already exists would let anyone
      // check whether an email is registered (account enumeration).
      if (message.contains('user already registered') || message.contains('already exists')) {
        return "Couldn't create that account. If you already have one, try logging in or resetting your password instead.";
      }
      if (message.contains('email not confirmed')) {
        return 'Please confirm your email before logging in -- check your inbox.';
      }
      if (message.contains('password') && (message.contains('least') || message.contains('character') || message.contains('weak'))) {
        return 'Password must be at least 8 characters with upper and lower case letters and a number.';
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
