import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../survey/survey_screen.dart';

/// Shown after sign-up, or after a login attempt on an unconfirmed
/// account. Asks for the 6-digit code Supabase emailed to [email] instead
/// of relying on a clickable confirmation link -- avoids the whole class
/// of "link points at the wrong redirect URL" problems entirely, since
/// nothing here involves a browser redirect.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showError('Enter the 6-digit code from your email.');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await AuthService.instance.verifySignupCode(email: widget.email, code: code);
      final user = response.user;
      if (user == null) {
        _showError('Could not verify that code. Please try again.');
        return;
      }

      final surveyDone = await UserRepository.instance.ensureProfile(user.id);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => surveyDone ? const MainShell() : const SurveyScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await AuthService.instance.resendSignupCode(widget.email);
      _showMessage('Sent a new code to ${widget.email}.');
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.background, size: 28),
              ),
              const SizedBox(height: 28),
              Text('Check Your Email', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to ${widget.email}. Enter it below to verify your account.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Text('VERIFICATION CODE', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: AppTextStyles.h1.copyWith(letterSpacing: 8, fontSize: 28),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '000000',
                ),
              ),
              const SizedBox(height: 12),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Verify', icon: Icons.check_rounded, onPressed: _verify),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(
                    _resending ? 'Sending...' : "Didn't get a code? Resend",
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
