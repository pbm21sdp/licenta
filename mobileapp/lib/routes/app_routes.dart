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
import '../presentation/add_pet_screen/add_pet_screen.dart';
import '../presentation/edit_pet_screen/edit_pet_screen.dart';
import '../presentation/public_profile_screen/public_profile_screen.dart';
import '../presentation/adoption_requests_screen/adoption_requests_screen.dart';

class AppRoutes {
  // TODO: Add routes here
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
  static const String addPet = '/add-pet';
  static const String editPet = '/edit-pet';
  static const String publicProfile = '/public-profile';
  static const String adoptionRequests = '/adoption-requests';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const WelcomeScreen(),
    login: (context) => const LoginScreen(),
    favorites: (context) => const FavoritesScreen(),
    mainPets: (context) => const MainPetsScreen(),
    register: (context) => const RegisterScreen(),
    welcome: (context) => const WelcomeScreen(),
    onboardingQuestionnaire: (context) => const OnboardingQuestionnaire(),
    petDetail: (context) => const PetDetailScreen(),
    profileScreen: (context) => const AccountManagementScreen(),
    chatScreen: (context) => const ChatScreen(),
    addPet: (context) => const AddPetScreen(),
    editPet: (context) => const EditPetScreen(),
    publicProfile: (context) => const PublicProfileScreen(),
    adoptionRequests: (context) => const AdoptionRequestsScreen(),
  };
}
