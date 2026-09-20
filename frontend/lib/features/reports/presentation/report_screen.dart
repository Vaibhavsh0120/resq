import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';
import '../application/report_providers.dart';
import '../domain/incident_report.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.isGuest});

  final bool isGuest;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _description = TextEditingController();
  final _picker = ImagePicker();
  HazardType _selected = HazardType.flood;
  Position? _position;
  XFile? _photo;
  bool _locating = false;
  bool _submitting = false;
  String? _pendingPhotoReportId;

  IncidentReportDraft get _draft => IncidentReportDraft(
    hazard: _selected,
    description: _description.text,
    latitude: _position?.latitude,
    longitude: _position?.longitude,
    photoPath: _photo?.path,
  );

  Future<void> _capturePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 78,
      );
      if (photo != null && mounted) {
        setState(() => _photo = photo);
      }
    } catch (_) {
      if (mounted) {
        _message('Camera is unavailable. You can submit without a photo.');
      }
    }
  }

  Future<void> _addLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const PermissionDeniedException('Location permission denied');
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() => _position = position);
      }
    } catch (_) {
      if (mounted) {
        _message('Location was not added. You can still submit the report.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _showAddDetails() {
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(_photo == null ? 'Take a photo' : 'Replace photo'),
                subtitle: const Text('Optional evidence for private review'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _capturePhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_location_alt_outlined),
                title: Text(
                  _position == null
                      ? 'Add current location'
                      : 'Update location',
                ),
                subtitle: const Text('Optional and permission-based'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _addLocation();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.isGuest) return;
    if (_description.text.trim().length < 3) {
      _message('Add a short description before submitting.');
      return;
    }
    setState(() => _submitting = true);
    final photo = _photo;
    try {
      final repository = ref.read(reportsRepositoryProvider);
      final reportId = _pendingPhotoReportId ?? await repository.submit(_draft);
      if (photo != null) {
        _pendingPhotoReportId = reportId;
        await repository.uploadPhoto(
          reportId: reportId,
          bytes: await photo.readAsBytes(),
          filename: photo.name,
        );
      }
      if (!mounted) return;
      _description.clear();
      setState(() {
        _photo = null;
        _position = null;
        _pendingPhotoReportId = null;
      });
      _message('Report submitted privately for verification.');
      await _showGuidance();
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showGuidance() {
    final guidance = _draft.guidance;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selected.label} guidance',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Do', style: Theme.of(context).textTheme.titleMedium),
              ...guidance.dos.map(
                (item) =>
                    _GuidanceRow(icon: Icons.check_circle_rounded, text: item),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text("Don't", style: Theme.of(context).textTheme.titleMedium),
              ...guidance.donts.map(
                (item) => _GuidanceRow(icon: Icons.cancel_rounded, text: item),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close guidance'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showSignInGate() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 40),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Sign in to submit a private report. Guidance remains available without an account.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppPageContent(
      child: ListView(
        key: const PageStorageKey('report-scroll'),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          ResQPageHeader(
            title: strings.report,
            subtitle: strings.reportSubtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'What are you experiencing?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HazardType.values
                .map(
                  (type) => ChoiceChip(
                    label: Text(type.label),
                    selected: _selected == type,
                    onSelected: (_) => setState(() => _selected = type),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            child: TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'What can you see?',
                hintText: 'Add useful details without approaching danger',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _locating || _submitting ? null : _showAddDetails,
            icon: _locating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _photo != null || _position != null
                        ? Icons.check_circle_rounded
                        : Icons.add_a_photo_outlined,
                  ),
            label: Text(
              _photo != null || _position != null
                  ? 'Optional details added'
                  : 'Add photo or location',
            ),
          ),
          if (_photo != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Photo metadata is removed before private review.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: _showGuidance,
            child: Text(strings.getGuidance),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: _submitting
                ? null
                : widget.isGuest
                ? _showSignInGate
                : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              widget.isGuest
                  ? 'Sign in to submit report'
                  : strings.submitPrivateReport,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(text),
    );
  }
}
