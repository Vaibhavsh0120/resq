import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_mark.dart';

/// Plays the theme-appropriate startup video once, then hands off via
/// [onFinished]. Tap anywhere to skip. Never actually shown on web — see
/// [AppPlatformInfo.showsStartupVideo] at the call site — but this widget
/// stays platform-agnostic itself so it's easy to test/reuse.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  VideoPlayerController? _controller;
  bool _finished = false;
  bool _hadError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initVideo());
  }

  Future<void> _initVideo() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/videos/startup_dark.mp4'
        : 'assets/videos/startup_light.mp4';

    final controller = VideoPlayerController.asset(asset);
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_onVideoTick);
      await controller.play();
      setState(() {});
    } catch (_) {
      // If the asset fails to load/decode on some device for any reason,
      // don't strand the user on a black screen — proceed straight to auth.
      if (mounted) setState(() => _hadError = true);
      _finish();
    }
  }

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || _finished) return;
    final value = controller.value;
    if (value.isInitialized &&
        !value.isPlaying &&
        value.position >= value.duration) {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _finish();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _hadError ? null : _skip,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedOpacity(
              duration: AppMotion.slow,
              opacity: ready ? 1 : 0,
              child: ready
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              left: AppSpacing.lg,
              top: AppSpacing.lg,
              child: SafeArea(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface
                        .withValues(alpha: .88),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: ResQBrandMark(size: 30, showWordmark: true),
                  ),
                ),
              ),
            ),
            if (!ready && !_hadError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ResQBrandMark(size: 72),
                    const SizedBox(height: AppSpacing.lg),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Preparing ResQ…',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (ready)
              Positioned(
                right: 20,
                bottom: 32,
                child: SafeArea(
                  child: AnimatedOpacity(
                    duration: AppMotion.medium,
                    opacity: 0.85,
                    child: _SkipPill(onTap: _skip),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkipPill extends StatelessWidget {
  const _SkipPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      elevation: 8,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Skip', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: scheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}
