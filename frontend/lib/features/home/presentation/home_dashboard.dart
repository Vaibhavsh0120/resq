import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/shell/adaptive_app_shell.dart';
import '../../assistant/presentation/assistant_chat_screen.dart';
import '../../assistant/presentation/assistant_voice_screen.dart';
import '../../readiness/presentation/readiness_screen.dart';
import '../../readiness/application/readiness_providers.dart';
import '../../sos/presentation/sos_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key, required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = isGuest ? null : ref.watch(currentUserIdProvider);
    final readiness = !isGuest && uid != null
        ? ref.watch(readinessItemsProvider(uid)).value
        : null;
    final readinessComplete =
        readiness?.where((item) => item.completed).length ?? 0;
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ResQPageHeader(
                      title: 'Home',
                      subtitle: 'Your safety tools in one place',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isGuest
                          ? 'Emergency access is ready'
                          : 'Good to see you safe',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(72),
                        backgroundColor: AppColors.emergency,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SosScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.sos_rounded, size: 30),
                      label: const Text('Emergency SOS'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSectionCard(
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReadinessScreen(isGuest: isGuest),
                          ),
                        ),
                        child: Row(
                          children: [
                            const AppIconTile(icon: Icons.fact_check_rounded),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your readiness plan',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isGuest
                                        ? 'Sign in to save your emergency plan.'
                                        : readiness == null
                                        ? 'Loading your saved plan…'
                                        : '$readinessComplete of ${readiness.length} essentials completed',
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSectionCard(
                      color: Theme.of(context).colorScheme.secondary
                          .withValues(alpha: .08),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ask ResQ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.base,
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const AssistantChatScreen(),
                                    ),
                                  ),
                                  child: const InputDecorator(
                                    decoration: InputDecoration(
                                      hintText: 'How can I help you prepare?',
                                      prefixIcon: Icon(
                                        Icons.auto_awesome_rounded,
                                      ),
                                    ),
                                    child: SizedBox(height: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton.filled(
                                tooltip: 'Start voice assistant',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const AssistantVoiceScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.mic_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
