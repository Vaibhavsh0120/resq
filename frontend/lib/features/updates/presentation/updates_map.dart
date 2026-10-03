import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/osm_map_attribution.dart';
import '../domain/india_event.dart';

class UpdatesMap extends StatelessWidget {
  const UpdatesMap({
    super.key,
    required this.isNearby,
    this.homeLatitude,
    this.homeLongitude,
    this.nearbyCount = 0,
    this.events = const [],
    this.onNearbyTap,
    this.onEventTap,
  });

  final bool isNearby;
  final double? homeLatitude;
  final double? homeLongitude;
  final int nearbyCount;
  final List<IndiaEvent> events;
  final VoidCallback? onNearbyTap;
  final ValueChanged<IndiaEvent>? onEventTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final hasHome = homeLatitude != null && homeLongitude != null;
    final center = isNearby && hasHome
        ? LatLng(homeLatitude!, homeLongitude!)
        : const LatLng(21.5, 79.0);
    final markers = <Marker>[
      if (isNearby && hasHome)
        Marker(
          point: center,
          width: 64,
          height: 64,
          child: Semantics(
            label: '${strings.homeCoverageMarker}: $nearbyCount',
            button: true,
            child: Tooltip(
              message: '${strings.homeCoverageMarker}: $nearbyCount',
              child: Material(
                color: AppColors.accent,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  key: const ValueKey('nearby-coverage-marker'),
                  customBorder: const CircleBorder(),
                  onTap: onNearbyTap,
                  child: Center(
                    child: Text(
                      '$nearbyCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      if (!isNearby)
        for (final event in events)
          Marker(
            point: LatLng(event.latitude, event.longitude),
            width: 50,
            height: 50,
            child: Semantics(
              label: event.title,
              button: true,
              child: Tooltip(
                message: event.title,
                child: Material(
                  color: AppColors.emergency,
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: InkWell(
                    key: ValueKey('india-event-${event.id}'),
                    customBorder: const CircleBorder(),
                    onTap: () => onEventTap?.call(event),
                    child: const Icon(
                      Icons.crisis_alert_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
    ];
    return Container(
      height: wide ? 320 : 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: isNearby && !hasHome
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  strings.noHomeMapPoint,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : OsmCreditedMap(
              child: FlutterMap(
                key: ValueKey(isNearby ? 'nearby-map' : 'india-map'),
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: isNearby ? 9 : 4,
                  interactionOptions: InteractionOptions(
                    flags: wide
                        ? InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom
                        : InteractiveFlag.pinchZoom |
                              InteractiveFlag.pinchMove |
                              InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.vaibhav.resq',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
    );
  }
}
