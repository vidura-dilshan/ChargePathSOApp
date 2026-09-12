import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Screens/login.dart';
import 'Screens/mainscreen.dart';
import 'Widgets/loadingscreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChargePath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0253A4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F6FF),
        useMaterial3: true,
      ),
      home: const _AppStartup(),
    );
  }
}

// ── STARTUP ──────────────────────────────────────────────────────────────────

class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  late final Future<void> _init;

  @override
  void initState() {
    super.initState();

    // Uses the Firebase configuration already installed
    // in the native Android/iOS project.
    _init = Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Startup error:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          );
        }

        return const AuthWrapper();
      },
    );
  }
}

// ── AUTH WRAPPER ─────────────────────────────────────────────────────────────

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final Widget child;

        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const LoadingScreen(
            key: ValueKey('loading'),
          );
        } else if (snapshot.hasError) {
          child = Scaffold(
            key: const ValueKey('error'),
            body: Center(
              child: Text(
                'Authentication error:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (snapshot.hasData) {
          child = const MainScreen(
            key: ValueKey('main'),
          );
        } else {
          child = const LogIn(
            key: ValueKey('login'),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }
}