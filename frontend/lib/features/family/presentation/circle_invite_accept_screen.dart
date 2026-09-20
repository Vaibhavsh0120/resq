import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../application/family_providers.dart';

class CircleInviteAcceptScreen extends ConsumerStatefulWidget {
  const CircleInviteAcceptScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<CircleInviteAcceptScreen> createState() =>
      _CircleInviteAcceptScreenState();
}

class _CircleInviteAcceptScreenState
    extends ConsumerState<CircleInviteAcceptScreen> {
  bool _accepting = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
    });
    try {
      await ref.read(circleApiProvider).acceptInvite(widget.token);
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final canAccept = user != null && !user.isAnonymous;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Family Circle invitation'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppSectionCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_add_rounded, size: 48),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Join this household safety Circle?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    canAccept
                        ? 'Accepting lets Circle members coordinate emergency check-ins. Location is never shared automatically.'
                        : 'Sign in with a registered ResQ account before accepting this invitation.',
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: !canAccept || _accepting ? null : _accept,
                      icon: _accepting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        canAccept ? 'Accept invitation' : 'Go to sign in',
                      ),
                    ),
                  ),
                  if (!canAccept) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Open ResQ sign in'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
