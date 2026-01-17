import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';

/// Reset Password Screen for setting a new password after clicking reset link
/// Implements password strength validation matching the register screen
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Validation states
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _passwordValid = _hasMinLength && _hasUppercase && _hasNumber;

      // Revalidate confirm password if it has content
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordValid = value == _confirmPasswordController.text;
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _confirmPasswordValid =
          value == _passwordController.text && value.isNotEmpty;
    });
  }

  bool get _isFormValid {
    return _passwordValid && _confirmPasswordValid;
  }

  Future<void> _handleResetPassword() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updatePassword(
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      // Show success message and navigate to login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.tertiary,
                size: 28,
              ),
              SizedBox(width: 3.w),
              const Expanded(child: Text('Password Updated')),
            ],
          ),
          content: const Text(
            'Your password has been successfully updated. You can now log in with your new password.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Failed to update password. Please try again.';
      if (e.toString().contains('same as')) {
        errorMessage = 'New password must be different from your current password.';
      } else if (e.toString().contains('expired')) {
        errorMessage = 'The reset link has expired. Please request a new one.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: Theme.of(context).snackBarTheme.contentTextStyle,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Reset Password', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 2.h),

                  // Header message
                  Text(
                    'Create New Password',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Please enter your new password below. Make sure it meets all the requirements.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 4.h),

                  // New password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Create a strong password',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'lock',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: CustomIconWidget(
                          iconName: _obscurePassword
                              ? 'visibility_off'
                              : 'visibility',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Password requirements
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password must contain:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        _buildRequirement(
                          'Minimum 8 characters',
                          _hasMinLength,
                          theme,
                        ),
                        SizedBox(height: 0.5.h),
                        _buildRequirement(
                          'One uppercase letter',
                          _hasUppercase,
                          theme,
                        ),
                        SizedBox(height: 0.5.h),
                        _buildRequirement('One number', _hasNumber, theme),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onChanged: _validateConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'lock',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_confirmPasswordController.text.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(right: 2.w),
                              child: CustomIconWidget(
                                iconName: _confirmPasswordValid
                                    ? 'check_circle'
                                    : 'cancel',
                                color: _confirmPasswordValid
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.error,
                                size: 20,
                              ),
                            ),
                          IconButton(
                            icon: CustomIconWidget(
                              iconName: _obscureConfirmPassword
                                  ? 'visibility_off'
                                  : 'visibility',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Reset password button
                  SizedBox(
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isLoading
                          ? _handleResetPassword
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.12,
                              ),
                        foregroundColor: _isFormValid
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.38,
                              ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(
                              'Update Password',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _isFormValid
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.38),
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Back to login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remember your password? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Log In',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet, ThemeData theme) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: isMet ? 'check_circle' : 'radio_button_unchecked',
          color: isMet
              ? theme.colorScheme.tertiary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
          size: 16,
        ),
        SizedBox(width: 2.w),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isMet
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}