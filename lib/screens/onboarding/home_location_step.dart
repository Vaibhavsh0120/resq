import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Onboarding Step 4 — Home Location.
///
/// Captures both GPS coordinates (for a future mini-map / distance-to-help
/// feature) and a human-written address (for anyone who has to read it
/// aloud or dispatch help to it) — the two aren't redundant, they serve
/// different future features.
///
/// Map: `flutter_map` rendering free OpenStreetMap raster tiles — no API
/// key, no billing account, just a `userAgentPackageName` per OSM's usage
/// policy (see `docs/architecture.md` for why this was chosen over Google
/// Maps / Mapbox).
class HomeLocationStep extends StatefulWidget {
  const HomeLocationStep({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final HomeLocation initialValue;
  final ValueChanged<HomeLocation> onChanged;

  @override
  State<HomeLocationStep> createState() => _HomeLocationStepState();
}

class _HomeLocationStepState extends State<HomeLocationStep> {
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _landmarkController;
  late final MapController _mapController;

  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  String? _locationError;

  static const _defaultCenter = latlong.LatLng(20.5937, 78.9629); // India

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.initialValue.addressLine ?? '',
    );
    _cityController = TextEditingController(
      text: widget.initialValue.city ?? '',
    );
    _stateController = TextEditingController(
      text: widget.initialValue.state ?? '',
    );
    _landmarkController = TextEditingController(
      text: widget.initialValue.landmark ?? '',
    );
    _latitude = widget.initialValue.latitude;
    _longitude = widget.initialValue.longitude;
    _mapController = MapController();

    _addressController.addListener(_emit);
    _cityController.addListener(_emit);
    _stateController.addListener(_emit);
    _landmarkController.addListener(_emit);

    // If we already have coordinates from a previous session, don't
    // re-prompt for GPS — just show them. Otherwise, ask right away since
    // this step exists specifically to capture location.
    if (!widget.initialValue.hasCoordinates) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _detectLocation());
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      HomeLocation(
        latitude: _latitude,
        longitude: _longitude,
        addressLine: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        landmark: _landmarkController.text,
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(
          () => _locationError =
              'Location services are turned off on this device.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() => _locationError = 'Location permission was denied.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _locationError =
              'Location permission is permanently denied. Enable it in '
              'system settings to auto-fill your coordinates.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      HapticFeedback.mediumImpact();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _emit();
      _mapController.move(
        latlong.LatLng(position.latitude, position.longitude),
        16,
      );
    } catch (_) {
      setState(
        () => _locationError = 'Could not get your location. Try again.',
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasCoords = _latitude != null && _longitude != null;
    final center = hasCoords
        ? latlong.LatLng(_latitude!, _longitude!)
        : _defaultCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('GPS location', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: hasCoords ? 16 : 4,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vaibhav.resq',
                      maxZoom: 19,
                    ),
                    if (hasCoords)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.error,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                if (!hasCoords && !_isLocating)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor
                          .withValues(alpha: 0.55),
                      child: const Center(
                        child: Icon(Icons.location_searching, size: 28),
                      ),
                    ),
                  ),
                if (_isLocating)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor
                          .withValues(alpha: 0.6),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _locationError!,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        SecondaryButton(
          label: hasCoords ? 'Update my location' : 'Use my current location',
          isLoading: _isLocating,
          onPressed: _isLocating ? null : _detectLocation,
          icon: const Icon(Icons.my_location, size: 18),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Address',
          controller: _addressController,
          hintText: 'Street, building, apartment/unit',
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.home_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'City',
                controller: _cityController,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'State',
                controller: _stateController,
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Nearest landmark (optional)',
          controller: _landmarkController,
          hintText: 'e.g. Near City Hospital',
          textInputAction: TextInputAction.done,
          prefixIcon: Icons.place_outlined,
        ),
      ],
    );
  }
}
