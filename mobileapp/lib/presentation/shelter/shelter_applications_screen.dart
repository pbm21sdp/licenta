import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/services.dart';

import '../../services/shelter_service.dart';
import '../../widgets/custom_icon_widget.dart';
import 'widgets/application_card_widget.dart';

/// Screen for managing adoption applications
/// Includes filtering by status and list view
class ShelterApplicationsScreen extends StatefulWidget {
  final String shelterId;

  const ShelterApplicationsScreen({
    super.key,
    required this.shelterId,
  });

  @override
  State<ShelterApplicationsScreen> createState() =>
      _ShelterApplicationsScreenState();
}

class _ShelterApplicationsScreenState extends State<ShelterApplicationsScreen> {
  final _shelterService = ShelterService.instance;

  List<Map<String, dynamic>> _applications = [];
  Map<String, int> _statusCounts = {};
  String? _selectedFilter;
  bool _isLoading = true;

  final List<String> _statusOptions = [
    'All',
    'pending',
    'under_review',
    'interview',
    'approved',
    'rejected',
    'withdrawn',
  ];

  @override
  void initState() {
    super.initState();
    _loadApplications();
    _loadStatusCounts();
  }

  Future<void> _loadApplications() async {
    if (widget.shelterId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final filter =
          _selectedFilter == 'All' || _selectedFilter == null
              ? null
              : _selectedFilter;

      final applications = await _shelterService.getShelterApplications(
        widget.shelterId,
        statusFilter: filter,
      );

      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading applications: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(

            duration: const Duration(seconds: 3),
            content: Text('Error loading applications: $e'),

            action: SnackBarAction(
              label: 'COPY',
              textColor: Colors.red,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.toString()));
              },
            ),
          ),
        );


      }
    }
  }

  Future<void> _loadStatusCounts() async {
    if (widget.shelterId.isEmpty) return;

    try {
      final counts = await _shelterService.getApplicationCountsByStatus(
        widget.shelterId,
      );

      if (mounted) {
        setState(() => _statusCounts = counts);
      }
    } catch (e) {
      // Silently fail for counts
    }
  }

  void _onFilterChanged(String? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Filter chips
        Container(
          height: 6.h,
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _statusOptions.length,
            itemBuilder: (context, index) {
              final status = _statusOptions[index];
              final isSelected =
                  (_selectedFilter == null && status == 'All') ||
                  _selectedFilter == status;
              final count = status == 'All'
                  ? _statusCounts.values.fold(0, (a, b) => a + b)
                  : _statusCounts[status] ?? 0;

              return Padding(
                padding: EdgeInsets.only(right: 2.w),
                child: FilterChip(
                  label: Text(
                    '${_formatStatus(status)} ($count)',
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) => _onFilterChanged(
                    status == 'All' ? null : status,
                  ),
                  selectedColor: theme.colorScheme.primary,
                  checkmarkColor: theme.colorScheme.onPrimary,
                ),
              );
            },
          ),
        ),

        // Applications list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _applications.isEmpty
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadApplications();
                        await _loadStatusCounts();
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final application = _applications[index];
                          return ApplicationCardWidget(
                            application: application,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/shelter-application-detail',
                                arguments: {
                                  'applicationId': application['id'],
                                },
                              ).then((_) {
                                _loadApplications();
                                _loadStatusCounts();
                              });
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'inbox',
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            _selectedFilter == null
                ? 'No applications yet'
                : 'No ${_formatStatus(_selectedFilter!).toLowerCase()} applications',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Applications will appear here when adopters apply',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
