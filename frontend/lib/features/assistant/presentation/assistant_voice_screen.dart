import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class AssistantVoiceScreen extends StatelessWidget {
  const AssistantVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice assistant'),
        actions: [
          IconButton(
            tooltip: 'Switch to keyboard',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.keyboard_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary
                      .withValues(alpha: .14),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Listening…',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Speak naturally. You can interrupt ResQ at any time.',
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: () {},
                    tooltip: 'Mute microphone',
                    icon: const Icon(Icons.mic_off_rounded),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  IconButton.filled(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'End voice session',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
