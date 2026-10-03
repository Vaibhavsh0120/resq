import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../widgets/osm_map_attribution.dart';
import '../domain/safe_place.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.place,
    required this.distance,
  });

  final SafePlace place;
  final String distance;

  Future<void> _launch(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No compatible app is available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe place')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            clipBehavior: Clip.antiAlias,
            child: OsmCreditedMap(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(place.latitude, place.longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vaibhav.resq',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(place.latitude, place.longitude),
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.emergency,
                          size: 44,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(place.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('$distance • ${place.type.replaceAll('_', ' ')}'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                place.verified ? Icons.verified_rounded : Icons.info_outline,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  place.verified
                      ? 'Verified${place.verifiedAt == null ? '' : ' • checked ${_date(place.verifiedAt!)}'}'
                      : 'Verification pending',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () => _launch(
              context,
              Uri.https('www.google.com', '/maps/dir/', {
                'api': '1',
                'destination': '${place.latitude},${place.longitude}',
              }),
            ),
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Directions'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: place.phone == null || place.phone!.trim().isEmpty
                ? null
                : () => _launch(context, Uri(scheme: 'tel', path: place.phone)),
            icon: const Icon(Icons.call_rounded),
            label: const Text('Call place'),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.medical_services_rounded),
              title: const Text('Available facilities'),
              subtitle: Text(
                place.facilities.isEmpty
                    ? 'No facility details available'
                    : place.facilities
                          .map((item) => item.replaceAll('_', ' '))
                          .join(' • '),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
