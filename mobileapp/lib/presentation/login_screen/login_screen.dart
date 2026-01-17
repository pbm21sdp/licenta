import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';

/// Login Screen for pet adoption app authentication
/// Implements secure email/password authentication with mobile-optimized input
/// Uses stack navigation, accessible from welcome screen or when session expires
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Mock credentials for authentication
  final String _mockEmail = "user@petadoption.com";
  final String _mockPassword = "PetLover123";

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates email format
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

  /// Validates password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Handles sign in authentication
  Future<void> _handleSignIn() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Simulate authentication delay
    await Future.delayed(const Duration(seconds: 1));

    // Check credentials
    if (_emailController.text.trim() == _mockEmail &&
        _passwordController.text == _mockPassword) {
      // Success - navigate to main pets screen
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/main-pets-screen');
      }
    } else {
      // Failed authentication
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password. Please try again.';
        });
      }
    }
  }

  /// Handles forgot password navigation
  void _handleForgotPassword() {
    // Show password reset dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Password reset functionality will be available soon. Please contact support for assistance.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/logo.png',
                              ),
                              fit: BoxFit.contain
                            ),
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.w),
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
