import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Modal widget for updating application status
class StatusUpdateModalWidget extends StatefulWidget {
  final String currentStatus;
  final Future<void> Function(String newStatus, String? notes) onStatusUpdate;

  const StatusUpdateModalWidget({
    super.key,
    required this.currentStatus,
    required this.onStatusUpdate,
  });

  @override
  State<StatusUpdateModalWidget> createState() =>
      _StatusUpdateModalWidgetState();
}

class _StatusUpdateModalWidgetState extends State<StatusUpdateModalWidget> {
  late String _selectedStatus;
  final _notesController = TextEditingController();
  bool _isUpdating = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'value': 'pending',
      'label': 'Pending',
      'description': 'Application awaiting initial review',
      'icon': 'hourglass_empty',
      'color': Colors.orange,
    },
    {
      'value': 'under_review',
      'label': 'Under Review',
      'description': 'Currently being evaluated',
      'icon': 'search',
      'color': Colors.blue,
    },
    {
      'value': 'interview',
      'label': 'Interview',
      'description': 'Scheduled for interview',
      'icon': 'event',
      'color': Colors.purple,
    },
    {
      'value': 'approved',
      'label': 'Approved',
      'description': 'Application approved for adoption',
      'icon': 'check_circle',
      'color': Colors.green,
    },
    {
      'value': 'rejected',
      'label': 'Rejected',
      'description': 'Application declined',
      'icon': 'cancel',
      'color': Colors.red,
    },
    {
      'value': 'withdrawn',
      'label': 'Withdrawn',
      'description': 'Application withdrawn by applicant',
      'icon': 'undo',
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_selectedStatus == widget.currentStatus) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await widget.onStatusUpdate(
        _selectedStatus,
        _notesController.text.isEmpty ? null : _notesController.text,
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 10.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: 2.h),

              // Title
              Text(
                'Update Application Status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Select a new status for this application',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 3.h),

              // Status options
              ..._statusOptions.map((option) {
                final isSelected = option['value'] == _selectedStatus;
                final isCurrent = option['value'] == widget.currentStatus;
                final color = option['color'] as Color;

                return GestureDetector(
                  onTap: _isUpdating
                      ? null
                      : () {
                          setState(() {
                            _selectedStatus = option['value'] as String;
                          });
                        },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 1.5.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: CustomIconWidget(
                            iconName: option['icon'] as String,
                            size: 20,
                            color: color,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    option['label'] as String,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? color
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    SizedBox(width: 2.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 1.5.w,
                                        vertical: 0.2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Current',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                option['description'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<String>(
                          value: option['value'] as String,
                          groupValue: _selectedStatus,
                          onChanged: _isUpdating
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                          activeColor: color,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: 2.h),

              // Notes field
              Text(
                'Notes (optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              TextField(
                controller: _notesController,
                maxLines: 3,
                enabled: !_isUpdating,
                decoration: const InputDecoration(
                  hintText: 'Add any notes about this status change...',
                ),
              ),
              SizedBox(height: 3.h),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUpdating
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _handleUpdate,
                      child: _isUpdating
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
                          : const Text('Update Status'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
