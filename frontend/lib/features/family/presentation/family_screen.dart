import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';
import '../../updates/application/alerts_providers.dart';
import '../../profile/data/app_settings_repository.dart';
import '../application/family_providers.dart';
import '../domain/family_models.dart';
import 'family_member_screen.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key, required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final uid = isGuest ? null : ref.watch(currentUserIdProvider);
    if (uid == null) {
      return const _FamilyMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to use Family Circle',
        message: 'A registered account protects invitations, check-ins, and shared locations.',
      );
    }

    ref.watch(familyContactMigrationProvider(uid));

    final circleId = ref.watch(familyCircleIdProvider(uid));
    final contacts = ref.watch(emergencyContactsProvider(uid));
    final alerts = ref.watch(activeAlertsProvider).value ?? const [];
    final emergencyAlerts = alerts
        .where(
          (alert) => const {
            'critical',
            'warning',
            'extreme',
            'severe',
          }.contains(alert.severity.toLowerCase()),
        )
        .toList(growable: false);
    return ListView(
      key: const PageStorageKey('family-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        ResQPageHeader(title: strings.family, subtitle: strings.familySubtitle),
        const SizedBox(height: AppSpacing.xl),
        circleId.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => const _FamilyMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Family Circle is unavailable',
            message: 'Check your connection and try again.',
          ),
          data: (id) => id == null
              ? _NoCircle(contacts: contacts)
              : _ConnectedCircle(
                  uid: uid,
                  circleId: id,
                  activeEventId: emergencyAlerts.isEmpty
                      ? null
                      : emergencyAlerts.first.id,
                  contacts: contacts,
                ),
        ),
      ],
    );
  }
}

class _ConnectedCircle extends ConsumerStatefulWidget {
  const _ConnectedCircle({
    required this.uid,
    required this.circleId,
    required this.activeEventId,
    required this.contacts,
  });

  final String uid;
  final String circleId;
  final String? activeEventId;
  final AsyncValue<List<EmergencyContact>> contacts;

  @override
  ConsumerState<_ConnectedCircle> createState() => _ConnectedCircleState();
}

class _ConnectedCircleState extends ConsumerState<_ConnectedCircle> {
  bool _checkingIn = false;
  bool _enablingDaily = false;
  bool _sharingLocation = false;

  Future<void> _shareLocation() async {
    setState(() => _sharingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission is required.');
      }
      final position = await Geolocator.getCurrentPosition();
      await ref
          .read(familyRepositoryProvider)
          .shareLocation(
            circleId: widget.circleId,
            ownerId: widget.uid,
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Circle can see this location for one hour.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location could not be shared. Check permission and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingLocation = false);
    }
  }

  Future<void> _enableDailyCheckIns() async {
    final eventId = widget.activeEventId;
    if (eventId == null) return;
    setState(() => _enablingDaily = true);
    try {
      await AppSettingsRepository(FirebaseFirestore.instance)
          .activateEmergencyCheckIn(uid: widget.uid, eventId: eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily emergency check-ins are set for 09:00.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enablingDaily = false);
    }
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      await ref
          .read(familyRepositoryProvider)
          .checkIn(
            SafetyCheckIn(
              circleId: widget.circleId,
              userId: widget.uid,
              safe: true,
              eventId: widget.activeEventId,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Circle can now see that you are safe.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your check-in could not be saved. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(circleMembersProvider(widget.circleId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: widget.activeEventId == null || _checkingIn
              ? null
              : _checkIn,
          icon: _checkingIn
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.health_and_safety_rounded),
          label: Text(
            widget.activeEventId == null
                ? 'Check-ins activate during emergencies'
                : "I'm safe — check in",
          ),
        ),
        if (widget.activeEventId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _enablingDaily ? null : _enableDailyCheckIns,
            icon: _enablingDaily
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.schedule_rounded),
            label: const Text('Enable daily check-ins for this emergency'),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _sharingLocation ? null : _shareLocation,
          icon: _sharingLocation
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.location_on_outlined),
          label: const Text('Share my location for 1 hour'),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accepted Circle members',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              members.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Text('Members could not be loaded.'),
                data: (items) => items.isEmpty
                    ? const Text('No accepted members yet.')
                    : Column(
                        children: items
                            .map(
                              (member) => _MemberRow(
                                member: member,
                                circleId: widget.circleId,
                              ),
                            )
                            .toList(),
                      ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person_add_alt_1_rounded),
                ),
                title: const Text('Invite family member'),
                subtitle: const Text(
                  'Create a secure invitation for a registered account',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _InviteSheet(circleId: widget.circleId),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _EmergencyContacts(contacts: widget.contacts),
      ],
    );
  }
}

