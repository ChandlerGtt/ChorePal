// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'models/chore_state.dart';
import 'models/reward_state.dart';
import 'models/user_state.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/splash_screen.dart';
import 'services/theme_service.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notification service
    await NotificationService().initialize();

    // Initialize auth service with persistence
    await AuthService().initialize();

    // Initialize theme service first
    final themeService = await ThemeService.create();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeService),
          ChangeNotifierProvider(create: (context) => UserState()),
          ChangeNotifierProvider(create: (context) => ChoreState()),
          ChangeNotifierProvider(create: (context) => RewardState()),
        ],
        child: const ChoreApp(),
      ),
    );
  } catch (e) {
    // If Firebase fails to initialize, show error app
    runApp(const ErrorApp());
  }
}

/// Error app shown when Firebase initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChorePal - Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'ChorePal couldn\'t start properly. Please check your internet connection and try again.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChoreApp extends StatelessWidget {
  const ChoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ChorePal',
          theme: themeService.getLightTheme(),
          darkTheme: themeService.getDarkTheme(),
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            // Wrap with MediaQuery to ensure proper scaling
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          home: StreamBuilder<User?>(
            stream: AuthService().authStateChanges,
            builder: (context, snapshot) {
              // Show splash screen while checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              // Show auth wrapper if user is logged in, login screen if not
              if (snapshot.hasData) {
                return const AuthWrapper();
              } else {
                return const LoginScreen();
              }
            },
          ),
        );
      },
    );
  }
}
