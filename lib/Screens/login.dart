import 'package:chargepathso/Widgets/loadingscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LogIn extends StatefulWidget {
  const LogIn({
    super.key,
  });

  @override
  State<LogIn> createState() =>
      _LogInState();
}

class _LogInState extends State<LogIn> {
  final TextEditingController
  _emailController =
  TextEditingController();

  final TextEditingController
  _passwordController =
  TextEditingController();

  static const String _stationOwnerRole = 'stationOwner';

  static const Set<String> _validRoles = {
    'driver',
    'stationOwner',
  };

  bool _isLogin = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  final Color _primaryColor =
  const Color(
    0xFF0253A4,
  );

  final Color _lightFillColor =
  const Color(
    0xFFE6EFF8,
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // VALIDATION
  // ---------------------------------------------------------------------------

  bool _validateInputs() {
    final String email =
    _emailController.text.trim();

    final String password =
    _passwordController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog(
        'Please enter your email address.',
      );

      return false;
    }

    if (!RegExp(
      r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
    ).hasMatch(email)) {
      _showErrorDialog(
        'Please enter a valid email address.',
      );

      return false;
    }

    if (password.isEmpty) {
      _showErrorDialog(
        'Please enter your password.',
      );

      return false;
    }

    if (!_isLogin &&
        password.length < 6) {
      _showErrorDialog(
        'Password must be at least 6 characters long.',
      );

      return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
// FIRESTORE ROLE MANAGEMENT
// ---------------------------------------------------------------------------

  Future<void> _addRoleToUser(
      User user,
      String newRole,
      ) async {
    final DocumentReference<Map<String, dynamic>> userReference =
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
    await userReference.get();

    final Set<String> roles = <String>{};

    bool hasLegacyRoleField = false;
    bool hasCreatedAt = false;

    if (snapshot.exists) {
      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      // Read roles from the new array format.
      final dynamic existingRoles = data['roles'];

      if (existingRoles is List) {
        for (final dynamic role in existingRoles) {
          if (role is String &&
              _validRoles.contains(role)) {
            roles.add(role);
          }
        }
      }

      // Migrate the old single role field automatically.
      if (data.containsKey('role')) {
        hasLegacyRoleField = true;

        final dynamic legacyRole = data['role'];

        if (legacyRole is String &&
            _validRoles.contains(legacyRole)) {
          roles.add(legacyRole);
        }
      }

      hasCreatedAt =
          data.containsKey('createdAt');
    }

    // Add Station Owner access while preserving Driver access.
    roles.add(newRole);

    final Map<String, dynamic> profileData = {
      'email': user.email,
      'roles': roles.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists || !hasCreatedAt) {
      profileData['createdAt'] =
          FieldValue.serverTimestamp();
    }

    // Remove the old role field after migration.
    if (hasLegacyRoleField) {
      profileData['role'] =
          FieldValue.delete();
    }

    await userReference.set(
      profileData,
      SetOptions(
        merge: true,
      ),
    );
  }

// ---------------------------------------------------------------------------
// MIGRATE OLD ROLE WITHOUT ADDING STATION OWNER ACCESS
// ---------------------------------------------------------------------------

  Future<void> _migrateLegacyRole(
      User user,
      ) async {
    final DocumentReference<Map<String, dynamic>> userReference =
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
    await userReference.get();

    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    // Already using the new roles array.
    if (data['roles'] is List) {
      if (data.containsKey('role')) {
        await userReference.update({
          'role': FieldValue.delete(),
        });
      }

      return;
    }

    final dynamic oldRole = data['role'];

    if (oldRole is! String ||
        !_validRoles.contains(oldRole)) {
      return;
    }

    await userReference.update({
      'roles': [
        oldRole,
      ],
      'role': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
// EXISTING CHARGEPATH ACCOUNT DIALOG
// ---------------------------------------------------------------------------

  Future<void> _showExistingAccountDialog() async {
    if (!mounted) {
      return;
    }

    // Stop the loading screen before showing the dialog.
    setState(() {
      _isLoading = false;
    });

    final bool? goToLogin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'ChargePath Account Already Exists',
          ),
          content: const Text(
            'This email is already registered with ChargePath.\n\n'
                'If you created this account in the Driver app, you can use '
                'the same credentials to log in to the Station Owner app.\n\n'
                'You do not need to create another account.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Go to Login',
              ),
            ),
          ],
        );
      },
    );

