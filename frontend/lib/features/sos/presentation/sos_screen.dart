import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../application/sos_providers.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  Timer? _timer;
  int? _seconds;
  bool _activated = false;
  bool _activating = false;
  bool _saved = false;
  double? _latitude;
  double? _longitude;

  void _start() {
    if (_timer != null || _activated) return;
    setState(() => _seconds = 5);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = (_seconds ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        _timer = null;
        setState(() => _seconds = null);
        _activate();
      } else {
        setState(() => _seconds = next);
      }
    });
  }

  Future<void> _activate() async {
    if (_activating || _activated) return;
    setState(() => _activating = true);
    Position? position;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        position = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 8),
        );
      }
    } catch (_) {
      position = null;
    }
    _latitude = position?.latitude;
    _longitude = position?.longitude;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    var saved = false;
    if (userId != null) {
      try {
        final eventId = await ref
            .read(sosRepositoryProvider)
            .activate(
              ownerId: userId,
              latitude: _latitude,
              longitude: _longitude,
            );
        saved = true;
        try {
          await ref.read(sosApiProvider).fanOut(eventId);
        } catch (_) {
          // The durable SOS event remains pending for backend retry.
        }
      } catch (_) {
        saved = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _activating = false;
      _activated = true;
      _saved = saved;
    });
  }

  Future<void> _callEmergency() => _launch(Uri(scheme: 'tel', path: '112'));

  Future<void> _shareBySms() {
    final location = _latitude == null || _longitude == null
        ? ''
        : ' My location: https://maps.google.com/?q=$_latitude,$_longitude';
    final query =
        'body=${Uri.encodeComponent('I need emergency help.$location')}';
    return _launch(Uri(scheme: 'sms', query: query));
  }

  Future<void> _launch(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No compatible phone app is available.')),
      );
    }
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    setState(() => _seconds = null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _seconds == null,
      child: Scaffold(
        appBar: AppBar(title: const Text('Emergency SOS')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionCard(
                  color: AppColors.emergency.withValues(alpha: .10),
                  child: Column(
                    children: [
                      Icon(
                        _activated
                            ? Icons.check_circle_rounded
                            : Icons.sos_rounded,
                        size: 72,
                        color: AppColors.emergency,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _activated
                            ? 'SOS activated'
                            : _activating
                            ? 'Activating SOS'
                            : _seconds != null
                            ? 'Sending SOS in $_seconds'
                            : 'Hold to activate SOS',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _activated
                            ? _saved
                                  ? 'Your SOS event was recorded. Call 112 if you need immediate help.'
                                  : 'ResQ could not confirm the online record. Calling 112 and SMS sharing are still available.'
                            : 'You will have five seconds to cancel before ResQ records the event.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_seconds != null)
                  OutlinedButton(
                    onPressed: _cancel,
                    child: const Text('Cancel SOS'),
                  )
                else if (!_activated && !_activating)
                  GestureDetector(
                    onLongPress: _start,
                    child: Semantics(
                      button: true,
                      label: 'Press and hold to activate emergency SOS',
                      child: Container(
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.emergency,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const Text(
                          'Hold to activate SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _callEmergency,
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call 112'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _activated ? _shareBySms : null,
                  icon: const Icon(Icons.sms_rounded),
                  label: const Text('Share SOS by SMS'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
