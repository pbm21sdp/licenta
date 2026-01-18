import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';

/// Register Screen for new user account creation
/// Implements progressive form validation with real-time feedback
/// Stack navigation pattern with dismissible keyboard support
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  // Auth service pentru înregistrare reală
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Validation states
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
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
    return _emailValid &&
        _passwordValid &&
        _confirmPasswordValid &&
        _termsAccepted;
  }

  Future<void> _handleRegister() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Apel real la API pentru înregistrare
      final response = await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response.success) {
        // Afișează mesaj de succes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: Theme.of(context).snackBarTheme.contentTextStyle,
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navighează la onboarding
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/onboarding-questionnaire');
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'A apărut o eroare. Verifică conexiunea la internet.';
      });
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
        title: Text('Create Account', style: theme.appBarTheme.titleTextStyle),
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

                  // Welcome message
                  Text(
                    'Join Paws',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Create an account to start finding your perfect pet companion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 4.h),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2.w),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
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
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'person',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: _validateEmail,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: CustomIconWidget(
                          iconName: 'email',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      suffixIcon: _emailController.text.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.all(3.w),
                              child: CustomIconWidget(
                                iconName: _emailValid
                                    ? 'check_circle'
                                    : 'cancel',
                                color: _emailValid
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.error,
                                size: 20,
                              ),
                            )
                          : null,
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: _validatePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
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

                  SizedBox(height: 3.h),

                  // Terms and conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() => _termsAccepted = value ?? false);
                          },
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _termsAccepted = !_termsAccepted);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Register button
                  SizedBox(
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isLoading
                          ? _handleRegister
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
                              'Create Account',
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

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushReplacementNamed('/login-screen');
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
