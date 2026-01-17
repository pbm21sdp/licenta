import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './main_pets_screen_initial_page.dart';

class MainPetsScreen extends StatefulWidget {
  const MainPetsScreen({super.key});

  @override
  MainPetsScreenState createState() => MainPetsScreenState();
}

class MainPetsScreenState extends State<MainPetsScreen> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  final List<String> routes = [
    '/main-pets-screen',
    '/favorites-screen',
    '/chat-screen',
    '/profile-screen',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/main-pets-screen',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/main-pets-screen':
            case '/':
              return MaterialPageRoute(
                builder: (context) => const MainPetsScreenInitialPage(),
                settings: settings,
              );
            default:
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
