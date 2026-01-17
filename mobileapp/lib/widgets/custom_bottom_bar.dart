import 'package:flutter/material.dart';

/// Custom Bottom Navigation Bar for pet adoption app
/// Implements thumb-accessible design with primary navigation destinations
/// Based on Mobile Navigation Hierarchy: Pets Tab, Favorites Tab, Profile Tab
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor:
              theme.bottomNavigationBarTheme.unselectedItemColor,
          selectedLabelStyle: theme.bottomNavigationBarTheme.selectedLabelStyle,
          unselectedLabelStyle:
              theme.bottomNavigationBarTheme.unselectedLabelStyle,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            // Pets Tab - Main swipe interface (Heart Icon)
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.favorite_border,
                isSelected: currentIndex == 0,
              ),
              activeIcon: _buildIcon(icon: Icons.favorite, isSelected: true),
              label: 'Pets',
              tooltip: 'Discover pets',
            ),

            // Favorites Tab - Saved pets grid (Bookmark Icon)
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.bookmark_border,
                isSelected: currentIndex == 1,
              ),
              activeIcon: _buildIcon(icon: Icons.bookmark, isSelected: true),
              label: 'Favorites',
              tooltip: 'View saved pets',
            ),

            // Chat Tab - AI adoption assistant (Chat Icon)
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.chat_bubble_outline,
                isSelected: currentIndex == 2,
              ),
              activeIcon: _buildIcon(icon: Icons.chat_bubble, isSelected: true),
              label: 'Chat',
              tooltip: 'Adoption assistant',
            ),

            // Profile Tab - Settings and preferences (User Icon)
            BottomNavigationBarItem(
              icon: _buildIcon(
                icon: Icons.person_outline,
                isSelected: currentIndex == 3,
              ),
              activeIcon: _buildIcon(icon: Icons.person, isSelected: true),
              label: 'Profile',
              tooltip: 'Manage profile',
            ),
          ],
        ),
      ),
    );
  }

  /// Builds icon with subtle scaling animation for touch feedback
  /// Implements Transform.scale (0.95-1.0) for purposeful motion
  Widget _buildIcon({required IconData icon, required bool isSelected}) {
    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Icon(icon, size: 24),
    );
  }
}
