import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Home's standalone "Timer" quick action -- a simple interval/rest timer
/// not tied to a workout session.
class TimerSheet extends StatefulWidget {
  const TimerSheet({super.key});

  @override
  State<TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<TimerSheet> {
  static const _presets = [30, 60, 90, 120, 180, 300];

  int _durationSeconds = 60;
  int _remaining = 60;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setDuration(int seconds) {
    _timer?.cancel();
    setState(() {
      _durationSeconds = seconds;
      _remaining = seconds;
      _running = false;
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remaining = _durationSeconds;
      _running = false;
    });
  }

  String get _display {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Timer', style: AppTextStyles.h2),
          const SizedBox(height: 20),
          Center(child: Text(_display, style: AppTextStyles.display.copyWith(fontSize: 64))),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((s) {
              final selected = s == _durationSeconds;
              return GestureDetector(
                onTap: () => _setDuration(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: selected ? AppColors.primary : Colors.transparent,
                  child: Text(
                    s < 60 ? '${s}s' : '${s ~/ 60}m',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected ? AppColors.background : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: AppColors.primary,
                  child: InkWell(
                    onTap: _toggle,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text(_running ? 'Pause' : 'Start', style: AppTextStyles.button),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _reset,
                  child: Container(
                    height: 52,
                    width: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
                    child: Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
