import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import 'family_circle_step.dart';
import 'home_location_step.dart';
import 'medical_info_step.dart';
import 'onboarding_shell.dart';
import 'personal_info_step.dart';

/// Owns the 4-step onboarding flow: current step, the in-progress data for
/// each step, and persistence. Each "Continue" tap saves *only that step's*
/// data to Firestore before advancing — so if the user quits mid-flow,
/// [resumeStep] on their profile tells the next launch exactly where to
/// pick back up (see [UserProfileService]).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.initialProfile});

  final UserProfile initialProfile;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _totalSteps = 4;

  late int _step;
  late PersonalInfo _personalInfo;
  late MedicalInfo _medicalInfo;
  late FamilyCircle _familyCircle;
  late HomeLocation _homeLocation;

  bool _isPersonalInfoValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Resume at whatever step the profile says was reached, clamped to a
    // valid range in case of stale/corrupt data.
    _step = widget.initialProfile.resumeStep.clamp(1, _totalSteps);
    _personalInfo = widget.initialProfile.personalInfo;
    _medicalInfo = widget.initialProfile.medicalInfo;
    _familyCircle = widget.initialProfile.familyCircle;
    _homeLocation = widget.initialProfile.homeLocation;
    // Personal info may already be complete if resuming past step 1.
    _isPersonalInfoValid = _personalInfo.isComplete || _step > 1;
  }

  String get _uid => widget.initialProfile.uid;

  String get _addressCountryCode {
    final phone = _personalInfo.phoneNumber;
    if (phone != null && phone.trim().isNotEmpty) {
      try {
        return PhoneNumber.parse(phone).isoCode.name;
      } on PhoneNumberException {
        // Fall back to the device region for legacy/invalid saved numbers.
      }
    }
    return WidgetsBinding.instance.platformDispatcher.locale.countryCode
            ?.toUpperCase() ??
        'IN';
  }

  Future<void> _handleCancel() async {
    // Cancelling on step 1 backs all the way out — sign out and return to
    // Login. Partial data already saved from a prior step (if the user
    // returns) is preserved; nothing here deletes it.
    await AuthService.instance.signOut();
  }

  void _goBack() {
    if (_step == 1) {
      _handleCancel();
    } else {
      setState(() => _step -= 1);
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);
    try {
      switch (_step) {
        case 1:
          await UserProfileService.instance.savePersonalInfo(
            _uid,
            _personalInfo,
          );
          break;
        case 2:
          await UserProfileService.instance.saveMedicalInfo(_uid, _medicalInfo);
          break;
        case 3:
          await UserProfileService.instance.saveFamilyCircle(
            _uid,
            _familyCircle,
          );
          break;
        case 4:
          await UserProfileService.instance.saveHomeLocation(
            _uid,
            _homeLocation,
          );
          await UserProfileService.instance.completeOnboarding(_uid);
          // OnboardingGate's profile stream picks up onboardingCompleted
          // and routes to Home automatically — nothing else to do here.
          return;
      }
      if (mounted) setState(() => _step += 1);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't save — check your connection and try again.",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _isNextEnabled {
    switch (_step) {
      case 1:
        return _isPersonalInfoValid;
      default:
        return true; // Steps 2–4 have no required fields.
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      1 => OnboardingShell(
        step: 1,
        totalSteps: _totalSteps,
        title: 'Personal info',
        subtitle: 'The basics responders need to know about you.',
        onBackOrCancel: _handleCancel,
        onNext: _saveAndContinue,
        isNextEnabled: _isNextEnabled,
        isNextLoading: _isSaving,
        child: PersonalInfoStep(
          initialValue: _personalInfo,
          onChanged: (value) => _personalInfo = value,
          onValidChanged: (valid) =>
              setState(() => _isPersonalInfoValid = valid),
        ),
      ),
      2 => OnboardingShell(
        step: 2,
        totalSteps: _totalSteps,
        title: 'Medical info',
        subtitle: 'Optional, but can be critical in an emergency.',
        onBackOrCancel: _goBack,
        onNext: _saveAndContinue,
        isNextLoading: _isSaving,
        child: MedicalInfoStep(
          initialValue: _medicalInfo,
          onChanged: (value) => _medicalInfo = value,
        ),
      ),
      3 => OnboardingShell(
        step: 3,
        totalSteps: _totalSteps,
        title: 'Family circle',
        subtitle: 'Add trusted people ResQ can help you reach.',
        onBackOrCancel: _goBack,
        onNext: _saveAndContinue,
        isNextLoading: _isSaving,
        child: FamilyCircleStep(
          initialValue: _familyCircle,
          onChanged: (value) => _familyCircle = value,
        ),
      ),
      _ => OnboardingShell(
        step: 4,
        totalSteps: _totalSteps,
        title: 'Home location',
        subtitle: 'Helps responders find you faster.',
        onBackOrCancel: _goBack,
        onNext: _saveAndContinue,
        nextLabel: 'Finish setup',
        isNextLoading: _isSaving,
        child: HomeLocationStep(
          initialValue: _homeLocation,
          countryCode: _addressCountryCode,
          onChanged: (value) => _homeLocation = value,
        ),
      ),
    };
  }
}
