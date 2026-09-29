import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../screens/onboarding/medical_info_step.dart';
import '../../../screens/onboarding/personal_info_step.dart';
import '../../../services/user_profile_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: Text(strings.yourInformation)),
      body: uid == null
          ? Center(child: Text(strings.signInEditInformation))
          : FutureBuilder<UserProfile>(
              future: UserProfileService.instance.fetchProfile(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(strings.informationLoadFailed));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _InformationForm(uid: uid, profile: snapshot.data!);
              },
            ),
    );
  }
}

class _InformationForm extends StatefulWidget {
  const _InformationForm({required this.uid, required this.profile});
  final String uid;
  final UserProfile profile;

  @override
  State<_InformationForm> createState() => _InformationFormState();
}

class _InformationFormState extends State<_InformationForm> {
  late PersonalInfo _personal;
  late MedicalInfo _medical;
  late final TextEditingController _districtController;
  late final TextEditingController _stateController;
  bool _personalValid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _personal = widget.profile.personalInfo;
    _medical = widget.profile.medicalInfo;
    _districtController = TextEditingController(
      text: widget.profile.homeLocation.city,
    );
    _stateController = TextEditingController(
      text: widget.profile.homeLocation.state,
    );
  }

  @override
  void dispose() {
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_personalValid) return;
    final strings = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await UserProfileService.instance.savePersonalInfo(widget.uid, _personal);
      await UserProfileService.instance.saveMedicalInfo(widget.uid, _medical);
      await UserProfileService.instance.saveHomeLocation(
        widget.uid,
        widget.profile.homeLocation.copyWith(
          city: _districtController.text.trim(),
          state: _stateController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.informationSaved)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.informationSaveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppPageContent(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            strings.personalDetails,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          PersonalInfoStep(
            initialValue: _personal,
            onChanged: (value) => _personal = value,
            onValidChanged: (value) => setState(() => _personalValid = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            strings.medicalDetails,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          MedicalInfoStep(
            initialValue: _medical,
            onChanged: (value) => _medical = value,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            strings.localAlerts,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(strings.districtStateHelp),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _districtController,
            decoration: InputDecoration(
              labelText: strings.district,
              hintText: strings.districtExample,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _stateController,
            decoration: InputDecoration(
              labelText: strings.state,
              hintText: strings.stateExample,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: !_personalValid || _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(strings.saveInformation),
          ),
        ],
      ),
    );
  }
}
