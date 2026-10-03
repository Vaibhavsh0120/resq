import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../widgets/osm_map_attribution.dart';
import '../domain/family_models.dart';
import '../data/family_repository.dart';

class FamilyMemberScreen extends StatelessWidget {
  const FamilyMemberScreen({
    super.key,
    required this.member,
    required this.circleId,
  });

  final CircleMember member;
  final String circleId;

  Future<void> _openDeviceAction(BuildContext context, String scheme) async {
    final opened = await launchUrl(
      Uri(scheme: scheme, path: member.phoneNumber),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No app is available to $scheme this contact.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(member.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              member.displayName.trim().isEmpty
                  ? '?'
                  : member.displayName.characters.first,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            member.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            member.lastCheckInSafe == true
                ? 'Checked in safe'
                : 'No recent safe check-in',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Action(
                icon: Icons.call_rounded,
                label: 'Call',
                onTap: member.phoneNumber.isEmpty
                    ? null
                    : () => _openDeviceAction(context, 'tel'),
              ),
              _Action(
                icon: Icons.message_rounded,
                label: 'Message',
                onTap: member.phoneNumber.isEmpty
                    ? null
                    : () => _openDeviceAction(context, 'sms'),
              ),
              _Action(
                icon: Icons.location_on_rounded,
                label: 'Locate',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('The latest active share is shown below.'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last shared location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                StreamBuilder<LocationShare?>(
                  stream: FirestoreFamilyRepository(FirebaseFirestore.instance)
                      .watchActiveLocation(
                        circleId: circleId,
                        memberId: member.uid,
                      ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 180,
                        child: Center(
                          child: Text('No active location share is available.'),
                        ),
                      );
                    }
                    final share = snapshot.data!;
                    final point = LatLng(share.latitude, share.longitude);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.base),
                          child: SizedBox(
                            height: 180,
                            child: OsmCreditedMap(
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: point,
                                  initialZoom: 14,
                                  interactionOptions: const InteractionOptions(
                                    flags:
                                        InteractiveFlag.pinchZoom |
                                        InteractiveFlag.drag,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.vaibhav.resq',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: point,
                                        width: 48,
                                        height: 48,
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          size: 42,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Expires ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(share.expiresAt.toLocal()))}',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                member.lastCheckInSafe == true
                    ? Icons.check_circle_rounded
                    : Icons.history_rounded,
              ),
              title: Text(
                member.lastCheckInSafe == true
                    ? 'Safe check-in'
                    : 'No safe check-in recorded',
              ),
              subtitle: Text(
                member.lastCheckInAt == null
                    ? 'Check-in history will appear here.'
                    : 'Last update: ${member.lastCheckInAt}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
          Text(label),
        ],
      ),
    );
  }
}
