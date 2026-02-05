import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:meza_restaurant/providers/theme_provider.dart';
import 'package:meza_restaurant/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:meza_restaurant/pages/homescreen.dart';
import 'package:meza_restaurant/pages/order_history.dart';
import 'package:meza_restaurant/pages/profile.dart';
import 'package:meza_restaurant/pages/settings.dart';
import 'package:meza_restaurant/pages/sign_in.dart';
import 'package:meza_restaurant/pages/sign_up.dart';
import 'package:meza_restaurant/pages/splashscreen.dart';
import 'package:meza_restaurant/pages/upload_dish.dart';
import 'package:meza_restaurant/theme/app_theme.dart';
import 'firebase_options.dart';

// Add required annotations for background services
@pragma('vm:entry-point')
void callbackDispatcher() {
  // This function is called by native code for background services
  WidgetsFlutterBinding.ensureInitialized();
  print("Background service callback dispatcher initialized");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Open Hive boxes
  await Hive.openBox('auth');
  await Hive.openBox('user');

  runApp(const MyApp());
}

// Create router as a final variable to prevent recreation
final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/sign_up',
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/orderhistory',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => const UploadDishScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.uri}',
        style: const TextStyle(color: Colors.red),
      ),
    ),
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: Builder(
        builder: (context) {
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp.router(
                title: 'MEZAHUB Restaurant',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                routerConfig: _router,
              );
            },
          );
        },
      ),
    );
  }
}