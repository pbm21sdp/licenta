import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_icon_widget.dart';

/// Login Screen with Supabase authentication
/// Implements email verification checking and activation notification
/// Restricts adoption actions for unverified users
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.instance;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in with Supabase
      final response = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Check email verification status
      final isVerified = await _authService.isEmailVerified();

      if (!isVerified) {
        // Show verification warning dialog
        _showVerificationWarningDialog();
      } else {
        // Navigate to main pets screen
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/main-pets-screen');
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Invalid email or password. Please try again.';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage =
            'Invalid email or password. Please check your credentials.';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'Please verify your email before logging in.';
      } else if (e.toString().contains('User not found')) {
        errorMessage =
            'No account found with this email. Please register first.';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted && _errorMessage == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVerificationWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 28,
            ),
            SizedBox(width: 3.w),
            const Expanded(child: Text('Email Not Verified')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your email address has not been verified yet.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 2.h),
            const Text(
              'You can browse pets, but adoption actions are restricted until you verify your email.',
            ),
            SizedBox(height: 1.h),
            Text(
              'Please check your inbox for the verification link.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await _authService.resendVerificationEmail();
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Verification email sent!'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to resend email: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Resend Email'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushReplacementNamed('/main-pets-screen');
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Reset Password',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: const Text('Please enter your email address first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(email: _emailController.text.trim());

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Password Reset Email Sent',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'A password reset link has been sent to ${_emailController.text.trim()}. Please check your email.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error', style: Theme.of(context).textTheme.titleLarge),
          content: Text('Failed to send reset email: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 4.h),

                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushReplacementNamed('/welcome-screen'),
                          icon: CustomIconWidget(
                            iconName: 'arrow_back',
                            color: theme.colorScheme.onSurface,
                            size: 24,
                          ),
                          tooltip: 'Back to welcome',
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // App logo
                      Center(
                        child: Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: Center(
                            child: CustomIconWidget(
                              iconName: 'pets',
                              color: theme.colorScheme.onPrimary,
                              size: 10.w,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Welcome text
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 1.h),

                      Text(
                        'Sign in to continue your pet adoption journey',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 4.h),

                      // Demo credentials section
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Demo Credentials',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Verified User:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'verified@petadoption.com / VerifiedUser123',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              'Unverified User:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'unverified@petadoption.com / UnverifiedUser123',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Login form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email input
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              enabled: !_isLoading,
                              validator: _validateEmail,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(3.w),
                                  child: CustomIconWidget(
                                    iconName: 'email',
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 2.h),

                            // Password input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              textInputAction: TextInputAction.done,
                              enabled: !_isLoading,
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _handleSignIn(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(3.w),
                                  child: CustomIconWidget(
                                    iconName: 'lock',
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  icon: CustomIconWidget(
                                    iconName: _isPasswordVisible
                                        ? 'visibility_off'
                                        : 'visibility',
                                    color: theme.colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  tooltip: _isPasswordVisible
                                      ? 'Hide password'
                                      : 'Show password',
                                ),
                              ),
                            ),

                            SizedBox(height: 1.h),

                            // Forgot password link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleForgotPassword,
                                child: Text(
                                  'Forgot Password?',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // Error message
                            if (_errorMessage != null) ...[
                              SizedBox(height: 1.h),
                              Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(2.w),
                                  border: Border.all(
                                    color: theme.colorScheme.error.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'error_outline',
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    SizedBox(width: 2.w),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.error,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: 3.h),

                            // Sign in button
                            SizedBox(
                              height: 6.h,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignIn,
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                theme.colorScheme.onPrimary,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Register link
                      Padding(
                        padding: EdgeInsets.only(bottom: 3.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pushReplacementNamed('/register-screen'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 2.w),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign Up',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
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
        ),
      ),
    );
  }
}
