import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

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
  late IsoCode _phoneCountry;
  DateTime? _dateOfBirth;
  BloodType? _bloodType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialValue.fullName ?? '',
    );
    final initialPhone = _initialPhoneNumber(widget.initialValue.phoneNumber);
    _phoneCountry = initialPhone.isoCode;
    _phoneController = TextEditingController(text: initialPhone.formatNsn());
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
    final phone = _parsedPhone;
    final value = PersonalInfo(
      fullName: _nameController.text,
      phoneNumber: phone == null || phone.nsn.isEmpty
          ? null
          : phone.international,
      dateOfBirth: _dateOfBirth,
      bloodType: _bloodType,
    );
    widget.onChanged(value);
    widget.onValidChanged(value.isComplete);
  }

  PhoneNumber? get _parsedPhone {
    if (_phoneController.text.trim().isEmpty) return null;
    try {
      return PhoneNumber.parse(
        _phoneController.text,
        destinationCountry: _phoneCountry,
      );
    } on PhoneNumberException {
      return null;
    }
  }

  Future<void> _pickPhoneCountry() async {
    HapticFeedback.selectionClick();
    final selected = await showDialog<IsoCode>(
      context: context,
      builder: (context) => _CountryCodeDialog(selected: _phoneCountry),
    );
    if (selected != null && selected != _phoneCountry) {
      setState(() => _phoneCountry = selected);
      _emit();
    }
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
        Text('Phone number', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              key: const ValueKey('country-code-button'),
              onPressed: _pickPhoneCountry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(112, 56),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_phoneCountry.name} +${_countryDialCode(_phoneCountry)}',
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                key: const ValueKey('phone-number-input'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9()\-\s]')),
                ],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(hintText: 'Phone number'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your phone number';
                  }
                  if (!(_parsedPhone?.isValid() ?? false)) {
                    return 'Invalid number for selected country';
                  }
                  return null;
                },
              ),
            ),
          ],
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

  PhoneNumber _initialPhoneNumber(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      try {
        return PhoneNumber.parse(value);
      } on PhoneNumberException {
        // Fall through to a clean default for legacy invalid data.
      }
    }
    final countryCode = WidgetsBinding
        .instance
        .platformDispatcher
        .locale
        .countryCode
        ?.toUpperCase();
    var isoCode = IsoCode.IN;
    for (final candidate in IsoCode.values) {
      if (candidate.name == countryCode) {
        isoCode = candidate;
        break;
      }
    }
    return PhoneNumber(isoCode: isoCode, nsn: '');
  }

  static String _countryDialCode(IsoCode isoCode) =>
      PhoneNumber(isoCode: isoCode, nsn: '').countryCode;
}

class _CountryCodeDialog extends StatefulWidget {
  const _CountryCodeDialog({required this.selected});

  final IsoCode selected;

  @override
  State<_CountryCodeDialog> createState() => _CountryCodeDialogState();
}

class _CountryCodeDialogState extends State<_CountryCodeDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final countries = IsoCode.values.where((code) {
      if (_query.isEmpty) return true;
      final dialCode = PhoneNumber(isoCode: code, nsn: '').countryCode;
      final query = _query.toUpperCase().replaceAll('+', '');
      return code.name.contains(query) || dialCode.startsWith(query);
    }).toList();

    return AlertDialog(
      title: const Text('Choose country code'),
      content: SizedBox(
        width: 420,
        height: 480,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search country or code',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: countries.length,
                itemBuilder: (context, index) {
                  final country = countries[index];
                  final dialCode = PhoneNumber(
                    isoCode: country,
                    nsn: '',
                  ).countryCode;
                  return ListTile(
                    selected: country == widget.selected,
                    title: Text(country.name),
                    trailing: Text('+$dialCode'),
                    onTap: () => Navigator.of(context).pop(country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
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
