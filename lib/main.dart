import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'providers/pet_provider.dart';
import 'providers/vaccination_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/post_provider.dart';
import 'providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => VaccinationProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Pet Vaccination Diary',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Wrapper để handle auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  Timer? _dailyCheckTimer;

  @override
  void initState() {
    super.initState();
    _initSplash();
    _startDailyVaccinationCheck();
  }

  @override
  void dispose() {
    _dailyCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSplash() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  void _startDailyVaccinationCheck() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _checkVaccinationReminders();
      }
    });

    _dailyCheckTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      if (mounted) {
        _checkVaccinationReminders();
      }
    });
  }

  Future<void> _checkVaccinationReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        print('🔔 Checking vaccination reminders...');

        if (mounted) {
          await context
              .read<NotificationProvider>()
              .checkVaccinationReminders();
        }

        print('✅ Vaccination reminders checked');
      }
    } catch (e) {
      print('❌ Error in daily vaccination check: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print(
          '🔄 StreamBuilder - ConnectionState: ${snapshot.connectionState}',
        );
        print('🔄 StreamBuilder - Has data: ${snapshot.hasData}');
        print('🔄 StreamBuilder - User: ${snapshot.data?.uid ?? "null"}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('📧 User email verified: ${user.emailVerified}');

          if (user.emailVerified) {
            print('✅ Email verified - Navigating to HomeScreen');
            return const HomeScreen();
          } else {
            print('⚠️ Email not verified - staying on LoginScreen');
            return const LoginScreen();
          }
        }

        print('➡️ No user - Navigating to LoginScreen');
        return const LoginScreen();
      },
    );
  }
}
