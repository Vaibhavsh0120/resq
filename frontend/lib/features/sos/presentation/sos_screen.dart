import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';
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
  String _deliveryMessage = '';
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
    final strings = AppLocalizations.of(context);
    setState(() {
      _activated = true;
      _activating = true;
      _deliveryMessage = strings.sosRecording;
    });
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

    var saved = false;
    var deliveryMessage = strings.sosUnconfirmedHelp;
    try {
      final event = await ref
          .read(sosRepositoryProvider)
          .activate(latitude: _latitude, longitude: _longitude);
      saved = true;
      if (event.deliveryStatus == 'no_recipients') {
        deliveryMessage = strings.sosNoRecipients;
      } else {
        deliveryMessage = strings.sosDeliveryPending;
        try {
          final status = await ref.read(sosApiProvider).fanOut(event.id);
          if (status == 'inbox_delivered') {
            deliveryMessage = strings.sosInboxesRecorded;
          } else if (status == 'no_recipients') {
            deliveryMessage = strings.sosNoRecipients;
          }
        } catch (_) {
          // The event remains pending for an operator's manual backend retry.
        }
      }
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _activating = false;
      _saved = saved;
      _deliveryMessage = deliveryMessage;
    });
  }

  Future<void> _callEmergency() => _launch(Uri(scheme: 'tel', path: '112'));

  Future<void> _shareBySms() {
    final strings = AppLocalizations.of(context);
    final location = _latitude == null || _longitude == null
        ? ''
        : ' ${strings.sosMyLocation} https://maps.google.com/?q=$_latitude,$_longitude';
    final query =
        'body=${Uri.encodeComponent('${strings.sosSmsBody}$location')}';
    return _launch(Uri(scheme: 'sms', query: query));
  }

  Future<void> _launch(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).phoneAppUnavailable),
        ),
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
    final strings = AppLocalizations.of(context);
    return PopScope(
      canPop: _seconds == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _seconds != null) {
          _cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.sosCountdownCancelled)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.sosTitle)),
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
                        _saved ? Icons.check_circle_rounded : Icons.sos_rounded,
                        size: 72,
                        color: AppColors.emergency,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _activating
                            ? strings.sosSending
                            : _activated
                            ? _saved
                                  ? strings.sosRecorded
                                  : strings.sosDigitalUnconfirmed
                            : _seconds != null
                            ? '${strings.sosCountdown} $_seconds'
                            : strings.sosActivate,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _activated ? _deliveryMessage : strings.sosCancelNotice,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_seconds != null)
                  OutlinedButton(
                    onPressed: _cancel,
                    child: Text(strings.sosCancel),
                  )
                else if (!_activated && !_activating)
                  InkWell(
                    onTap: _start,
                    onLongPress: _start,
                    child: Semantics(
                      button: true,
                      label: strings.sosActivate,
                      child: Container(
                        height: 84,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.emergency,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Text(
                          strings.sosActivate,
                          style: const TextStyle(
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
                  label: Text(strings.call112),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _shareBySms,
                  icon: const Icon(Icons.sms_rounded),
                  label: Text(strings.sosSmsHelp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
