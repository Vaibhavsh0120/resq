import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../app/shell/adaptive_app_shell.dart';
import '../../readiness/application/readiness_providers.dart';
import '../../updates/application/alerts_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key, required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final uid = isGuest ? null : ref.watch(currentUserIdProvider);
    final readiness = !isGuest && uid != null
        ? ref.watch(readinessItemsProvider(uid)).value
        : null;
    final readinessComplete =
        readiness?.where((item) => item.completed).length ?? 0;
    final activeAlerts = ref.watch(activeAlertsProvider).value ?? const [];
    final activeAlert = activeAlerts.isEmpty ? null : activeAlerts.first;
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
                    ResQPageHeader(
                      title: strings.home,
                      subtitle: strings.homeSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isGuest
                          ? strings.emergencyAccessReady
                          : strings.goodToSeeYouSafe,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(72),
                        backgroundColor: AppColors.emergency,
                      ),
                      onPressed: () => context.push('/sos'),
                      icon: const Icon(Icons.sos_rounded, size: 30),
                      label: Text(strings.emergencySos),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (activeAlert != null) ...[
                      AppSectionCard(
                        color: AppColors.emergency.withValues(alpha: .08),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppIconTile(
                              icon: Icons.warning_amber_rounded,
                              color: AppColors.emergency,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.activeVerifiedAlert,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    activeAlert.titleFor(
                                      Localizations.localeOf(context)
                                          .languageCode,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  if (activeAlert.area != null)
                                    Text(activeAlert.area!),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${activeAlert.source} • ${activeAlert.severity.toUpperCase()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    AppSectionCard(
                      child: InkWell(
                        onTap: () => context.push('/readiness'),
                        child: Row(
                          children: [
                            const AppIconTile(icon: Icons.fact_check_rounded),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.yourReadinessPlan,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isGuest
                                        ? strings.signInSavePlan
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
                            strings.askResq,
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
                                  onTap: () => context.push('/assistant/chat'),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      hintText: strings.assistantPrompt,
                                      prefixIcon: const Icon(
                                        Icons.auto_awesome_rounded,
                                      ),
                                    ),
                                    child: SizedBox(height: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              IconButton.filled(
                                tooltip: strings.startVoiceAssistant,
                                onPressed: () =>
                                    context.push('/assistant/voice'),
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
