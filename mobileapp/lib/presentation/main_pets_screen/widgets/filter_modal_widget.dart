import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

/// Quick filter modal for temporary filtering on MainPetsScreen
/// Allows users to override their saved preferences temporarily
class FilterModalWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Map<String, dynamic>? savedPreferences;
  final Function(Map<String, dynamic>) onApply;

  const FilterModalWidget({
    super.key,
    required this.currentFilters,
    this.savedPreferences,
    required this.onApply,
  });

  @override
  State<FilterModalWidget> createState() => _FilterModalWidgetState();
}

class _FilterModalWidgetState extends State<FilterModalWidget> {
  late List<String> _selectedSpecies;

  @override
  void initState() {
    super.initState();
    // Initialize from current filters
    final speciesFilter = widget.currentFilters['speciesFilter'] as List?;
    _selectedSpecies = speciesFilter != null
        ? List<String>.from(speciesFilter)
        : ['Dog', 'Cat'];
  }

  void _toggleSpecies(String species) {
    setState(() {
      if (_selectedSpecies.contains(species)) {
        // Don't allow deselecting all species
        if (_selectedSpecies.length > 1) {
          _selectedSpecies.remove(species);
        }
      } else {
        _selectedSpecies.add(species);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedSpecies = ['Dog', 'Cat'];
    });
  }

  void _resetToPreferences() {
    if (widget.savedPreferences != null) {
      final preferredTypes =
          widget.savedPreferences!['preferred_pet_types'] as List?;
      setState(() {
        if (preferredTypes != null && preferredTypes.isNotEmpty) {
          _selectedSpecies = List<String>.from(preferredTypes);
        } else {
          _selectedSpecies = ['Dog', 'Cat'];
        }
      });
    }
  }

  void _applyFilters() {
    widget.onApply({
      'speciesFilter': _selectedSpecies,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.5.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              children: [
                Text(
                  'Filter Pets',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.savedPreferences != null)
                  TextButton(
                    onPressed: _resetToPreferences,
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),

          // Pet Type Section
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Type',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),

                // Species toggles
                Row(
                  children: [
                    Expanded(
                      child: _buildSpeciesChip(
                        theme,
                        'Dog',
                        'pets',
                        _selectedSpecies.contains('Dog'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: _buildSpeciesChip(
                        theme,
                        'Cat',
                        'pets',
                        _selectedSpecies.contains('Cat'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Show All option
                InkWell(
                  onTap: _selectAll,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedSpecies.length == 2
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: _selectedSpecies.length == 2
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: _selectedSpecies.length == 2 ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'select_all',
                          color: _selectedSpecies.length == 2
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Show All Pets',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _selectedSpecies.length == 2
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: _selectedSpecies.length == 2
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Apply Button
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSpeciesChip(
    ThemeData theme,
    String species,
    String iconName,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => _toggleSpecies(species),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              species,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}