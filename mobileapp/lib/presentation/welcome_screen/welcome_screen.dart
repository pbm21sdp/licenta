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
              RepaintBoundary(
                child: _buildIllustration(context),
              ),

              SizedBox(height: 1.h),

              // App title
              Text(
                'Paws',
                style: TextStyle(
                  fontFamily: 'Cinthya',
                  fontSize: 60.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),

              SizedBox(height: 2.h),

              // Subtitle
              Text(
                'Match with your\nperfect pet companion',
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
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/register-screen');
                },
              ),

              SizedBox(height: 2.h),

              // Login button
              _buildOutlinedButton(
                theme: theme,
                label: 'Login',
                onPressed: () {
                  Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/login-screen');
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
  Widget _buildIllustration(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;

    // limitează dimensiunea ca să nu explodeze pe ecrane mari
    final double circleSize = (70.w).clamp(220.0, 320.0);
    final double imageSize = (60.w).clamp(200.0, 280.0);

    return SizedBox(
      height: (45.h).clamp(260.0, 360.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildDecorativeDots(),

          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: const Color(0xFFE8B8C8).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/icon__1_.png',
              width: imageSize,
              height: imageSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
              // SUPER important: decode la dimensiune apropiată de ce afișezi
              cacheWidth: (imageSize * dpr).round(),
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
          // Top right dot - Rose shades
          Positioned(
            top: 5.0.h,
            right: 2.w,
            child: _buildDot(
              size: 14.w,
              color: const Color(0xFFD4A0B0),
            ), // Deep rose
          ),
          // Top right dot 2
          Positioned(
            top: 25.h,
            right: 15.w,
            child: _buildDot(size: 6.w, color: const Color(0xFFE8B8C8)), // Rose
          ),
          // Bottom right dot
          Positioned(
            bottom: 8.h,
            right: 6.w,
            child: _buildDot(
              size: 4.5.w,
              color: const Color(0xFF8A8587),
            ), // Grey taupe
          ),
          // Bottom left dot
          Positioned(
            bottom: 12.h,
            left: 4.w,
            child: _buildDot(
              size: 4.w,
              color: const Color(0xFFF0D0DC),
            ), // Light rose
          ),
          // Top left dot
          Positioned(
            top: 18.h,
            left: 10.w,
            child: _buildDot(
              size: 8.w,
              color: const Color(0xFFB0ADAF),
            ), // Light taupe
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  /// Builds a primary-themed button
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
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Builds a primary-themed outlined button
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
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
