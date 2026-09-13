import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.user,
    required this.onVerified,
  });

  final User user;
  final VoidCallback onVerified;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  static const Color _primaryColor = Color(0xFF0253A4);
  static const Color _backgroundColor = Color(0xFFF0F6FF);
  static const Color _lightFillColor = Color(0xFFE6EFF8);
  static const Color _textSecondary = Color(0xFF667085);

  bool _isChecking = false;
  bool _isSending = false;

  // ---------------------------------------------------------------------------
  // CHECK WHETHER THE USER VERIFIED THEIR EMAIL
  // ---------------------------------------------------------------------------

  Future<void> _checkVerification() async {
    if (_isChecking) {
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      // Refresh the Firebase user information.
      await widget.user.reload();

      final User? refreshedUser =
          FirebaseAuth.instance.currentUser;

      if (refreshedUser != null &&
          refreshedUser.emailVerified) {
        // Tell AuthWrapper to rebuild.
        widget.onVerified();
        return;
      }

      _showMessage(
        'Email not verified yet. Please check your inbox.',
      );
    } on FirebaseAuthException catch (error) {
      _showMessage(
        error.message ??
            'Could not check verification status.',
      );
    } catch (_) {
      _showMessage(
        'Could not check verification status.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // RESEND VERIFICATION EMAIL
  // ---------------------------------------------------------------------------

  Future<void> _resendVerification() async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        _showMessage(
          'Your session has expired. Please sign in again.',
        );
        return;
      }

      await currentUser.sendEmailVerification();

      _showMessage(
        'Verification email sent.',
      );
    } on FirebaseAuthException catch (error) {
      String message;

      switch (error.code) {
        case 'too-many-requests':
          message =
          'Too many verification emails were requested. '
              'Please try again later.';
          break;

        case 'network-request-failed':
          message =
          'Please check your internet connection.';
          break;

        default:
          message =
              error.message ??
                  'Could not send verification email.';
      }

      _showMessage(message);
    } catch (_) {
      _showMessage(
        'Could not send verification email.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT / USE DIFFERENT ACCOUNT
  // ---------------------------------------------------------------------------

  Future<void> _signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Google Sign-In may not be active for an email/password account.
    }

    await FirebaseAuth.instance.signOut();
  }

  // ---------------------------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
    ScaffoldMessenger.of(context);

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
          BuildContext context,
          BoxConstraints constraints,
          ) {
        final bool useWideLayout =
            constraints.maxWidth >= 800;

        final bool isShortHeight =
            constraints.maxHeight < 620;

        if (useWideLayout) {
          return _buildWideLayout(
            isShortHeight: isShortHeight,
          );
        }

        return _buildMobileLayout(
          isShortHeight: isShortHeight,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout({
    required bool isShortHeight,
  }) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildMobileHeader(
              isShortHeight: isShortHeight,
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  isShortHeight ? 16 : 32,
                  24,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                child: _buildVerificationCard(
                  compact: isShortHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader({
    required bool isShortHeight,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        isShortHeight ? 16 : 24,
        24,
        isShortHeight ? 24 : 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0253A4),
            Color(0xFF034485),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: isShortHeight ? 40 : 46,
            height: isShortHeight ? 40 : 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.20,
                ),
              ),
            ),
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                    isShortHeight ? 20 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (!isShortHeight) ...[
                  const SizedBox(height: 3),

                  Text(
                    'One final step before you continue.',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.80,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLET / WIDE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildWideLayout({
    required bool isShortHeight,
  }) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: _buildBrandPanel(
                isShortHeight: isShortHeight,
              ),
            ),

            Expanded(
              flex: 5,
              child: Container(
                color: _backgroundColor,
                child: Center(
                  child: SingleChildScrollView(
                    physics:
                    const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal:
                      isShortHeight ? 32 : 48,
                      vertical:
                      isShortHeight ? 16 : 48,
                    ),
                    child: ConstrainedBox(
                      constraints:
                      const BoxConstraints(
                        maxWidth: 520,
                      ),
                      child: _buildVerificationCard(
                        compact: isShortHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandPanel({
    required bool isShortHeight,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0253A4),
            Color(0xFF034485),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/Assets/loginimage.jpeg',
            fit: BoxFit.cover,
            color: const Color(0xFF012B55)
                .withValues(
              alpha: 0.58,
            ),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                ) {
              return const SizedBox.shrink();
            },
          ),

          Padding(
            padding: EdgeInsets.all(
              isShortHeight ? 28 : 48,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: isShortHeight ? 52 : 66,
                  height: isShortHeight ? 52 : 66,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.16,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      isShortHeight ? 16 : 20,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.28,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.ev_station_rounded,
                    color: Colors.white,
                    size:
                    isShortHeight ? 28 : 34,
                  ),
                ),

                const Spacer(),

                Text(
                  'Almost there.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                    isShortHeight ? 30 : 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height:
                  isShortHeight ? 8 : 12,
                ),

                Text(
                  'Verify your email to finish setting up '
                      'your ChargePath Station Owner account.',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.82,
                    ),
                    fontSize:
                    isShortHeight ? 14 : 17,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                Text(
                  'Manage your charging stations with ChargePath.',
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.68,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VERIFICATION CARD
  // ---------------------------------------------------------------------------

  Widget _buildVerificationCard({
    required bool compact,
  }) {
    final String email =
        widget.user.email ??
            'your email address';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: compact ? 62 : 76,
              height: compact ? 62 : 76,
              decoration: const BoxDecoration(
                color: _lightFillColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_rounded,
                color: _primaryColor,
                size: compact ? 30 : 36,
              ),
            ),
          ),

          SizedBox(
            height: compact ? 16 : 24,
          ),

          Text(
            'Verify your email',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _primaryColor,
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(
            height: compact ? 8 : 12,
          ),

          Text(
            'We sent a verification link to',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: compact ? 13 : 14,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: _lightFillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.email_rounded,
                  color: _primaryColor,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    email,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: compact ? 18 : 26,
          ),

          const Row(
            children: [
              Icon(
                Icons.checklist_rounded,
                color: _primaryColor,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'What to do next',
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(
            height: compact ? 12 : 16,
          ),

          _buildStep(
            number: 1,
            text:
            'Open the verification email sent by ChargePath.',
          ),

          const SizedBox(height: 10),

          _buildStep(
            number: 2,
            text:
            'Tap the verification link in the email.',
          ),

          const SizedBox(height: 10),

          _buildStep(
            number: 3,
            text:
            'Return here and tap the verification button.',
          ),

          SizedBox(
            height: compact ? 20 : 28,
          ),

          SizedBox(
            height: compact ? 48 : 54,
            child: ElevatedButton.icon(
              onPressed:
              _isChecking
                  ? null
                  : _checkVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                _primaryColor.withValues(
                  alpha: 0.55,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _isChecking
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.verified_rounded,
              ),
              label: Text(
                _isChecking
                    ? 'Checking...'
                    : 'I verified my email',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(
            height: compact ? 10 : 14,
          ),

          SizedBox(
            height: compact ? 48 : 54,
            child: OutlinedButton.icon(
              onPressed:
              _isSending
                  ? null
                  : _resendVerification,
              icon: _isSending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryColor,
                ),
              )
                  : const Icon(
                Icons.outgoing_mail,
                size: 19,
              ),
              label: Text(
                _isSending
                    ? 'Sending...'
                    : 'Resend email',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(
                  color: _primaryColor,
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          TextButton(
            onPressed: _signOut,
            child: const Text(
              'Use a different account',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String text,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Padding(
            padding:
            const EdgeInsets.only(
              top: 3,
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}