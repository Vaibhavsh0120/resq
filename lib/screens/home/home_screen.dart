import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/theme_mode_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final guest = user?.isAnonymous ?? false;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Row(
                        children: [
                          const ResQBrandMark(size: 44, showWordmark: true),
                          const Spacer(),
                          const ThemeModeButton(),
                          IconButton(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded),
                            tooltip: 'Log out',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            guest ? 'You have quick access' : 'You are ready',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            guest
                                ? 'ResQ is available in guest mode without storing a personal profile.'
                                : 'Your safety profile is set up and available when you need it.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppSectionCard(
                            padding: EdgeInsets.zero,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final horizontal = constraints.maxWidth > 620;
                                final status = Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withValues(
                                            alpha: .12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.full,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: AppColors.accent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 7),
                                            Text('Emergency access ready'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      Text(
                                        guest
                                            ? "You're in — Emergency access"
                                            : 'Your account is protected',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        guest
                                            ? 'Core help remains available without an account.'
                                            : (user?.email ??
                                                  'Signed-in account'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                                const art = Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: AppIllustration(
                                    'assets/illustrations/auth_safety.png',
                                    height: 220,
                                  ),
                                );
                                return horizontal
                                    ? Row(
                                        children: [
                                          Expanded(flex: 6, child: status),
                                          const Expanded(flex: 4, child: art),
                                        ],
                                      )
                                    : Column(children: [art, status]);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppSectionCard(
                            showShadow: false,
                            color: AppColors.emergency.withValues(alpha: .08),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppIconTile(
                                  icon: Icons.emergency_rounded,
                                  color: AppColors.emergency,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Emergency tools',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.emergency,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ResQ is not a replacement for local emergency services. Call your local emergency number when immediate help is required.',
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
