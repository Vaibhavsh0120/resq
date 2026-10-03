import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../models/user_profile.dart';
import '../../data/country_subdivisions.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/osm_map_attribution.dart';
import '../../widgets/primary_button.dart';

/// Onboarding Step 4 — Home Location.
///
/// Captures coordinates for map coverage and nearby help, plus an address the
/// user can read aloud when requesting assistance.
///
/// Map: `flutter_map` rendering free OpenStreetMap raster tiles — no API
/// key, no billing account, just a `userAgentPackageName` per OSM's usage
/// policy. See `frontend/docs/architecture.md` for the service boundaries.
class HomeLocationStep extends StatefulWidget {
  const HomeLocationStep({
    super.key,
    required this.initialValue,
    required this.countryCode,
    required this.onChanged,
  });

  final HomeLocation initialValue;
  final String countryCode;
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
  bool _permissionPermanentlyDenied = false;

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
              'Location is off. You can still enter your address manually.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(
          () => _locationError =
              'Location permission was denied. Enter your address manually, '
              'or try location again whenever you are ready.',
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionPermanentlyDenied = true;
          _locationError =
              'Location permission is off. Manual address entry still '
              'works, or you can enable location in system settings.';
        });
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
        _permissionPermanentlyDenied = false;
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
        const AppIllustration(
          'assets/illustrations/home_location.png',
          height: 150,
        ),
        const SizedBox(height: AppSpacing.md),
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
                OsmCreditedMap(
                  child: FlutterMap(
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
                    ],
                  ),
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
        if (_permissionPermanentlyDenied)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: Geolocator.openAppSettings,
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Open location settings'),
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
              child: _StateSuggestionField(
                controller: _stateController,
                countryCode: widget.countryCode,
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

class _StateSuggestionField extends StatelessWidget {
  const _StateSuggestionField({
    required this.controller,
    required this.countryCode,
  });

  final TextEditingController controller;
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final suggestions = countrySubdivisions[countryCode] ?? const <String>[];
    if (suggestions.isEmpty) {
      return AppTextField(
        label: 'State / region',
        controller: controller,
        textInputAction: TextInputAction.next,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State / region', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => DropdownMenu<String>(
            key: ValueKey('state-suggestions-$countryCode'),
            controller: controller,
            width: constraints.maxWidth,
            enableFilter: true,
            enableSearch: true,
            requestFocusOnTap: true,
            hintText: 'Type or select',
            dropdownMenuEntries: suggestions
                .map((state) => DropdownMenuEntry(value: state, label: state))
                .toList(),
            onSelected: (state) {
              if (state != null) controller.text = state;
            },
          ),
        ),
      ],
    );
  }
}
