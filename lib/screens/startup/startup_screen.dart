import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return StartupVideoPresentation(
      onTap: _skip,
      child: ready
          ? SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// The intentionally minimal visual shell around the startup video.
///
/// The complete video is kept visible. Space left above and below it is filled
/// with pure white in light mode or pure black in dark mode.
class StartupVideoPresentation extends StatelessWidget {
  const StartupVideoPresentation({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;

    return Scaffold(
      backgroundColor: background,
      body: ColoredBox(
        key: const Key('startup-background'),
        color: background,
        child: GestureDetector(
          key: const Key('startup-tap-target'),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.expand(
            child: FittedBox(
              key: const Key('startup-video-fit'),
              fit: BoxFit.contain,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
