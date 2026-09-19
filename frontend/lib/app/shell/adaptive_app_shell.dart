import 'package:flutter/material.dart';

import '../../features/family/presentation/family_screen.dart';
import '../../features/home/presentation/home_dashboard.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/places/presentation/places_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reports/presentation/report_screen.dart';
import '../../features/updates/presentation/updates_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/brand_mark.dart';

enum ResQDestination { home, updates, report, family, places }

class AdaptiveAppShell extends StatefulWidget {
  const AdaptiveAppShell({super.key, required this.isGuest});

  final bool isGuest;

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  var _selected = ResQDestination.home;

  static const _icons = [
    Icons.home_rounded,
    Icons.notifications_active_rounded,
    Icons.add_alert_rounded,
    Icons.people_alt_rounded,
    Icons.location_on_rounded,
  ];

  void _select(int index) {
    final destination = ResQDestination.values[index];
    if (widget.isGuest && destination == ResQDestination.family) {
      _showGuestGate();
      return;
    }
    setState(() => _selected = destination);
  }

  void _showGuestGate() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to use Family Circle',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'A registered account protects invitations, check-ins, and shared locations.',
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final selectedIndex = _selected.index;
    final strings = AppLocalizations.of(context);
    final labels = [
      strings.home,
      strings.updates,
      strings.report,
      strings.family,
      strings.places,
    ];
    final pages = <Widget>[
      HomeDashboard(isGuest: widget.isGuest),
      const UpdatesScreen(),
      ReportScreen(isGuest: widget.isGuest),
      FamilyScreen(isGuest: widget.isGuest),
      const PlacesScreen(),
    ];

    final content = IndexedStack(index: selectedIndex, children: pages);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    _Sidebar(
                      selectedIndex: selectedIndex,
                      labels: labels,
                      onSelect: _select,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: _select,
              destinations: List.generate(
                labels.length,
                (index) => NavigationDestination(
                  icon: Icon(_icons[index]),
                  label: labels[index],
                ),
              ),
            ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.labels,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ResQBrandMark(size: 40, showWordmark: true),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: NavigationRail(
              extended: true,
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: onSelect,
              labelType: NavigationRailLabelType.none,
              destinations: List.generate(
                labels.length,
                (index) => NavigationRailDestination(
                  icon: Icon(_AdaptiveAppShellState._icons[index]),
                  label: Text(labels[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResQPageHeader extends StatelessWidget {
  const ResQPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onProfile,
    this.onNotifications,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: strings.profileSettings,
          onPressed:
              onProfile ??
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileScreen(
                    isGuest:
                        AuthService.instance.currentUser?.isAnonymous ?? false,
                  ),
                ),
              ),
          icon: const Icon(Icons.person_rounded),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: strings.notifications,
          onPressed:
              onNotifications ??
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
          icon: const Badge(
            smallSize: 8,
            child: Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }
}
