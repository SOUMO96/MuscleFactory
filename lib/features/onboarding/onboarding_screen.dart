import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

/// Entry screen: a hero-photo panel over a red wordmark panel, with SSO and
/// email sign-up actions and a log-in link. Colors are fixed, not theme-adaptive.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _ink = Color(0xFF0D0C0C);
  static const _accent = Color(0xFFEC3013);

  bool _loading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      // On web this navigates the page away immediately; SplashScreen
      // picks the signed-in user back up once the redirect returns.
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signUpWithEmail() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen()));
  }

  void _logIn() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Column(
        children: [
          // Hero photo panel: a plain placeholder, since there's no real photo asset yet.
          Expanded(
            child: Container(
              width: double.infinity,
              color: _ink,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              alignment: Alignment.topRight,
              child: Text(
                'hero photo · lifter · b/w',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          // Red wordmark panel.
          Container(
            width: double.infinity,
            color: _accent,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -50),
                    child: const Text(
                      'MUSCLE\nFACTORY',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 0.86,
                        letterSpacing: -2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Train anywhere. Log every set. See it add up.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        _PosterButton(
                          label: 'Continue with Google',
                          filled: true,
                          onTap: _loading ? null : _continueWithGoogle,
                        ),
                        const SizedBox(height: 8),
                        _PosterButton(
                          label: 'Sign up with email',
                          filled: false,
                          onTap: _loading ? null : _signUpWithEmail,
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _loading ? null : _logIn,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 13, color: Colors.white, fontFamily: 'Archivo'),
                              children: [
                                TextSpan(text: 'Already a member? '),
                                TextSpan(
                                  text: 'Log in',
                                  style: TextStyle(fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterButton extends StatelessWidget {
  const _PosterButton({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF0D0C0C) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(border: filled ? null : Border.all(color: Colors.white, width: 2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
