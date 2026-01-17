import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/adoption_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class AdoptionFormWidget extends StatefulWidget {
  final String petId;
  final String petName;
  final String shelterId;

  const AdoptionFormWidget({
    super.key,
    required this.petId,
    required this.petName,
    required this.shelterId,
  });

  @override
  State<AdoptionFormWidget> createState() => _AdoptionFormWidgetState();
}

class _AdoptionFormWidgetState extends State<AdoptionFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _adoptionService = AdoptionService();
  final _authService = AuthService.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String _housingType = 'house';
  final String _experienceLevel = 'some_experience';
  bool _hasGarden = false;
  final bool _hasExistingPets = false;
  String _hasPets = 'No';
  String _experience = 'First time';
  bool _isLoading = false;
  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    final isVerified = await _authService.isEmailVerified();
    setState(() {
      _isEmailVerified = isVerified;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Check email verification first
    if (!_isEmailVerified) {
      _showEmailVerificationRequired();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final hasDuplicate = await _adoptionService.hasExistingApplication(
        petId: widget.petId,
        applicantEmail: _emailController.text.trim(),
      );

      if (hasDuplicate) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'You have already submitted an application for this pet.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      await _adoptionService.submitAdoptionApplication(
        petId: widget.petId,
        petName: widget.petName,
        shelterId: widget.shelterId,
        applicantName: _nameController.text.trim(),
        applicantEmail: _emailController.text.trim(),
        applicantPhone: _phoneController.text.trim(),
        applicantAddress: _addressController.text.trim(),
        housingType: _housingType,
        hasGarden: _hasGarden,
        hasExistingPets: _hasExistingPets,
        experienceLevel: _experienceLevel,
        additionalNotes: _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Application submitted successfully!'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEmailVerificationRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            SizedBox(width: 3.w),
            const Expanded(child: Text('Email Verification Required')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You must verify your email address before submitting adoption applications.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 2.h),
            const Text(
              'Please check your email for the verification link we sent when you registered.',
            ),
            SizedBox(height: 1.h),
            Text(
              'After verifying your email, you can submit applications to adopt pets.',
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      child: Column(
        children: [
          SizedBox(height: 1.h),
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(1.h),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Adoption Application',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Email verification banner
          if (!_isEmailVerified)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.error,
                    size: 24,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Verification Required',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Verify your email to submit applications',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(5.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Contact Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        hintText: 'Enter your address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Housing Situation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      initialValue: _housingType,
                      decoration: InputDecoration(
                        labelText: 'Housing Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                      items: [
                        DropdownMenuItem(value: 'house', child: Text('House')),
                        DropdownMenuItem(
                          value: 'apartment',
                          child: Text('Apartment'),
                        ),
                        DropdownMenuItem(value: 'condo', child: Text('Condo')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _housingType = value ?? 'house';
                        });
                      },
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      initialValue: _hasGarden ? 'Yes' : 'No',
                      decoration: InputDecoration(
                        labelText: 'Do you have a garden/yard?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.grass_outlined),
                      ),
                      items: ['Yes', 'No']
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _hasGarden = value == 'Yes';
                        });
                      },
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Experience Assessment',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      initialValue: _hasPets,
                      decoration: InputDecoration(
                        labelText: 'Do you currently have pets?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.pets_outlined),
                      ),
                      items: ['Yes', 'No']
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _hasPets = value ?? 'No';
                        });
                      },
                    ),
                    SizedBox(height: 2.h),
                    DropdownButtonFormField<String>(
                      initialValue: _experience,
                      decoration: InputDecoration(
                        labelText: 'Pet Ownership Experience',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.star_outline),
                      ),
                      items:
                          ['First time', 'Some experience', 'Very experienced']
                              .map(
                                (exp) => DropdownMenuItem(
                                  value: exp,
                                  child: Text(exp),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          _experience = value ?? 'First time';
                        });
                      },
                    ),
                    SizedBox(height: 2.h),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        hintText:
                            'Tell us why you would be a great fit for ${widget.petName}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    SizedBox(
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
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
                                'Submit Application',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
