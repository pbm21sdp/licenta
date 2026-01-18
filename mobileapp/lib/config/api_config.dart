// lib/config/api_config.dart
// Configurare pentru conexiunea la backend API

class ApiConfig {
  // URL-ul backend-ului - schimbă pentru producție
  // Pentru emulator Android folosește 10.0.2.2 în loc de localhost
  // Pentru dispozitiv fizic folosește IP-ul computerului (ex: 192.168.1.100)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api/v1', // Pentru emulator Android
  );

  // Pentru iOS simulator sau web, folosește localhost
  static const String baseUrlIOS = 'http://localhost:5000/api/v1';

  // Pentru dispozitiv fizic, înlocuiește cu IP-ul computerului
  static const String baseUrlDevice = 'http://192.168.1.100:5000/api/v1';

  // Timeout pentru request-uri (în milisecunde)
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Endpoints pentru autentificare
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh-token';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // Endpoints pentru animale
  static const String pets = '/pets';
  static const String petSwipeFeed = '/pets/feed/swipe';
  static const String petSwipeUndo = '/pets/swipe/undo';
  static String petById(int id) => '/pets/$id';
  static String petSwipe(int id) => '/pets/$id/swipe';

  // Endpoints pentru favorite
  static const String favorites = '/favorites';
  static String favoriteById(int petId) => '/favorites/$petId';
  static String checkFavorite(int petId) => '/favorites/$petId/check';

  // Endpoints pentru adopții
  static const String adoptions = '/adoptions';
  static String adoptionById(int id) => '/adoptions/$id';

  // Endpoints pentru preferințe utilizator
  static const String preferences = '/preferences';

  // Endpoints pentru admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminPets = '/admin/pets';
  static const String adminAdoptions = '/admin/adoptions';
  static String adminPetById(int id) => '/admin/pets/$id';
  static String adminAdoptionById(int id) => '/admin/adoptions/$id';
  static String adminAdoptionStatus(int id) => '/admin/adoptions/$id/status';
  static String adminScheduleMeeting(int id) => '/admin/adoptions/$id/meeting';
}
