import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../survey/survey_screen.dart';
import 'signup_screen.dart';
import 'sso_row.dart';
import 'verify_email_screen.dart';
import 'verify_login_screen.dart';

/// Direct copy of the design handoff's "Auth Log in" screen
/// (MF Auth.dc.html) -- a red "Welcome back" hero panel over the form.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialErrorMessage});

  /// Shown once, right after the first frame -- used when SplashScreen
  /// detects an `?error=...` redirect (e.g. an expired/already-used
  /// password reset link) so the user sees a plain explanation instead
  /// of just landing here with no context.
  final String? initialErrorMessage;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final message = widget.initialErrorMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showError(message);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _goToApp() async {
    final user = AuthService.instance.currentUser;
    // Null on web right after signInWithGoogle(), since that call navigates
    // the whole page away before returning here -- SplashScreen handles
    // routing for that case once the redirect comes back.
    if (user == null) return;

    final surveyDone = await UserRepository.instance.ensureProfile(user.id);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => surveyDone ? const MainShell() : const SurveyScreen()),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email above first, then tap "Forgot password?".');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      _showMessage('Password reset email sent. Check your inbox.');
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('Enter your email and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      // Validates the password, but a correct password alone must never
      // reach the app: sign back out immediately and require a fresh
      // emailed code before the session actually counts.
      await AuthService.instance.signInWithEmail(email: email, password: password);
      await AuthService.instance.signOut();
      await AuthService.instance.sendLoginCode(email);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerifyLoginScreen(email: email)),
      );
    } catch (e) {
      if (AuthService.instance.isEmailNotConfirmed(e)) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
        );
        return;
      }
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      await _goToApp();
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToSignup() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MUSCLE FACTORY',
                      style: AppTextStyles.caption.copyWith(color: AppColors.background, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Welcome\nback',
                      style: AppTextStyles.h1.copyWith(color: AppColors.background, fontSize: 46, height: 0.9, letterSpacing: -1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EMAIL', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextField(controller: _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    Text('PASSWORD', style: AppTextStyles.caption),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        suffixIcon: TextButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          child: Text(
                            _obscure ? 'Show' : 'Hide',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _loading ? null : _forgotPassword,
                      child: Text('Forgot password?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 22),
                    SsoRow(onGoogle: _loading ? null : _loginWithGoogle, onApple: () => _showError('Sign in with Apple is not available yet.')),
                    const SizedBox(height: 22),
                    _loading
                        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : PrimaryButton(label: 'Log in', icon: Icons.arrow_forward_rounded, onPressed: _login),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('New to Muscle Factory? ', style: AppTextStyles.bodyMedium),
                        GestureDetector(
                          onTap: _loading ? null : _goToSignup,
                          child: Text(
                            'Create account',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