    if (goToLogin == true && mounted) {
      setState(() {
        // Change the UI from Sign Up to Login.
        _isLogin = true;
      });

      // We intentionally keep the email and password fields filled.
      // The user can immediately press Login using the same credentials.
    }
  }

// ---------------------------------------------------------------------------
// SO APP REGISTRATION
// ---------------------------------------------------------------------------

  Future<String?> _registerStationOwnerAccount() async {
    final String email =
    _emailController.text.trim();

    final String password =
    _passwordController.text.trim();

    try {
      // ---------------------------------------------------------
      // TRY TO CREATE A BRAND-NEW FIREBASE ACCOUNT
      // ---------------------------------------------------------

      final UserCredential credential =
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        return 'Unable to create the account.';
      }

      // This account was created through the Station Owner app.
      await _addRoleToUser(
        user,
        _stationOwnerRole,
      );

      // Email/password accounts must verify their email.
      await user.sendEmailVerification();

      return null;
    } on FirebaseAuthException catch (error) {
      // ---------------------------------------------------------
      // ACCOUNT ALREADY EXISTS
      // ---------------------------------------------------------

      if (error.code == 'email-already-in-use') {
        await _showExistingAccountDialog();

        // This is not treated as a normal error anymore.
        // The user is redirected to the Login mode instead.
        return null;
      }

      // Any other Firebase error is handled by _authenticate().
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // EMAIL / PASSWORD AUTHENTICATION
  // ---------------------------------------------------------------------------

  Future<void> _authenticate() async {
    if (!_validateInputs()) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Normal login.
        final UserCredential credential =
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final User? user = credential.user;

        if (user != null) {
          // The user successfully authenticated in the Station Owner app.
          // Preserve any existing Driver role and add Station Owner access.
          await _addRoleToUser(
            user,
            _stationOwnerRole,
          );
        }
      } else {
        // Create SO account or add SO access
        // to an existing ChargePath account.
        final String? errorMessage =
        await _registerStationOwnerAccount();

        if (errorMessage != null) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }

          _showErrorDialog(errorMessage);
          return;
        }
      }

      // AuthWrapper handles navigation.
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      String errorMessage;

      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage =
          'The email or password is incorrect.';
          break;

        case 'weak-password':
          errorMessage =
          'The password provided is too weak.';
          break;

        case 'invalid-email':
          errorMessage =
          'The email address is invalid.';
          break;

        case 'network-request-failed':
          errorMessage =
          'Please check your internet connection.';
          break;

        case 'operation-not-allowed':
          errorMessage =
          'Email and password authentication is not enabled.';
          break;

        case 'too-many-requests':
          errorMessage =
          'Too many attempts were made. '
              'Please try again later.';
          break;

        default:
          errorMessage =
              error.message ??
                  'Authentication failed.';
      }

      _showErrorDialog(errorMessage);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      debugPrint(
        'Authentication error: $error',
      );

      _showErrorDialog(
        'An unexpected error occurred.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // FORGOT PASSWORD
  // ---------------------------------------------------------------------------

  Future<void> _resetPassword() async {
    final String email =
    _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorDialog(
        'Please enter your email address before resetting your password.',
      );

      return;
    }

    if (!RegExp(
      r"^[^\s@]+@[^\s@]+\.[^\s@]+$",
    ).hasMatch(email)) {
      _showErrorDialog(
        'Please enter a valid email address.',
      );

      return;
    }

    FocusManager
        .instance.primaryFocus
        ?.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (
            BuildContext dialogContext,
            ) {
          return AlertDialog(
            title: const Text(
              'Password Reset Email Sent',
            ),
            content: Text(
              'A password reset link has been sent to $email. '
                  'Please check your inbox and spam folder.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                },
                child: const Text(
                  'Okay',
                ),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      String errorMessage;

      switch (error.code) {
        case 'invalid-email':
          errorMessage =
          'The email address is invalid.';
          break;

        case 'user-not-found':
          errorMessage =
          'No account was found with this email address.';
          break;

        case 'network-request-failed':
          errorMessage =
          'Please check your internet connection.';
          break;

        case 'too-many-requests':
          errorMessage =
          'Too many reset attempts were made. '
              'Please try again later.';
          break;

        default:
          errorMessage =
              error.message ??
                  'Unable to send the password reset email.';
      }

      _showErrorDialog(
        errorMessage,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _showErrorDialog(
        'An unexpected error occurred.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE SIGN-IN
  // ---------------------------------------------------------------------------

  Future<void> _signInWithGoogle() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn =
      GoogleSignIn();

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential =
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential firebaseCredential =
      await FirebaseAuth.instance
          .signInWithCredential(
        credential,
      );

      final User? user =
          firebaseCredential.user;

      if (user != null) {
        // Google login through the SO app grants
        // Station Owner access while preserving Driver access.
        await _addRoleToUser(
          user,
          _stationOwnerRole,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _showErrorDialog(
        error.message ??
            'Google authentication failed.',
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      debugPrint(
        'GOOGLE SIGN-IN ERROR: $error',
      );

      _showErrorDialog(
        'Google Sign-In failed.\n\n$error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR DIALOG
  // ---------------------------------------------------------------------------

  void _showErrorDialog(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title: const Text(
            'Action Required',
          ),
          content: Text(
            message,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Okay',
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final Size size =
        MediaQuery.of(context).size;

    return Stack(
      children: [
        Scaffold(
          backgroundColor:
          Colors.white,
          body:
          SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipPath(
                      clipper:
                      BottomWaveClipper(),
                      child: Container(
                        height:
                        size.height *
                            0.32,
                        width:
                        double.infinity,
                        color:
                        _primaryColor
                            .withValues(
                          alpha: 0.8,
                        ),
                        child: Stack(
                          fit:
                          StackFit.expand,
                          children: [
                            Image.asset(
                              'lib/Assets/loginimage.jpeg',
                              fit:
                              BoxFit.cover,
                              errorBuilder: (
                                  BuildContext
                                  context,
                                  Object error,
                                  StackTrace?
                                  stackTrace,
                                  ) {
                                return Container(
                                  color:
                                  _primaryColor,
                                );
                              },
                            ),

                            Container(
                              color:
                              Colors.black
                                  .withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      top: 50,
                      left: 20,
                      child: InkWell(
                        onTap: () {
                          if (Navigator
                              .canPop(
                            context,
                          )) {
                            Navigator.pop(
                              context,
                            );
                          }
                        },
                        child: Container(
                          padding:
                          const EdgeInsets
                              .all(
                            8,
                          ),
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.white,
                            shape:
                            BoxShape.circle,
                          ),
                          child:
                          const Icon(
                            Icons
                                .arrow_back,
                            color:
                            Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isLogin
                                  ? 'Welcome Back'
                                  : 'Create Account',
                              style:
                              TextStyle(
                                fontSize: 32,
                                fontWeight:
                                FontWeight
                                    .bold,
                                color:
                                _primaryColor,
                              ),
                            ),
                          ),

                          Container(
                            height: 40,
                            width: 40,
                            decoration:
                            BoxDecoration(
                              color:
                              _primaryColor,
                              shape: BoxShape
                                  .circle,
                            ),
                            child:
                            const Icon(
                              Icons
                                  .ev_station_rounded,
                              color:
                              Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        _isLogin
                            ? 'Login to your account'
                            : 'Sign up to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors
                              .grey[600],
                        ),
                      ),

                      const SizedBox(
                        height: 25,
                      ),

                      _buildCustomTextField(
                        controller:
                        _emailController,
                        hintText:
                        'Email Address',
                        icon: Icons
                            .email_outlined,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      _buildCustomTextField(
                        controller:
                        _passwordController,
                        hintText:
                        'Password',
                        icon: Icons
                            .lock_outline,
                        isPassword: true,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      if (_isLogin)
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child:
                              Checkbox(
                                value:
                                _rememberMe,
                                activeColor:
                                _primaryColor,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    4,
                                  ),
                                ),
                                onChanged:
                                    (bool?
                                value) {
                                  setState(
                                        () {
                                      _rememberMe =
                                          value ??
                                              false;
                                    },
                                  );
                                },
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child: Text(
                                'Remember me',
                                style:
                                TextStyle(
                                  color: Colors
                                      .grey[
                                  600],
                                ),
                              ),
                            ),

                            TextButton(
                              onPressed:
                              _resetPassword,
                              child: Text(
                                'Forgot Password?',
                                style:
                                TextStyle(
                                  color:
                                  _primaryColor,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(
                        height: 25,
                      ),

                      SizedBox(
                        width:
                        double.infinity,
                        height: 55,
                        child:
                        ElevatedButton(
                          onPressed:
                          _authenticate,
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            _primaryColor,
                            foregroundColor:
                            Colors.white,
                            elevation: 0,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                30,
                              ),
                            ),
                          ),
                          child: Text(
                            _isLogin
                                ? 'Login'
                                : 'Create Account',
                            style:
                            const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Flexible(
                            child: Text(
                              _isLogin
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style:
                              TextStyle(
                                color: Colors
                                    .grey[600],
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              setState(
                                    () {
                                  _isLogin =
                                  !_isLogin;
                                },
                              );
                            },
                            child: Text(
                              _isLogin
                                  ? 'Sign up'
                                  : 'Login',
                              style:
                              TextStyle(
                                color:
                                _primaryColor,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      Center(
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors
                                .grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width:
                        double.infinity,
                        height: 55,
                        child:
                        OutlinedButton.icon(
                          onPressed:
                          _signInWithGoogle,
                          style:
                          OutlinedButton
                              .styleFrom(
                            side:
                            BorderSide(
                              color: Colors
                                  .grey
                                  .shade300,
                            ),
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                30,
                              ),
                            ),
                          ),
                          icon:
                          Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (
                                BuildContext
                                context,
                                Object error,
                                StackTrace?
                                stackTrace,
                                ) {
                              return const Icon(
                                Icons
                                    .account_circle_outlined,
                              );
                            },
                          ),
                          label:
                          const Text(
                            'Sign in with Google',
                            style:
                            TextStyle(
                              color: Colors
                                  .black87,
                              fontSize: 16,
                              fontWeight:
                              FontWeight
                                  .w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_isLoading)
          const Positioned.fill(
            child:
            LoadingScreen(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TEXT FIELD
  // ---------------------------------------------------------------------------

  Widget _buildCustomTextField({
    required TextEditingController
    controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _lightFillColor,
        borderRadius:
        BorderRadius.circular(
          15,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText:
        isPassword &&
            !_isPasswordVisible,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons
                  .visibility
                  : Icons
                  .visibility_off,
              color:
              Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible =
                !_isPasswordVisible;
              });
            },
          )
              : null,
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets
              .symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// HEADER WAVE
// -----------------------------------------------------------------------------

class BottomWaveClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(
      Size size,
      ) {
    final Path path =
    Path();

    path.lineTo(
      0,
      size.height - 40,
    );

    final Offset firstControlPoint =
    Offset(
      size.width / 4,
      size.height,
    );

    final Offset firstEndPoint =
    Offset(
      size.width / 2.25,
      size.height - 30,
    );

    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final Offset secondControlPoint =
    Offset(
      size.width -
          (size.width / 3.25),
      size.height - 80,
    );

    final Offset secondEndPoint =
    Offset(
      size.width,
      size.height - 40,
    );

    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(
      size.width,
      0,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
      CustomClipper<Path> oldClipper,
      ) {
    return false;
  }
}