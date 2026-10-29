import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../survey/survey_screen.dart';

/// Shown when the user arrives from a "Forgot password" email link. The link
/// already signs them in, so this is where they set the new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 8 || !RegExp(r'[a-z]').hasMatch(password) || !RegExp(r'[A-Z]').hasMatch(password) || !RegExp(r'\d').hasMatch(password)) {
      _showError('Password must be at least 8 characters with upper and lower case letters and a number.');
      return;
    }
    if (password != confirm) {
      _showError('Passwords do not match.');
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _showError('This reset link has expired. Please request a new one.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.updateOwnPassword(password);
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
                  gradient: LinearGradient(colors: AppColors.primaryGradient),
                ),
                child: Icon(Icons.lock_reset_rounded, color: AppColors.background, size: 30),
              ),
              const SizedBox(height: 28),
              Text('Set a New Password', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Choose a new password for your account.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Text('NEW PASSWORD', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Min. 8 characters, upper+lower case, a number',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('CONFIRM PASSWORD', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Re-enter your new password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Save New Password', icon: Icons.check_rounded, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
