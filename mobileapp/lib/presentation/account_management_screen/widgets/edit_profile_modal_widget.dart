import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Modal widget for editing user profile
class EditProfileModalWidget extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  final Future<bool> Function(String name) onSave;

  const EditProfileModalWidget({
    super.key,
    required this.currentProfile,
    required this.onSave,
  });

  @override
  State<EditProfileModalWidget> createState() => _EditProfileModalWidgetState();
}

class _EditProfileModalWidgetState extends State<EditProfileModalWidget> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentProfile['name'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onSave(_nameController.text.trim());

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorMessage = 'Could not update profile. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(3.w),
                        margin: EdgeInsets.only(bottom: 2.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'error',
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

                    // Name field
                    Text(
                      'Display Name',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _saveProfile(),
                    ),

                    SizedBox(height: 2.h),

                    // Email (read-only)
                    Text(
                      'Email',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              widget.currentProfile['email'] as String? ?? '',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Email cannot be changed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                'Save Changes',
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
