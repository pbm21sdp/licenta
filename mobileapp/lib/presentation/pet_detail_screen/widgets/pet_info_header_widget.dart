import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PetInfoHeaderWidget extends StatelessWidget {
  final String name;
  final String gender;

  const PetInfoHeaderWidget({
    super.key,
    required this.name,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 3.w),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: gender.toLowerCase() == 'male' ? 'male' : 'female',
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
