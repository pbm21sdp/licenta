import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Minimalist Welcome Screen
/// Clean design with pet illustration and teal accent buttons

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Pet illustration with decorative dots
              _buildIllustration(),

              SizedBox(height: 1.h),

              // App title
              Text(
                'Paws',
                style: TextStyle(
                  fontFamily: 'Cinthya',
                  fontSize: 80.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: 2.h),

              // Subtitle
              Text(
                'Find with your\nperfect pet companion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const Spacer(flex: 3),

              // Get Started button
              _buildTealButton(
                theme: theme,
                label: 'Get Started',
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .pushNamed('/register-screen');
                },
              ),

              SizedBox(height: 2.h),

              // Login button
              _buildOutlinedButton(
                theme: theme,
                label: 'Login',
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .pushNamed('/login-screen');
                },
              ),

              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the pet illustration section with decorative elements
  Widget _buildIllustration() {
    return SizedBox(
      height: 45.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative dots in background
          _buildDecorativeDots(),

          // Main pet illustration container
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: const Color(0xFFB2DFDB).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                'assets/images/icon__1_.png', // Your pet artwork
                width: 95.w,
                height: 95.w,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds decorative dots scattered around the illustration
  Widget _buildDecorativeDots() {
    return SizedBox(
      width: 80.w,
      height: 50.h,
      child: Stack(
        children: [
          // Top right dot
          Positioned(
            top: 5.0.h,
            right: 2.w,
            child: _buildDot(size: 25.w, color: const Color(0xFF006666)),
          ),
          // Top right dot 2
          Positioned(
            top: 25.h,
            right: 15.w,
            child: _buildDot(size: 10.w, color: const Color(0xFF008080)),
          ),
          // Bottom right dot
          Positioned(
            bottom: 8.h,
            right: 6.w,
            child: _buildDot(size: 6.5.w, color: const Color(0xFF004c4c)),
          ),
          // Bottom left dot
          Positioned(
            bottom: 12.h,
            left: 4.w,
            child: _buildDot(size: 6.w, color: const Color(0xFFb2d8d8)),
          ),
          // Top left dot
          Positioned(
            top: 18.h,
            left: 10.w,
            child: _buildDot(size: 12.w, color: const Color(0xFF66b2b2)),
          ),
        ],
      ),
    );
  }

  /// Builds a single decorative dot
  Widget _buildDot({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Builds a teal-themed button
  Widget _buildTealButton({
    required ThemeData theme,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 6.5.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Builds a teal-themed outlined button
  Widget _buildOutlinedButton({
    required ThemeData theme,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 6.5.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: theme.colorScheme.tertiary,
          side: BorderSide(color: theme.colorScheme.tertiary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.tertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