class _NoCircle extends ConsumerStatefulWidget {
  const _NoCircle({required this.contacts});
  final AsyncValue<List<EmergencyContact>> contacts;

  @override
  ConsumerState<_NoCircle> createState() => _NoCircleState();
}

class _NoCircleState extends ConsumerState<_NoCircle> {
  bool _creating = false;

  Future<void> _createCircle() async {
    setState(() => _creating = true);
    try {
      await ref.read(circleApiProvider).createCircle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your Family Circle is ready.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FamilyMessage(
          icon: Icons.group_add_outlined,
          title: 'No household Circle yet',
          message: 'Create or accept a secure invitation to start household check-ins.',
        ),
        FilledButton.icon(
          onPressed: _creating ? null : _createCircle,
          icon: _creating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.group_add_rounded),
          label: const Text('Create Family Circle'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _EmergencyContacts(contacts: widget.contacts),
      ],
    );
  }
}

class _EmergencyContacts extends StatelessWidget {
  const _EmergencyContacts({required this.contacts});
  final AsyncValue<List<EmergencyContact>> contacts;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency contacts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Contacts are not Circle members until they accept an invitation.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          contacts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const Text('Contacts could not be loaded.'),
            data: (items) => items.isEmpty
                ? const Text('No emergency contacts saved.')
                : Column(
                    children: items
                        .map(
                          (contact) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.contact_phone_rounded),
                            ),
                            title: Text(contact.name),
                            subtitle: Text(
                              '${contact.relationship} • ${contact.phoneNumber}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.circleId});
  final CircleMember member;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final detail = member.lastCheckInSafe == true
        ? 'Safe • last check-in recorded'
        : member.sharesLocation
        ? 'Location sharing enabled'
        : 'No recent check-in';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(
          member.displayName.trim().isEmpty
              ? '?'
              : member.displayName.characters.first,
        ),
      ),
      title: Text(member.displayName),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              FamilyMemberScreen(member: member, circleId: circleId),
        ),
      ),
    );
  }
}

class _FamilyMessage extends StatelessWidget {
  const _FamilyMessage({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InviteSheet extends ConsumerStatefulWidget {
  const _InviteSheet({required this.circleId});
  final String circleId;

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final _contact = TextEditingController();
  bool _creating = false;
  String? _inviteUrl;

  Future<void> _create() async {
    final contact = _contact.text.trim();
    if (contact.isEmpty) return;
    setState(() => _creating = true);
    try {
      final url = await ref
          .read(circleApiProvider)
          .createInvite(circleId: widget.circleId, contact: contact);
      if (!mounted) return;
      setState(() => _inviteUrl = url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _share(BuildContext buttonContext) async {
    final url = _inviteUrl;
    if (url == null) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Join my ResQ Family Circle',
        text: 'Join my household safety Circle in ResQ: $url',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  void dispose() {
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invite to Family Circle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'The secure link expires after 48 hours and requires a registered ResQ account.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (_inviteUrl == null) ...[
              TextField(
                controller: _contact,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _creating ? null : _create(),
                decoration: const InputDecoration(
                  labelText: 'Phone number or email',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _creating ? null : _create,
                icon: _creating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2_rounded),
                label: const Text('Create secure invitation'),
              ),
            ] else ...[
              Center(
                child: Semantics(
                  label: 'QR code for the ResQ Family Circle invitation',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.base),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: QrImageView(
                        data: _inviteUrl!,
                        size: 210,
                        semanticsLabel: 'ResQ Family Circle invitation QR code',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Ask your family member to scan this code, or share the secure link.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (buttonContext) => FilledButton.icon(
                  onPressed: () => _share(buttonContext),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share invitation link'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
