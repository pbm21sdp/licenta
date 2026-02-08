// lib/presentation/adoption_requests_screen/adoption_requests_screen.dart
// Ecran pentru gestionarea cererilor de adopție primite (ca owner)

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/public_profile_model.dart';
import '../../services/owner_adoptions_service.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_image_widget.dart';

class AdoptionRequestsScreen extends StatefulWidget {
  const AdoptionRequestsScreen({super.key});

  @override
  State<AdoptionRequestsScreen> createState() => _AdoptionRequestsScreenState();
}

class _AdoptionRequestsScreenState extends State<AdoptionRequestsScreen> {
  final OwnerAdoptionsService _adoptionsService = OwnerAdoptionsService();

  bool _isLoading = true;
  String? _errorMessage;
  List<AdoptionRequestModel> _requests = [];
  AdoptionRequestsStats? _stats;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _adoptionsService.getMyAdoptionRequests(
        status: _selectedFilter != 'all' ? _selectedFilter : null,
      );

      if (mounted) {
        setState(() {
          _requests = response.applications;
          _stats = response.stats;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load requests';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(AdoptionRequestModel request, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'approved' ? 'Approve Application' : 'Decline Application'),
        content: Text(
          status == 'approved'
              ? 'Are you sure you want to approve ${request.applicantName ?? "this applicant"}\'s application for ${request.petName}?'
              : 'Are you sure you want to decline this application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved'
                  ? const Color(0xFF22C55E)
                  : Theme.of(context).colorScheme.error,
            ),
            child: Text(status == 'approved' ? 'Approve' : 'Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (status == 'approved') {
        await _adoptionsService.approveAdoption(request.id);
      } else {
        await _adoptionsService.rejectAdoption(request.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Application approved!'
                  : 'Application declined',
            ),
            backgroundColor: status == 'approved'
                ? const Color(0xFF22C55E)
                : null,
          ),
        );
        _loadRequests();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showRequestDetails(AdoptionRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRequestDetailModal(request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Adoption Requests',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats bar
          if (_stats != null) _buildStatsBar(theme),

          // Filter chips
          _buildFilterChips(theme),

          // Requests list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            SizedBox(height: 2.h),
                            ElevatedButton(
                              onPressed: _loadRequests,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _requests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: theme.colorScheme.outline,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'No adoption requests',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'When someone applies to adopt your pet,\nit will appear here.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadRequests,
                            child: ListView.builder(
                              padding: EdgeInsets.all(4.w),
                              itemCount: _requests.length,
                              itemBuilder: (context, index) {
                                return _buildRequestCard(theme, _requests[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(theme, 'Pending', _stats!.pending, const Color(0xFFFFE66D)),
          _buildStatChip(theme, 'In Review', _stats!.inReview, const Color(0xFFFFAB91)),
          _buildStatChip(theme, 'Approved', _stats!.approved, const Color(0xFF22C55E)),
          _buildStatChip(theme, 'Declined', _stats!.rejected, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatChip(ThemeData theme, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'in_review', 'label': 'In Review'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'rejected', 'label': 'Declined'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedFilter = filter['key']!);
                _loadRequests();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(ThemeData theme, AdoptionRequestModel request) {
    final statusColor = _getStatusColor(request.status);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: request.petPhoto ?? '',
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                      semanticLabel: 'Photo of ${request.petName}',
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.petName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          'Applicant: ${request.applicantName ?? request.fullName ?? "Unknown"}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.statusDisplay,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Details
              if (request.adoptionReason != null) ...[
                SizedBox(height: 2.h),
                Text(
                  'Reason: ${request.adoptionReason}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Action buttons for pending requests
              if (request.isPending) ...[
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateStatus(request, 'rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateStatus(request, 'approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetailModal(AdoptionRequestModel request) {
    final theme = Theme.of(context);

    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Application Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet info
                  _buildDetailSection(theme, 'Pet', request.petName),

                  // Applicant info
                  _buildDetailSection(theme, 'Applicant', request.applicantName ?? request.fullName ?? 'Unknown'),
                  if (request.email != null)
                    _buildDetailSection(theme, 'Email', request.email!),
                  if (request.phone != null)
                    _buildDetailSection(theme, 'Phone', request.phone!),
                  if (request.city != null)
                    _buildDetailSection(theme, 'City', request.city!),
                  if (request.housingType != null)
                    _buildDetailSection(theme, 'Housing', _formatLabel(request.housingType!)),

                  // Household info
                  _buildDetailSection(
                    theme,
                    'Has Children',
                    request.hasChildren == true ? 'Yes' : 'No',
                  ),
                  _buildDetailSection(
                    theme,
                    'Has Other Pets',
                    request.hasOtherPets == true ? 'Yes' : 'No',
                  ),

                  // Reason
                  if (request.adoptionReason != null)
                    _buildDetailSection(theme, 'Adoption Reason', request.adoptionReason!),

                  // Message
                  if (request.message != null)
                    _buildDetailSection(theme, 'Additional Message', request.message!),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Action buttons
          if (request.isPending)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateStatus(request, 'rejected');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateStatus(request, 'approved');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFE66D);
      case 'in_review':
        return const Color(0xFFFFAB91);
      case 'approved':
        return const Color(0xFF22C55E);
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatLabel(String value) {
    return value.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
