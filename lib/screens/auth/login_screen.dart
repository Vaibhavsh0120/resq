import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/primary_button.dart';
import 'auth_shell.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _isGuestLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _anyLoading => _isSubmitting || _isGoogleLoading || _isGuestLoading;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Navigation onward happens automatically via AuthGate's
      // authStateChanges listener — nothing to do here on success.
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      final user = credential.user;
      // additionalUserInfo?.isNewUser tells us this is the very first
      // sign-in for this Firebase account — that's when we seed the
      // Firestore profile from the Google account's name/email so
      // Onboarding Step 1 opens pre-filled instead of blank.
      if (user != null && (credential.additionalUserInfo?.isNewUser ?? false)) {
        await UserProfileService.instance.createInitialProfile(
          uid: user.uid,
          email: user.email,
          authProvider: 'google.com',
          fullName: user.displayName,
        );
      }
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.signInAsGuest();
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to ResQ.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: _anyLoading
                ? null
                : () =>
                      Navigator.of(context)
                          .push(AppMotion.fadeThrough(const SignupScreen())),
            child: const Text('Sign up'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Emergency access is the first thing offered on Login — the
            // product principle is that emergency use must never be gated
            // behind an account, so it should never be buried at the bottom.
            _EmergencyAccessCard(
              isLoading: _isGuestLoading,
              onPressed: _anyLoading ? null : _continueAsGuest,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: Divider(color: scheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or sign in',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AnimatedAuthError(message: _errorMessage),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              hintText: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_anyLoading,
              prefixIcon: Icons.mail_outline,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Password',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              enabled: !_anyLoading,
              prefixIcon: Icons.lock_outline,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _anyLoading
                    ? null
                    : () => Navigator.of(context).push(
                        AppMotion.fadeThrough(const ForgotPasswordScreen()),
                      ),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Sign in',
              isLoading: _isSubmitting,
              onPressed: _anyLoading ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Continue with Google',
              isLoading: _isGoogleLoading,
              onPressed: _anyLoading ? null : _continueWithGoogle,
              icon: const _GoogleGlyph(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prominent, clearly-separate emergency/guest entry point — anonymous
/// Firebase sign-in so a person in crisis is never blocked by registration.
class _EmergencyAccessCard extends StatelessWidget {
  const _EmergencyAccessCard({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.error.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.base),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.base),
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.emergency_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency access',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: scheme.error),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Skip sign-in and get help right now',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.error),
                  ),
                )
              else
                Icon(Icons.chevron_right, color: scheme.error),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal "G" glyph so the Google button doesn't depend on a bundled brand
/// asset — drawn to match Google's four-color mark closely enough to read
/// as "Google" at button-icon size, without importing an icon font/package
/// or reproducing a full copyrighted logo file.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    const strokeWidth = 3.2;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect,
        startDeg * 3.1415926535 / 180,
        sweepDeg * 3.1415926535 / 180,
        false,
        paint,
      );
    }

    // Four arcs approximating the familiar four-quadrant color pattern.
    arc(-90, 90, const Color(0xFF4285F4)); // blue, top-right
    arc(0, 90, const Color(0xFF34A853)); // green, bottom-right
    arc(90, 90, const Color(0xFFFBBC05)); // yellow, bottom-left
    arc(180, 90, const Color(0xFFEA4335)); // red, top-left

    // Horizontal bar, like the lowercase "g" crossbar in the mark.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - strokeWidth / 2,
        radius - 2,
        strokeWidth,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
