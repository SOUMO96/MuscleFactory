import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/main_shell.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../survey/survey_screen.dart';
import 'login_screen.dart';
import 'otp_boxes.dart';

/// Second login step, shown after a correct password. Asks for the 6-digit
/// code just emailed to [email]; sign-in only completes once it's verified.
class VerifyLoginScreen extends StatefulWidget {
  const VerifyLoginScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyLoginScreen> createState() => _VerifyLoginScreenState();
}

class _VerifyLoginScreenState extends State<VerifyLoginScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _wrong = false;
  Timer? _timer;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    // OtpBoxes rebuilds itself, but this screen's own build (digit counter,
    // Verify button state) needs a listener too or it stays on the initial state.
    _codeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2) return widget.email;
    final local = parts[0].length <= 2 ? parts[0] : parts[0].substring(0, 2);
    return '$local•••@${parts[1]}';
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;

    setState(() {
      _loading = true;
      _wrong = false;
    });
    try {
      final response = await AuthService.instance.verifyLoginCode(email: widget.email, code: code);
      final user = response.user;
      if (user == null) {
        setState(() => _wrong = true);
        return;
      }

      final surveyDone = await UserRepository.instance.ensureProfile(user.id);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => surveyDone ? const MainShell() : const SurveyScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _wrong = true);
      _showError(AuthService.instance.messageForError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    try {
      await AuthService.instance.sendLoginCode(widget.email);
      _codeController.clear();
      setState(() {
        _wrong = false;
        _resendIn = 60;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_resendIn <= 1) {
          t.cancel();
          setState(() => _resendIn = 0);
        } else {
          setState(() => _resendIn--);
        }
      });
    } catch (e) {
      _showError(AuthService.instance.messageForError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _codeController.text;
    final full = code.length == 6;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
              ),
              const SizedBox(height: 28),
              Text('CONFIRM IT\'S YOU', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              const SizedBox(height: 8),
              Text('Enter the 6-digit code', style: AppTextStyles.h1.copyWith(fontSize: 30)),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium,
                  children: [
                    const TextSpan(text: 'We sent it to '),
                    TextSpan(text: _maskedEmail, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              OtpBoxes(controller: _codeController, hasError: _wrong, autofocus: true),
              const SizedBox(height: 12),
              Text(
                _wrong
                    ? "That code doesn't match. Try again."
                    : full
                        ? 'Ready to verify'
                        : '${6 - code.length} digits to go',
                style: AppTextStyles.bodyMedium.copyWith(color: _wrong ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider, width: 2), bottom: BorderSide(color: AppColors.divider, width: 1))),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Didn't get it?", style: AppTextStyles.bodyLarge),
                    GestureDetector(
                      onTap: _resend,
                      child: Text(
                        _resendIn > 0 ? 'Resend in 0:${_resendIn.toString().padLeft(2, '0')}' : 'Resend code',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _resendIn > 0 ? AppColors.textSecondary : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Opacity(
                opacity: full ? 1 : 0.45,
                child: Material(
                  color: AppColors.primary,
                  child: InkWell(
                    onTap: full && !_loading ? _verify : null,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      child: _loading
                          ? CircularProgressIndicator(color: AppColors.background)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Verify', style: AppTextStyles.button),
                                Icon(Icons.arrow_forward_rounded, color: AppColors.background, size: 20),
                              ],
                            ),
                    ),
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
