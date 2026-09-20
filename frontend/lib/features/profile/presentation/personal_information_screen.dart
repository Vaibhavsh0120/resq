import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../screens/onboarding/medical_info_step.dart';
import '../../../screens/onboarding/personal_info_step.dart';
import '../../../services/user_profile_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Your information')),
      body: uid == null
          ? const Center(child: Text('Sign in to edit your information.'))
          : FutureBuilder<UserProfile>(
              future: UserProfileService.instance.fetchProfile(uid),
              builder: (context, snapshot) {
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
  bool _personalValid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _personal = widget.profile.personalInfo;
    _medical = widget.profile.medicalInfo;
  }

  Future<void> _save() async {
    if (!_personalValid) return;
    setState(() => _saving = true);
    try {
      await UserProfileService.instance.savePersonalInfo(widget.uid, _personal);
      await UserProfileService.instance.saveMedicalInfo(widget.uid, _medical);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your information was saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your information could not be saved.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageContent(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Personal details',
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
            'Medical and accessibility details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          MedicalInfoStep(
            initialValue: _medical,
            onChanged: (value) => _medical = value,
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
            label: const Text('Save information'),
          ),
        ],
      ),
    );
  }
}
