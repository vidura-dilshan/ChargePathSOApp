import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Screens/email_verification.dart';
import 'Screens/login.dart';
import 'Screens/mainscreen.dart';
import 'Widgets/loadingscreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChargePath',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF0253A4,
          ),
        ),
        scaffoldBackgroundColor:
        const Color(
          0xFFF0F6FF,
        ),
        useMaterial3: true,
      ),
      home: const _AppStartup(),
    );
  }
}

// -----------------------------------------------------------------------------
// APPLICATION STARTUP
// -----------------------------------------------------------------------------

class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() =>
      _AppStartupState();
}

class _AppStartupState
    extends State<_AppStartup> {
  late final Future<void> _init;

  @override
  void initState() {
    super.initState();

    // Uses the Firebase configuration installed
    // in the native Android project.
    _init = Firebase.initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (
          BuildContext context,
          AsyncSnapshot<void> snapshot,
          ) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Text(
                  'Startup error:\n'
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
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

// -----------------------------------------------------------------------------
// AUTHENTICATION WRAPPER
// -----------------------------------------------------------------------------

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({
    super.key,
  });

  @override
  State<AuthWrapper> createState() =>
      _AuthWrapperState();
}

class _AuthWrapperState
    extends State<AuthWrapper> {
  /// Returns true when this user signed in using
  /// the Email/Password authentication provider.
  bool _usesPasswordProvider(
      User user,
      ) {
    return user.providerData.any(
          (UserInfo provider) =>
      provider.providerId == 'password',
    );
  }

  /// Called by EmailVerificationScreen after the
  /// user presses "I verified my email".
  ///
  /// The Firebase user was already reloaded by the
  /// verification screen, so rebuilding this widget
  /// is enough to re-check emailVerified.
  void _handleEmailVerified() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // userChanges is used instead of only authStateChanges.
      // This also reacts to user profile changes and reloads.
      stream:
      FirebaseAuth.instance.userChanges(),
      builder: (
          BuildContext context,
          AsyncSnapshot<User?> snapshot,
          ) {
        final Widget child;

        // Firebase is still checking the saved session.
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          child = const LoadingScreen(
            key: ValueKey(
              'loading',
            ),
          );
        }

        // Firebase authentication stream error.
        else if (snapshot.hasError) {
          child = Scaffold(
            key: const ValueKey(
              'error',
            ),
            body: Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Text(
                  'Authentication error:\n'
                      '${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            ),
          );
        }

        // No signed-in user.
        else if (!snapshot.hasData) {
          child = const LogIn(
            key: ValueKey(
              'login',
            ),
          );
        }

        // User is signed in.
        else {
          final User user =
          snapshot.data!;

          final bool usesPassword =
          _usesPasswordProvider(
            user,
          );

          // Email/password accounts must verify
          // their email before entering the SO app.
          if (usesPassword &&
              !user.emailVerified) {
            child =
                EmailVerificationScreen(
                  key: ValueKey(
                    'verify-${user.uid}',
                  ),
                  user: user,
                  onVerified:
                  _handleEmailVerified,
                );
          } else {
            // Google accounts normally arrive here
            // already verified by Google.
            //
            // Verified email/password users also
            // reach this screen.
            child = const MainScreen(
              key: ValueKey(
                'main',
              ),
            );
          }
        }

        return AnimatedSwitcher(
          duration:
          const Duration(
            milliseconds: 300,
          ),
          switchInCurve:
          Curves.easeIn,
          switchOutCurve:
          Curves.easeOut,
          transitionBuilder: (
              Widget child,
              Animation<double> animation,
              ) {
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