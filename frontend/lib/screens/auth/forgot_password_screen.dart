import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/auth_error_banner.dart';
import '../../widgets/primary_button.dart';
import 'auth_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isSubmitting = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _emailFocusNode.requestFocus(),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await AuthService.instance.sendPasswordResetEmail(_emailController.text);
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _emailSent = true);
    } on AuthFailure catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Reset your password',
      subtitle: _emailSent
          ? 'Check your inbox for a reset link.'
          : "Enter your email and we'll send you a reset link.",
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to sign in'),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.emphasized,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _emailSent
            ? _SentConfirmation(key: const ValueKey('sent'))
            : Form(
                key: _formKey,
                child: Column(
                  key: const ValueKey('form-body'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedAuthError(message: _errorMessage),
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      hintText: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      enabled: !_isSubmitting,
                      prefixIcon: Icons.mail_outline,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) => _submit(),
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
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Send reset link',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SentConfirmation extends StatelessWidget {
  const _SentConfirmation({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSectionCard(
      color: scheme.secondary.withValues(alpha: 0.08),
      child: Column(
        children: [
          const AppIllustration(
            'assets/illustrations/password_sent.png',
            height: 150,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "If an account exists for that email, we've sent a link to reset your password. It may take a minute to arrive.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
