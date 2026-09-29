import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';
import '../application/alerts_providers.dart';
import '../data/alerts_repository.dart';
import '../domain/public_alert.dart';

class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final alerts = ref.watch(activeAlertsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeAlertsProvider);
        await ref.read(activeAlertsProvider.future);
      },
      child: ListView(
        key: const PageStorageKey('updates-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          ResQPageHeader(
            title: strings.updates,
            subtitle: strings.updatesSubtitle,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            strings.homeAlertRegion,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          alerts.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _FeedMessage(
              icon: Icons.cloud_off_rounded,
              title: strings.updatesUnavailable,
              message: strings.updatesRetry,
            ),
            data: (feed) => Column(
              children: [
                _FeedStatus(feed: feed),
                const SizedBox(height: AppSpacing.lg),
                if (feed.items.isEmpty)
                  _FeedMessage(
                    icon: Icons.info_outline_rounded,
                    title: feed.coverage == 'home_region_missing'
                        ? strings.setHomeLocation
                        : strings.noMatchingAlerts,
                    message: feed.coverage == 'home_region_missing'
                        ? strings.addDistrictState
                        : strings.noAlertsSafetyNotice,
                  )
                else
                  for (var index = 0; index < feed.items.length; index++) ...[
                    _AlertCard(alert: feed.items[index]),
                    if (index != feed.items.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedStatus extends StatelessWidget {
  const _FeedStatus({required this.feed});
  final AlertFeed feed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final stale = feed.sources.any(
      (source) =>
          source.lastCheckedAt == null ||
          DateTime.now().difference(source.lastCheckedAt!).inMinutes > 90 ||
          source.status != 'ok' ||
          source.truncated,
    );
    final checked = feed.sources
        .map((source) => source.status == 'ok' && source.lastCheckedAt != null
            ? '${source.source}: ${_relativeIssued(strings, source.lastCheckedAt!)}'
            : strings.sourceUnavailable(source.source, _sourceStatus(strings, source.status)))
        .join(' • ');
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stale ? strings.feedDelayed : strings.feedChecked,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(checked.isEmpty ? strings.noFeedRefresh : checked),
          if (feed.coverage == 'limited') Text(strings.alertViewLimited),
          TextButton(
            onPressed: () =>
                launchUrl(Uri.parse('https://sachet.ndma.gov.in/')),
            child: Text(strings.openSachet),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final PublicAlert alert;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final severe = {
      'critical',
      'extreme',
      'severe',
    }.contains(alert.severity.toLowerCase());
    return AppSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: severe ? Icons.warning_rounded : Icons.info_rounded,
            color: severe ? AppColors.emergency : AppColors.gold,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.titleFor(language),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (alert.area != null) ...[
                  const SizedBox(height: 4),
                  Text(alert.area!),
                ],
                if (alert.summaryFor(language).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(alert.summaryFor(language)),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${alert.severity.toUpperCase()} • ${alert.source} • ${_relativeIssued(AppLocalizations.of(context), alert.issuedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).alertValidFor(_remaining(AppLocalizations.of(context), alert.expiresAt)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

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
        ],
      ),
    );
  }
}

String _relativeIssued(AppLocalizations strings, DateTime issuedAt) {
  final difference = DateTime.now().difference(issuedAt);
  if (difference.inMinutes < 60) {
    return strings.minutesAgo(difference.inMinutes.clamp(0, 59));
  }
  if (difference.inHours < 24) return strings.hoursAgo(difference.inHours);
  return strings.daysAgo(difference.inDays);
}

String _remaining(AppLocalizations strings, DateTime expiresAt) {
  final difference = expiresAt.difference(DateTime.now());
  if (difference.isNegative) return strings.expired;
  if (difference.inMinutes < 60) {
    return strings.durationMinutes(difference.inMinutes.clamp(1, 59));
  }
  if (difference.inHours < 24) return strings.durationHours(difference.inHours);
  return strings.durationDays(difference.inDays);
}

String _sourceStatus(AppLocalizations strings, String status) => switch (status) {
  'unconfigured' => strings.sourceNotConfigured,
  'error' => strings.sourceRefreshFailed,
  'partial' => strings.sourceCoveragePartial,
  _ => strings.sourceNotChecked,
};
