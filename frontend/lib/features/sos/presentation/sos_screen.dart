import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Timer? _timer;
  int? _seconds;
  bool _activated = false;

  void _start() {
    if (_timer != null || _activated) return;
    setState(() => _seconds = 5);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = (_seconds ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        _timer = null;
        setState(() {
          _seconds = null;
          _activated = true;
        });
      } else {
        setState(() => _seconds = next);
      }
    });
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
                            : _seconds != null
                            ? 'Sending SOS in $_seconds'
                            : 'Press and hold for SOS',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _activated
                            ? 'Your event has been recorded. Call 112 if you need immediate help.'
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
                else if (!_activated)
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
                          'PRESS AND HOLD',
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
                  onPressed: () {},
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call 112'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
