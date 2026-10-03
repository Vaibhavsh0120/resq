import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/auth_service.dart';
import '../application/alerts_providers.dart';
import '../application/india_events_providers.dart';
import '../data/alerts_repository.dart';
import '../data/india_events_repository.dart';
import '../domain/india_event.dart';
import '../domain/public_alert.dart';
import 'updates_map.dart';

enum _UpdatesView { nearby, india }

class UpdatesScreen extends ConsumerStatefulWidget {
  const UpdatesScreen({super.key, this.isActive = true, this.isGuest = false});

  final bool isActive;
  final bool isGuest;

  @override
  ConsumerState<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends ConsumerState<UpdatesScreen> {
  _UpdatesView _view = _UpdatesView.nearby;

  @override
  void didUpdateWidget(covariant UpdatesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      ref.invalidate(activeAlertsProvider);
      ref.invalidate(indiaEventsProvider);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(activeAlertsProvider);
    ref.invalidate(indiaEventsProvider);
    try {
      await ref.read(activeAlertsProvider.future);
    } catch (_) {
      /* The view renders this feed's error. */
    }
    try {
      await ref.read(indiaEventsProvider.future);
    } catch (_) {
      /* The other feed remains independent. */
    }
  }

  void _showNearbyDetails(AlertFeed feed) {
    final strings = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.homeCoverageMarker,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(strings.homeCoverageExplanation),
              const SizedBox(height: AppSpacing.md),
              Text(
                feed.items.isEmpty
                    ? strings.noMatchingAlerts
                    : feed.items
                          .map(
                            (item) => item.titleFor(
                              Localizations.localeOf(context).languageCode,
                            ),
                          )
                          .take(5)
                          .join(' • '),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIndiaEvent(IndiaEvent event) {
    final strings = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${event.countryLabel} • GDACS • ${_relativeIssued(strings, event.updatedAt)}',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(strings.indiaEventNotLocalWarning),
              const SizedBox(height: AppSpacing.md),
              TextButton.icon(
                onPressed: () => launchUrl(event.sourceUrl),
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(strings.openGdacsReport),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final alerts = ref.watch(activeAlertsProvider);
    final indiaEvents = ref.watch(indiaEventsProvider);
    return RefreshIndicator(
      onRefresh: _refresh,
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
          SegmentedButton<_UpdatesView>(
            segments: [
              ButtonSegment(
                value: _UpdatesView.nearby,
                label: Text(strings.nearbyUpdates),
              ),
              ButtonSegment(
                value: _UpdatesView.india,
                label: Text(strings.acrossIndia),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (selected) =>
                setState(() => _view = selected.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _view == _UpdatesView.nearby
                ? strings.homeAlertRegion
                : strings.indiaDisasterEvents,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_view == _UpdatesView.nearby)
            alerts.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Column(
                children: [
                  const UpdatesMap(isNearby: true),
                  _FeedMessage(
                    icon: Icons.cloud_off_rounded,
                    title: strings.updatesUnavailable,
                    message: strings.updatesRetry,
                  ),
                ],
              ),
              data: (feed) => Column(
                children: [
                  UpdatesMap(
                    isNearby: true,
                    homeLatitude: feed.homeLatitude,
                    homeLongitude: feed.homeLongitude,
                    nearbyCount: feed.items.length,
                    onNearbyTap: () => _showNearbyDetails(feed),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FeedStatus(feed: feed),
                  const SizedBox(height: AppSpacing.lg),
                  if (feed.items.isEmpty)
                    _FeedMessage(
                      icon: Icons.info_outline_rounded,
                      title: feed.coverage == 'home_region_missing'
                          ? strings.setHomeLocation
                          : strings.noMatchingAlerts,
                      message: feed.coverage == 'home_region_missing'
                          ? widget.isGuest
                                ? strings.signInEditInformation
                                : strings.addDistrictState
                          : strings.noAlertsSafetyNotice,
                      action: feed.coverage == 'home_region_missing'
                          ? FilledButton(
                              onPressed: () async {
                                if (widget.isGuest) {
                                  await AuthService.instance.signOut();
                                  if (context.mounted) context.go('/');
                                } else {
                                  context.push('/profile/information');
                                }
                              },
                              child: Text(
                                widget.isGuest
                                    ? strings.signInForUpdates
                                    : strings.setHomeLocation,
                              ),
                            )
                          : null,
                    )
                  else
                    for (var index = 0; index < feed.items.length; index++) ...[
                      _AlertCard(alert: feed.items[index]),
                      if (index != feed.items.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                ],
              ),
            )
          else
            indiaEvents.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Column(
                children: [
                  const UpdatesMap(isNearby: false),
                  _FeedMessage(
                    icon: Icons.cloud_off_rounded,
                    title: strings.indiaUpdatesUnavailable,
                    message: strings.updatesRetry,
                  ),
                ],
              ),
              data: (feed) => Column(
                children: [
                  UpdatesMap(
                    isNearby: false,
                    events: feed.items,
                    onEventTap: _showIndiaEvent,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _IndiaFeedStatus(feed: feed),
                  const SizedBox(height: AppSpacing.md),
                  if (feed.items.isEmpty)
                    _FeedMessage(
                      icon: Icons.public_rounded,
                      title: strings.noIndiaEvents,
                      message: strings.indiaEventNotLocalWarning,
                    )
                  else
                    for (var index = 0; index < feed.items.length; index++) ...[
                      _IndiaEventCard(
                        event: feed.items[index],
                        onTap: () => _showIndiaEvent(feed.items[index]),
                      ),
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
    final stale = feed.sources
        .where((source) => source.status != 'unconfigured')
        .any(
          (source) =>
              source.lastCheckedAt == null ||
              DateTime.now().difference(source.lastCheckedAt!).inMinutes > 90 ||
              source.status != 'ok' ||
              source.truncated,
        );
    final checked = feed.sources
        .map(
          (source) => source.status == 'ok' && source.lastCheckedAt != null
              ? '${source.source}: ${_relativeIssued(strings, source.lastCheckedAt!)}'
              : strings.sourceUnavailable(
                  source.source,
                  _sourceStatus(strings, source.status),
                ),
        )
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

class _IndiaFeedStatus extends StatelessWidget {
  const _IndiaFeedStatus({required this.feed});
  final IndiaEventFeed feed;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final checked = feed.lastCheckedAt;
    final stale =
        feed.status != 'ok' ||
        checked == null ||
        DateTime.now().difference(checked).inMinutes > 90 ||
        feed.truncated;
    return AppSectionCard(
      child: Row(
        children: [
          Icon(
            stale ? Icons.sync_problem_rounded : Icons.public_rounded,
            color: stale ? AppColors.gold : AppColors.accent,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stale ? strings.indiaFeedDelayed : strings.indiaFeedChecked,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  checked == null
                      ? strings.noFeedRefresh
                      : 'GDACS • ${_relativeIssued(strings, checked)}',
                ),
                Text(strings.gdacsAttribution),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndiaEventCard extends StatelessWidget {
  const _IndiaEventCard({required this.event, required this.onTap});
  final IndiaEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppSectionCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const AppIconTile(
          icon: Icons.public_rounded,
          color: AppColors.emergency,
        ),
        title: Text(
          event.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${event.countryLabel} • ${event.alertLevel} • GDACS\n${_relativeIssued(strings, event.updatedAt)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
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
                  AppLocalizations.of(context).alertValidFor(
                    _remaining(AppLocalizations.of(context), alert.expiresAt),
                  ),
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
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

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
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
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

String _sourceStatus(AppLocalizations strings, String status) =>
    switch (status) {
      'unconfigured' => strings.sourceNotConfigured,
      'error' => strings.sourceRefreshFailed,
      'partial' => strings.sourceCoveragePartial,
      _ => strings.sourceNotChecked,
    };
