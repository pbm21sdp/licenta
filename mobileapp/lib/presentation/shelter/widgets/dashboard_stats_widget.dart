import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Dashboard statistics card grid widget
/// Displays key metrics for shelter staff
class DashboardStatsWidget extends StatelessWidget {
  final Map<String, int> stats;

  const DashboardStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 1.h,
      crossAxisSpacing: 2.w,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          theme,
          'Total Pets',
          stats['totalPets'] ?? 0,
          Icons.home,
          theme.colorScheme.primary,
        ),
        _buildStatCard(
          theme,
          'Available',
          stats['availablePets'] ?? 0,
          Icons.check_circle,
          Colors.greenAccent,
        ),
        _buildStatCard(
          theme,
          'Pending',
          stats['pendingApplications'] ?? 0,
          Icons.hourglass_bottom,
          Colors.orange,
        ),
        _buildStatCard(
          theme,
          'Total Applications',
          stats['totalApplications'] ?? 0,
          Icons.assignment,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    int value,
    IconData iconName,
    Color color,
  ) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    iconName,
                    size: 48,
                    color: color,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    value.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
