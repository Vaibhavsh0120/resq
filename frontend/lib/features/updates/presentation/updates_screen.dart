import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../application/alerts_providers.dart';
import '../domain/public_alert.dart';

class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const ResQPageHeader(
            title: 'Updates',
            subtitle: 'Verified alerts near you',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Latest nearby',
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
              title: 'Updates are unavailable',
              message: 'Pull down to try again. Previously received emergency guidance remains available.',
            ),
            data: (items) => items.isEmpty
                ? const _FeedMessage(
                    icon: Icons.verified_user_outlined,
                    title: 'No active verified alerts',
                    message: 'Pull down to check again.',
                  )
                : Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        _AlertCard(alert: items[index]),
                        if (index != items.length - 1)
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final PublicAlert alert;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final severe = {'extreme', 'severe'}.contains(alert.severity);
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
                  '${alert.source} • ${_relativeIssued(alert.issuedAt)}',
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

String _relativeIssued(DateTime issuedAt) {
  final difference = DateTime.now().difference(issuedAt);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(0, 59)} min ago';
  }
  if (difference.inHours < 24) return '${difference.inHours} hr ago';
  return '${difference.inDays} days ago';
}
