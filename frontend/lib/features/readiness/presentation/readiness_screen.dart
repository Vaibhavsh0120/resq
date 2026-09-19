import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../application/readiness_providers.dart';
import '../data/readiness_repository.dart';
import '../domain/readiness_item.dart';

class ReadinessScreen extends ConsumerWidget {
  const ReadinessScreen({super.key, required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = isGuest ? null : ref.watch(currentUserIdProvider);
    final guestItems = FirestoreReadinessRepository.defaults.entries
        .map(
          (entry) => ReadinessItem(
            id: entry.key,
            label: entry.value,
            completed: false,
          ),
        )
        .toList(growable: false);
    final items = isGuest || uid == null
        ? AsyncValue.data(guestItems)
        : ref.watch(readinessItemsProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Your readiness plan')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ReadinessMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Readiness is unavailable',
          message: 'Check your connection and try again.',
          action: uid == null
              ? null
              : () => ref.invalidate(readinessItemsProvider(uid)),
        ),
        data: (values) => _ReadinessList(
          items: values,
          isGuest: isGuest,
          onChanged: uid == null
              ? null
              : (item, completed) => ref
                    .read(readinessRepositoryProvider)
                    .setCompleted(uid, item, completed),
        ),
      ),
    );
  }
}

class _ReadinessList extends StatelessWidget {
  const _ReadinessList({
    required this.items,
    required this.isGuest,
    required this.onChanged,
  });

  final List<ReadinessItem> items;
  final bool isGuest;
  final Future<void> Function(ReadinessItem, bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final complete = items.where((item) => item.completed).length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          '$complete of ${items.length} essentials ready',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: items.isEmpty ? 0 : complete / items.length,
          minHeight: 10,
          borderRadius: BorderRadius.circular(99),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionCard(
          child: Column(
            children: items
                .map(
                  (item) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: item.completed,
                    title: Text(item.label),
                    onChanged: isGuest || onChanged == null
                        ? null
                        : (value) => onChanged!(item, value ?? false),
                  ),
                )
                .toList(),
          ),
        ),
        if (isGuest) ...[
          const SizedBox(height: AppSpacing.md),
          const Text('Sign in to save your checklist across devices.'),
        ],
      ],
    );
  }
}

class _ReadinessMessage extends StatelessWidget {
  const _ReadinessMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: action, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
