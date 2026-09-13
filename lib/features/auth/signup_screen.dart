import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscure = true;
  bool _agree = false;

  void _createAccount() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
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
              Text('Create Account', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Start your fitness journey today.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 28),
              Text('FULL NAME', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Alex Johnson',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 18),
              Text('EMAIL', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              const TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 18),
              Text('PASSWORD', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Min. 8 characters',
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
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Create Account', onPressed: _createAccount),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ', style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Log In',
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
