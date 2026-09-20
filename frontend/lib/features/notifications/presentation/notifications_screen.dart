import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../application/notifications_providers.dart';
import '../data/push_notification_service.dart';
import '../domain/resq_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user == null || user.isAnonymous ? null : user.uid;
    final unread = uid == null
        ? 0
        : ref.watch(unreadNotificationsProvider(uid));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Notifications'),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: unread == 0
                  ? null
                  : () => ref
                        .read(notificationsRepositoryProvider)
                        .markAllRead(uid),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: uid == null
          ? const _MessageState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to view notifications',
              message: 'Your durable alert inbox is available to registered accounts.',
            )
          : Column(
              children: [
                const _PushPermissionCard(),
                Expanded(
                  child: ref
                      .watch(notificationsProvider(uid))
                      .when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => const _MessageState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Notifications are unavailable',
                          message: 'Check your connection and try again.',
                        ),
                        data: (notifications) => notifications.isEmpty
                            ? const _MessageState(
                                icon: Icons.notifications_none_rounded,
                                title: 'You are all caught up',
                                message: 'Safety alerts and Circle updates will appear here.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: notifications.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final notification = notifications[index];
                                  return _NotificationTile(
                                    notification: notification,
                                    onTap: () async {
                                      if (!notification.isRead) {
                                        await ref
                                            .read(
                                              notificationsRepositoryProvider,
                                            )
                                            .markRead(uid, notification.id);
                                      }
                                      if (context.mounted) {
                                        final deepLink = notification.deepLink;
                                        if (deepLink != null &&
                                            deepLink.startsWith('/') &&
                                            !deepLink.startsWith('//')) {
                                          context.push(deepLink);
                                        } else {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  _NotificationDetail(
                                                    notification: notification,
                                                  ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                ),
              ],
            ),
    );
  }
}

class _PushPermissionCard extends StatefulWidget {
  const _PushPermissionCard();

  @override
  State<_PushPermissionCard> createState() => _PushPermissionCardState();
}

class _PushPermissionCardState extends State<_PushPermissionCard> {
  late Future<AuthorizationStatus> _status;
  bool _enabling = false;

  @override
  void initState() {
    super.initState();
    _status = PushNotificationService.instance.permissionStatus();
  }

  Future<void> _enable() async {
    setState(() => _enabling = true);
    try {
      await PushNotificationService.instance.enable();
    } finally {
      if (mounted) {
        setState(() {
          _enabling = false;
          _status = PushNotificationService.instance.permissionStatus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PushNotificationService.instance.isSupported) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<AuthorizationStatus>(
      future: _status,
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null ||
            status == AuthorizationStatus.authorized ||
            status == AuthorizationStatus.provisional) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Enable push alerts',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status == AuthorizationStatus.denied
                      ? 'Push alerts are blocked. Enable notifications for ResQ in your device settings.'
                      : 'Receive critical safety and Family Circle alerts when ResQ is closed.',
                ),
                if (status != AuthorizationStatus.denied) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: _enabling ? null : _enable,
                      child: Text(_enabling ? 'Enabling…' : 'Enable'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final ResQNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (notification.severity) {
      NotificationSeverity.critical => (Icons.sos_rounded, 'Critical'),
      NotificationSeverity.warning => (Icons.warning_amber_rounded, 'Warning'),
      NotificationSeverity.info => (Icons.info_outline_rounded, 'Information'),
    };
    return Semantics(
      label: '${notification.isRead ? 'Read' : 'Unread'} $label notification',
      button: true,
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: AppSpacing.md,
        leading: Badge(
          isLabelVisible: !notification.isRead,
          smallSize: 9,
          child: CircleAvatar(child: Icon(icon)),
        ),
        title: Text(
          notification.title,
          style: notification.isRead
              ? null
              : const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _NotificationDetail extends StatelessWidget {
  const _NotificationDetail({required this.notification});

  final ResQNotification notification;

  @override
  Widget build(BuildContext context) {
    final isSos = notification.category == 'sos';
    return Scaffold(
      appBar: AppBar(title: const Text('Notification details')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isSos ? Icons.sos_rounded : Icons.notifications_rounded,
                  size: 44,
                  color: isSos ? Theme.of(context).colorScheme.error : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(notification.body),
              ],
            ),
          ),
          if (isSos) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri(scheme: 'tel', path: '112'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call 112'),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'ResQ records and shares this alert with the Family Circle. It does not contact emergency responders automatically.',
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
