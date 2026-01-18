import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for help and support
/// Provides FAQ, contact options, and app information
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<_FAQItem> _faqItems = [
    _FAQItem(
      question: 'How do I submit an adoption application?',
      answer: 'Browse available pets, select one you\'re interested in, and tap the "Apply to Adopt" button on their profile. Fill out the application form with your information and submit it for review by the shelter.',
    ),
    _FAQItem(
      question: 'How long does the adoption process take?',
      answer: 'The process typically takes 2-7 days, depending on the shelter. You\'ll receive notifications about your application status, and the shelter may contact you for additional information or an interview.',
    ),
    _FAQItem(
      question: 'Can I save pets to view later?',
      answer: 'Yes! Tap the heart icon on any pet card or detail page to add them to your favorites. Access your saved pets anytime from the Favorites tab.',
    ),
    _FAQItem(
      question: 'How do I update my profile information?',
      answer: 'Go to the Account tab and tap "Edit Profile" to update your name, phone number, and profile photo.',
    ),
    _FAQItem(
      question: 'What happens after my application is approved?',
      answer: 'Once approved, the shelter will contact you to schedule a meet-and-greet with the pet and finalize the adoption paperwork and fees.',
    ),
    _FAQItem(
      question: 'Can I withdraw my application?',
      answer: 'Currently, you need to contact the shelter directly to withdraw an application. We recommend reaching out to them as soon as possible if you change your mind.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Help & Support', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact options
            _buildSectionHeader(theme, 'Contact Us'),
            SizedBox(height: 1.h),
            _buildContactCard(theme),

            SizedBox(height: 3.h),

            // FAQ Section
            _buildSectionHeader(theme, 'Frequently Asked Questions'),
            SizedBox(height: 1.h),
            _buildFAQCard(theme),

            SizedBox(height: 3.h),

            // App info
            _buildSectionHeader(theme, 'App Information'),
            SizedBox(height: 1.h),
            _buildAppInfoCard(theme),

            SizedBox(height: 3.h),

            // Feedback section
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_outline,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Love Paws?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Rate us on the app store to help other pet lovers find their perfect companion!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Thank you for your support!'),
                          backgroundColor: Color(0xFF4ECDC4),
                        ),
                      );
                    },
                    icon: Icon(Icons.star_outline),
                    label: Text('Rate the App'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
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

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildContactCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactItem(
            theme,
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@pawsapp.com',
            onTap: () => _launchEmail(),
          ),
          _buildDivider(theme),
          _buildContactItem(
            theme,
            icon: Icons.chat_outlined,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Live chat coming soon'),
                  backgroundColor: theme.colorScheme.primary,
                ),
              );
            },
          ),
          _buildDivider(theme),
          _buildContactItem(
            theme,
            icon: Icons.phone_outlined,
            title: 'Phone Support',
            subtitle: 'Mon-Fri, 9AM-5PM',
            onTap: () => _launchPhone(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: _faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildFAQTile(theme, item),
              if (index < _faqItems.length - 1) _buildDivider(theme),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFAQTile(ThemeData theme, _FAQItem item) {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 4.w),
      childrenPadding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 2.h),
      title: Text(
        item.question,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: theme.colorScheme.primary,
      collapsedIconColor: theme.colorScheme.onSurfaceVariant,
      children: [
        Text(
          item.answer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.08),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(theme, 'App Version', '1.0.0'),
          _buildDivider(theme),
          _buildInfoItem(theme, 'Build Number', '1'),
          _buildDivider(theme),
          _buildLinkItem(
            theme,
            title: 'Terms of Service',
            onTap: () => _showInfoDialog('Terms of Service'),
          ),
          _buildDivider(theme),
          _buildLinkItem(
            theme,
            title: 'Privacy Policy',
            onTap: () => _showInfoDialog('Privacy Policy'),
          ),
          _buildDivider(theme),
          _buildLinkItem(
            theme,
            title: 'Open Source Licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Paws',
              applicationVersion: '1.0.0',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(
    ThemeData theme, {
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
      height: 1,
      indent: 4.w,
      endIndent: 4.w,
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: 'support@pawsapp.com');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open email client'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchPhone() async {
    final uri = Uri(scheme: 'tel', path: '+1234567890');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showInfoDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            'This is a placeholder for the $title. '
            'In a production app, this would contain the full legal document.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;

  _FAQItem({required this.question, required this.answer});
}
