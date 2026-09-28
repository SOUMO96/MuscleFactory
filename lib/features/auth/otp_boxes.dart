import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The design's 6-box OTP input: a row of visible digit boxes with an
/// invisible numeric TextField stacked on top handling real input/focus
/// (the same technique the design mock itself uses).
class OtpBoxes extends StatelessWidget {
  const OtpBoxes({super.key, required this.controller, this.length = 6, this.hasError = false, this.autofocus = false});

  final TextEditingController controller;
  final int length;
  final bool hasError;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final code = controller.text;
        return SizedBox(
          height: 64,
          child: Stack(
            children: [
              Row(
                children: List.generate(length, (i) {
                  final filled = i < code.length;
                  final active = i == code.length;
                  final borderColor = hasError
                      ? AppColors.primary
                      : filled
                          ? AppColors.textPrimary
                          : active
                              ? AppColors.primary
                              : AppColors.divider;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i == length - 1 ? 0 : 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, border: Border.all(color: borderColor, width: 2)),
                      child: Text(filled ? code[i] : '', style: AppTextStyles.h1.copyWith(fontSize: 28)),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: controller,
                    autofocus: autofocus,
                    keyboardType: TextInputType.number,
                    maxLength: length,
                    decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
