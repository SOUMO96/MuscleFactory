import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import 'login_screen.dart';
import 'sso_row.dart';
import 'verify_email_screen.dart';

/// Direct copy of the design handoff's "Auth Sign up" screen (MF Auth.dc.html)
/// -- no name field (the survey's first question collects that), a live
/// password-strength meter, and the Apple/Google SSO row.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  int get _passwordScore {
    final pw = _passwordController.text;
    var score = 0;
    if (pw.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw) && RegExp(r'[a-z]').hasMatch(pw)) score++;
    if (RegExp(r'\d').hasMatch(pw)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score++;
    return score;
  }

  static const _hints = [
    '8+ characters, mix of letters and numbers',
    'Weak — add more variety',
    'Okay — add a number or symbol',
    'Good password',
    'Strong password',
  ];

  void _goToLogin() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Enter your email and password.');
      return;
    }

    setState(() => _loading = true);
    try {
      // No name field here (see file doc comment) -- the trigger falls
      // back to "Athlete" until the survey sets the real display name.
      await AuthService.instance.signUpWithEmail(email: email, password: password, displayName: '');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
        (route) => false,
      );
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _passwordScore;
    Color bar(int i) {
      if (i >= score) return AppColors.divider;
      return score <= 1 ? AppColors.primary : AppColors.textPrimary;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('MUSCLE FACTORY', style: AppTextStyles.caption.copyWith(letterSpacing: 1.2)),
                  GestureDetector(
                    onTap: _loading ? null : _goToLogin,
                    child: Text('Log in', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Create your account', style: AppTextStyles.h1.copyWith(fontSize: 30)),
              const SizedBox(height: 8),
              Text('One account for your plans, progress and gym pass.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),
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
              const SizedBox(height: 8),
              Row(children: [for (var i = 0; i < 4; i++) Expanded(child: Container(margin: EdgeInsets.only(right: i == 3 ? 0 : 3), height: 4, color: bar(i)))]),
              const SizedBox(height: 6),
              Text(_hints[score], style: AppTextStyles.bodySmall),
              const SizedBox(height: 22),
              SsoRow(onGoogle: _loading ? null : _continueWithGoogle, onApple: () => _showError('Sign in with Apple is not available yet.')),
              const SizedBox(height: 22),
              _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Create account', icon: Icons.arrow_forward_rounded, onPressed: _createAccount),
              const SizedBox(height: 12),
              Text('By continuing you agree to the Terms and Privacy Policy.', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
