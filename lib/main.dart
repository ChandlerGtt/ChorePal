// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/child/enhanced_child_dashboard.dart';
import 'screens/parent/enhanced_parent_dashboard.dart';
import 'models/chore_state.dart';
import 'models/reward_state.dart';
import 'models/user_state.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    runApp(
      MultiProvider(
        providers: [
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
    final primaryColor = const Color(0xFF4CAF50);
    final primaryColorDark = const Color(0xFF388E3C);
    final secondaryColor = const Color(0xFF2196F3);
    final backgroundColor = const Color(0xFFF5F5F5);
    final textColor = const Color(0xFF333333);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChorePal',
      theme: ThemeData(
        useMaterial3: false, // Ensure consistent behavior across app
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: Colors.white,
          background: backgroundColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        // App bar theme
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        // Tab bar theme - keep it simple and focused on preventing overlay
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xDDFFFFFF), 
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: EdgeInsets.symmetric(horizontal: 8),
          // These are the critical properties to prevent the white overlay
          overlayColor: MaterialStatePropertyAll(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
        ),
        // General text theme
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: const Color(0xFF666666),
          ),
        ),
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
        ),
        // Form field theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}