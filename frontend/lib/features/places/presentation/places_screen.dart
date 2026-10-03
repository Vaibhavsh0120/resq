import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../widgets/osm_map_attribution.dart';
import '../../../l10n/app_localizations.dart';
import '../application/places_providers.dart';
import '../domain/safe_place.dart';
import 'place_detail_screen.dart';

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final position = ref.watch(currentPositionProvider);
    return ListView(
      key: const PageStorageKey('places-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        ResQPageHeader(title: strings.places, subtitle: strings.placesSubtitle),
        const SizedBox(height: AppSpacing.xl),
        _MapSummary(
          hasError: position.hasError,
          latitude: position.value?.latitude,
          longitude: position.value?.longitude,
        ),
        const SizedBox(height: AppSpacing.lg),
        position.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PlacesMessage(
            icon: Icons.location_off_rounded,
            title: strings.locationUnavailable,
            message: error is LocationUnavailable
                ? error.message == 'services_off'
                      ? strings.locationServicesOff
                      : strings.locationPermissionNeeded
                : strings.checkConnectionRetry,
            onRetry: () => ref.invalidate(currentPositionProvider),
          ),
          data: (value) {
            final places = ref.watch(
              nearbyPlacesProvider((
                latitude: value.latitude,
                longitude: value.longitude,
              )),
            );
            return places.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _PlacesMessage(
                icon: Icons.cloud_off_rounded,
                title: strings.safePlacesUnavailable,
                message: strings.checkConnectionRetry,
                onRetry: () => ref.invalidate(
                  nearbyPlacesProvider((
                    latitude: value.latitude,
                    longitude: value.longitude,
                  )),
                ),
              ),
              data: (feed) => feed.items.isEmpty
                  ? _PlacesMessage(
                      icon: Icons.search_off_rounded,
                      title: strings.noVerifiedPlaces,
                      message: feed.limited
                          ? strings.placeCoverageLimited
                          : strings.placeCoverageIncomplete,
                    )
                  : Column(
                      children: [
                        if (feed.limited) Text(strings.placePartialResults),
                        for (
                          var index = 0;
                          index < feed.items.length;
                          index++
                        ) ...[
                          _PlaceCard(
                            place: feed.items[index],
                            distanceKm: feed.items[index].distanceKmFrom(
                              value.latitude,
                              value.longitude,
                            ),
                          ),
                          if (index != feed.items.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({
    required this.hasError,
    required this.latitude,
    required this.longitude,
  });
  final bool hasError;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: latitude != null && longitude != null
          ? OsmCreditedMap(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude!, longitude!),
                  initialZoom: 13,
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
                        point: LatLng(latitude!, longitude!),
                        width: 44,
                        height: 44,
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.emergency,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasError ? Icons.location_off_rounded : Icons.map_rounded,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasError
                        ? strings.locationNeededMap
                        : strings.findingPlaces,
                  ),
                ],
              ),
            ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.distanceKm});
  final SafePlace place;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    final details = place.facilities
        .map((item) => item.replaceAll('_', ' '))
        .join(' • ');
    return AppSectionCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const AppIconTile(icon: Icons.shield_rounded),
        title: Text(place.name),
        subtitle: Text('${distanceKm.toStringAsFixed(1)} km\n$details'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PlaceDetailScreen(
              place: place,
              distance: '${distanceKm.toStringAsFixed(1)} km',
            ),
          ),
        ),
      ),
    );
  }
}

class _PlacesMessage extends StatelessWidget {
  const _PlacesMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}
