import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../application/places_providers.dart';
import '../domain/safe_place.dart';
import 'place_detail_screen.dart';

class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(currentPositionProvider);
    return ListView(
      key: const PageStorageKey('places-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        const ResQPageHeader(
          title: 'Places',
          subtitle: 'Verified safe places within 5 km',
        ),
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
            title: 'Location is unavailable',
            message: error.toString(),
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
                title: 'Safe places are unavailable',
                message: 'Check your connection and try again.',
                onRetry: () => ref.invalidate(
                  nearbyPlacesProvider((
                    latitude: value.latitude,
                    longitude: value.longitude,
                  )),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _PlacesMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No verified places within 5 km',
                      message: 'Emergency calling remains available from Home.',
                    )
                  : Column(
                      children: [
                        for (var index = 0; index < items.length; index++) ...[
                          _PlaceCard(
                            place: items[index],
                            distanceKm: items[index].distanceKmFrom(
                              value.latitude,
                              value.longitude,
                            ),
                          ),
                          if (index != items.length - 1)
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
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: latitude != null && longitude != null
          ? FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude!, longitude!),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'app.resq.safety',
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
                        ? 'Location needed for the map'
                        : 'Finding nearby safe places…',
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
              name: place.name,
              detail: details.isEmpty ? place.type : details,
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
