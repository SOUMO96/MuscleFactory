import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The design's "or continue with" divider + Apple/Google SSO button
/// pair, shared by SignupScreen and LoginScreen.
class SsoRow extends StatelessWidget {
  const SsoRow({super.key, required this.onGoogle, required this.onApple});

  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider, thickness: 2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('OR CONTINUE WITH', style: AppTextStyles.caption),
            ),
            Expanded(child: Divider(color: AppColors.divider, thickness: 2)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Material(
                color: const Color(0xFF0D0C0C),
                child: InkWell(
                  onTap: onApple,
                  child: const SizedBox(
                    height: 52,
                    child: Icon(Icons.apple_rounded, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: Colors.white,
                child: InkWell(
                  onTap: onGoogle,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2)),
                    child: const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
