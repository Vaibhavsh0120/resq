import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

/// Onboarding Step 1 — Personal Info. Pure, controller-driven form widget:
/// [OnboardingFlow] owns the [PersonalInfo] state and passes it down, this
/// widget only edits it via [onChanged] and reports [onValidChanged] so the
/// flow controller knows whether "Continue" should be enabled.
class PersonalInfoStep extends StatefulWidget {
  const PersonalInfoStep({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.onValidChanged,
  });

  final PersonalInfo initialValue;
  final ValueChanged<PersonalInfo> onChanged;
  final ValueChanged<bool> onValidChanged;

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  DateTime? _dateOfBirth;
  BloodType? _bloodType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialValue.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialValue.phoneNumber ?? '',
    );
    _dateOfBirth = widget.initialValue.dateOfBirth;
    _bloodType = widget.initialValue.bloodType;
    _nameController.addListener(_emit);
    _phoneController.addListener(_emit);
    // Report initial validity once the first frame is up.
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _emit() {
    final value = PersonalInfo(
      fullName: _nameController.text,
      phoneNumber: _phoneController.text,
      dateOfBirth: _dateOfBirth,
      bloodType: _bloodType,
    );
    widget.onChanged(value);
    widget.onValidChanged(value.isComplete);
  }

  Future<void> _pickDateOfBirth() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Full name',
          controller: _nameController,
          hintText: 'Jordan Rivera',
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Phone number',
          controller: _phoneController,
          hintText: '+1 555 123 4567',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Date of birth', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        _TapField(
          onTap: _pickDateOfBirth,
          icon: Icons.calendar_today_outlined,
          label: _dateOfBirth != null
              ? _formatDate(_dateOfBirth!)
              : 'Select date of birth',
          isPlaceholder: _dateOfBirth == null,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Blood type', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        _BloodTypeSelector(
          selected: _bloodType,
          onSelected: (type) {
            HapticFeedback.selectionClick();
            setState(() => _bloodType = type);
            _emit();
          },
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.isPlaceholder,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(AppRadius.base),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.base),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: isPlaceholder
                      ? textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        )
                      : textTheme.bodyLarge,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BloodTypeSelector extends StatelessWidget {
  const _BloodTypeSelector({required this.selected, required this.onSelected});

  final BloodType? selected;
  final ValueChanged<BloodType> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final types = BloodType.values.where((t) => t != BloodType.unknown);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = selected == type;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: ChoiceChip(
            label: Text(type.label),
            selected: isSelected,
            onSelected: (_) => onSelected(type),
            showCheckmark: false,
            selectedColor: scheme.secondary,
            backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
            side: BorderSide(
              color: isSelected ? scheme.secondary : scheme.outline,
            ),
            labelStyle: TextStyle(
              color: isSelected ? scheme.onSecondary : scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        );
      }).toList(),
    );
  }
}
