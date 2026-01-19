import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/favorites_screen/favorites_screen.dart';
import '../presentation/main_pets_screen/main_pets_screen.dart';
import '../presentation/register_screen/register_screen.dart';
import '../presentation/welcome_screen/welcome_screen.dart';
import '../presentation/onboarding_questionnaire/onboarding_questionnaire.dart';
import '../presentation/pet_detail_screen/pet_detail_screen.dart';
import '../presentation/account_management_screen/account_management_screen.dart';
import '../presentation/chat_screen/chat_screen.dart';
import '../presentation/reset_password_screen/reset_password_screen.dart';
import '../presentation/settings/notification_preferences_screen.dart';
import '../presentation/settings/account_security_screen.dart';
import '../presentation/settings/privacy_controls_screen.dart';
import '../presentation/settings/help_support_screen.dart';
// Shelter screens
import '../presentation/shelter/shelter_dashboard_screen.dart';
import '../presentation/shelter/application_detail_screen.dart';
import '../presentation/shelter/shelter_pet_editor_screen.dart';

class AppRoutes {
  // Adopter routes
  static const String initial = '/';
  static const String login = '/login-screen';
  static const String favorites = '/favorites-screen';
  static const String mainPets = '/main-pets-screen';
  static const String register = '/register-screen';
  static const String welcome = '/welcome-screen';
  static const String onboardingQuestionnaire = '/onboarding-questionnaire';
  static const String petDetail = '/pet-detail-screen';
  static const String profileScreen = '/profile-screen';
  static const String chatScreen = '/chat-screen';
  static const String resetPassword = '/reset-password-screen';
  static const String notificationPreferences = '/notification-preferences';
  static const String accountSecurity = '/account-security';
  static const String privacyControls = '/privacy-controls';
  static const String helpSupport = '/help-support';

  // Shelter staff routes
  static const String shelterDashboard = '/shelter-dashboard';
  static const String shelterApplicationDetail = '/shelter-application-detail';
  static const String shelterPetEditor = '/shelter-pet-editor';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const WelcomeScreen(),
    login: (context) => const LoginScreen(),
    favorites: (context) => const FavoritesScreen(),
    mainPets: (context) => const MainPetsScreen(),
    register: (context) => const RegisterScreen(),
    welcome: (context) => const WelcomeScreen(),
    onboardingQuestionnaire: (context) => const OnboardingQuestionnaire(),
    petDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PetDetailScreen(pet: args ?? {});
    },
    profileScreen: (context) => const AccountManagementScreen(),
    chatScreen: (context) => const ChatScreen(),
    resetPassword: (context) => const ResetPasswordScreen(),
    notificationPreferences: (context) => const NotificationPreferencesScreen(),
    accountSecurity: (context) => const AccountSecurityScreen(),
    privacyControls: (context) => const PrivacyControlsScreen(),
    helpSupport: (context) => const HelpSupportScreen(),
    // Shelter staff routes
    shelterDashboard: (context) => const ShelterDashboardScreen(),
    shelterApplicationDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ApplicationDetailScreen(
        applicationId: args?['applicationId'] as String? ?? '',
      );
    },
    shelterPetEditor: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ShelterPetEditorScreen(
        petId: args?['petId'] as String?,
        shelterId: args?['shelterId'] as String?,
      );
    },
  };
}