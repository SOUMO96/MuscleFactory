import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../survey/survey_screen.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';
import 'verify_login_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.primaryGradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.bolt_rounded, color: AppColors.background, size: 30),
              ),
              const SizedBox(height: 28),
              Text('Welcome Back', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Log in to continue crushing your goals.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Text('EMAIL', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 18),
              Text('PASSWORD', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _forgotPassword,
                  child: Text('Forgot password?', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 12),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Log In', onPressed: _login),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with', style: AppTextStyles.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Google',
                      onTap: _loading ? null : _loginWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.apple_rounded,
                      label: 'Apple',
                      onTap: () => _showError('Sign in with Apple is not available yet.'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: Text(
                      'Sign Up',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
