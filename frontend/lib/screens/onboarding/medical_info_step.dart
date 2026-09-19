import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';

/// Onboarding Step 2 — Medical Info. Every field here is optional (an
/// allergy-free, condition-free person with no accessibility needs is a
/// valid, complete answer) — see [MedicalInfo.stepCompleted].
class MedicalInfoStep extends StatefulWidget {
  const MedicalInfoStep({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final MedicalInfo initialValue;
  final ValueChanged<MedicalInfo> onChanged;

  @override
  State<MedicalInfoStep> createState() => _MedicalInfoStepState();
}

class _MedicalInfoStepState extends State<MedicalInfoStep> {
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late bool _usesMobilityAid;
  late bool _hasVisualImpairment;
  late bool _hasHearingImpairment;

  @override
  void initState() {
    super.initState();
    _allergiesController = TextEditingController(
      text: widget.initialValue.allergies ?? '',
    );
    _conditionsController = TextEditingController(
      text: widget.initialValue.medicalConditions ?? '',
    );
    _usesMobilityAid = widget.initialValue.usesMobilityAid;
    _hasVisualImpairment = widget.initialValue.hasVisualImpairment;
    _hasHearingImpairment = widget.initialValue.hasHearingImpairment;
    _allergiesController.addListener(_emit);
    _conditionsController.addListener(_emit);
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      MedicalInfo(
        allergies: _allergiesController.text,
        medicalConditions: _conditionsController.text,
        usesMobilityAid: _usesMobilityAid,
        hasVisualImpairment: _hasVisualImpairment,
        hasHearingImpairment: _hasHearingImpairment,
        stepCompleted: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Allergies',
          controller: _allergiesController,
          hintText: 'e.g. Penicillin, peanuts — or leave blank',
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.warning_amber_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Medical conditions',
          controller: _conditionsController,
          hintText: 'e.g. Asthma, diabetes — or leave blank',
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.medical_information_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Accessibility needs', style: textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          'Optional — select any that apply so responders know how to help.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AccessibilityTile(
          icon: Icons.accessible_outlined,
          label: 'Uses a mobility aid',
          value: _usesMobilityAid,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() => _usesMobilityAid = value);
            _emit();
          },
        ),
        _AccessibilityTile(
          icon: Icons.visibility_off_outlined,
          label: 'Visual impairment',
          value: _hasVisualImpairment,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() => _hasVisualImpairment = value);
            _emit();
          },
        ),
        _AccessibilityTile(
          icon: Icons.hearing_disabled_outlined,
          label: 'Hearing impairment',
          value: _hasHearingImpairment,
          onChanged: (value) {
            HapticFeedback.selectionClick();
            setState(() => _hasHearingImpairment = value);
            _emit();
          },
        ),
      ],
    );
  }
}

class _AccessibilityTile extends StatelessWidget {
  const _AccessibilityTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: value
              ? scheme.secondary.withValues(alpha: 0.08)
              : Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: value
                ? scheme.secondary.withValues(alpha: 0.4)
                : scheme.outline,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.base),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.base),
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: value ? scheme.secondary : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
