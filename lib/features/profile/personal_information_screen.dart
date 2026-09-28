import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/user_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';
import '../../shared/models/app_user.dart';

/// Lets a signed-in user view and edit the personal-info fields collected
/// by the onboarding survey (name, age, gender, height, current weight),
/// reached from Profile -> Personal Information.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key, required this.profile});

  final AppUser profile;

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.displayName == 'Athlete' ? '' : profile.displayName);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _heightController = TextEditingController(text: profile.heightCm?.round().toString() ?? '');
    _weightController = TextEditingController(text: profile.currentWeightKg?.toStringAsFixed(1) ?? '');
    _gender = profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (name.isEmpty) {
      _showError('Enter your name.');
      return;
    }
    if (age == null || age < 13 || age > 99) {
      _showError('Enter a valid age (13-99).');
      return;
    }
    if (_gender == null) {
      _showError('Select your gender.');
      return;
    }
    if (height == null || height < 100 || height > 230) {
      _showError('Enter a valid height in cm (100-230).');
      return;
    }
    if (weight == null || weight < 30 || weight > 200) {
      _showError('Enter a valid weight in kg (30-200).');
      return;
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      _showError('You have been signed out. Please log in again.');
      return;
    }

    setState(() => _saving = true);
    try {
      await UserRepository.instance.updatePersonalInfo(
        uid: user.id,
        name: name,
        age: age,
        gender: _gender!,
        heightCm: height,
        currentWeightKg: weight,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Could not save your changes. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Personal Information', style: AppTextStyles.h3)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NAME', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Your name'),
              ),
              const SizedBox(height: 18),
              Text('AGE', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Your age'),
              ),
              const SizedBox(height: 18),
              Text('GENDER', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _GenderChip(label: 'Male', selected: _gender == 'Male', onTap: () => setState(() => _gender = 'Male'))),
                  const SizedBox(width: 10),
                  Expanded(child: _GenderChip(label: 'Female', selected: _gender == 'Female', onTap: () => setState(() => _gender = 'Female'))),
                  const SizedBox(width: 10),
                  Expanded(child: _GenderChip(label: 'Other', selected: _gender == 'Other', onTap: () => setState(() => _gender = 'Other'))),
                ],
              ),
              const SizedBox(height: 18),
              Text('HEIGHT (CM)', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Height in cm'),
              ),
              const SizedBox(height: 18),
              Text('CURRENT WEIGHT (KG)', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Weight in kg'),
              ),
              const SizedBox(height: 32),
              _saving
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(label: 'Save Changes', icon: Icons.check_rounded, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.background : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
