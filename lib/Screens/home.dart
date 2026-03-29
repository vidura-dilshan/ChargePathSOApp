import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'registerstation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // ── COLORS ────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0253A4);
  static const Color _accent  = Color(0xFF00C2FF);
  static const Color _teal    = Color(0xFF00E5C3);
  static const Color _bg      = Color(0xFFF0F5FC);

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── DISPLAY NAME ──────────────────────────────────────────────────────────
  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    final email = user?.email ?? '';
    if (email.isNotEmpty) {
      final prefix = email.split('@').first;
      return prefix
          .split(RegExp(r'[._\-]'))
          .map((w) => w.isNotEmpty
              ? '${w[0].toUpperCase()}${w.substring(1)}'
              : '')
          .join(' ')
          .trim();
    }
    return 'User';
  }

  // ── NAVIGATION ────────────────────────────────────────────────────────────
  void _goToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const RegisterStation(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  void _goToDashboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.dashboard_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('SO Dashboard — coming soon!',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size        = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TOP BAR ───────────────────────────────────────────
                    _buildTopBar(),
                    const SizedBox(height: 22),

                    // ── HEADING ───────────────────────────────────────────
                    _buildHeadingSection(),
                    const SizedBox(height: 26),

                    // ── SECTION LABEL ─────────────────────────────────────
                    _buildSectionLabel('QUICK ACTIONS'),
                    const SizedBox(height: 14),

                    // ── ACTION CARDS ──────────────────────────────────────
                    Expanded(
                      child: Padding(
                        // bottom padding = nav bar (72) + device safe area + breathing room
                        padding: EdgeInsets.fromLTRB(
                          22, 0, 22,
                          72 + bottomInset + 10,
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0253A4),
                                    Color(0xFF0B7FE8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                accentColor: _accent,
                                icon: Icons.add_location_alt_rounded,
                                label: 'Register Your\nStation',
                                description:
                                    'List your EV charging point on ChargePath and start earning today.',
                                badge: 'FREE',
                                badgeColor: Colors.greenAccent,
                                decorIcon: Icons.cell_tower_rounded,
                                onTap: _goToRegister,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _ActionCard(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0D47A1),
                                    Color(0xFF1565C0),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                accentColor: _teal,
                                icon: Icons.dashboard_rounded,
                                label: 'SO Dashboard',
                                description:
                                    'View sessions, revenue, and live status of your stations.',
                                badge: 'LIVE',
                                badgeColor: _teal,
                                decorIcon: Icons.bar_chart_rounded,
                                onTap: _goToDashboard,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0253A4), Color(0xFF00C2FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _displayName.isNotEmpty
                        ? _displayName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _displayName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2E),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications_outlined,
                  color: _primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADING SECTION ───────────────────────────────────────────────────────
  Widget _buildHeadingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Station Owner Portal',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Main headline with gradient word
          RichText(
            text: TextSpan(
              style: const TextStyle(
                height: 1.18,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(
                  text: 'Power the Future of', 
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D1B2E),
                  ),
                ),
                TextSpan(
                  text: '\nEV Charging',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF0253A4), Color(0xFF00C2FF)],
                      ).createShader(
                          const Rect.fromLTWH(0, 0, 160, 44)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle
          Text(
            'Manage · Monitor · Grow your charging network',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 16),

          // Decorative dot–dash row
          Row(
            children: List.generate(7, (i) {
              return Container(
                margin: const EdgeInsets.only(right: 5),
                width: i == 0 ? 30 : 6,
                height: 4,
                decoration: BoxDecoration(
                  color: i == 0
                      ? _primary
                      : _primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── SECTION LABEL ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade500,
              letterSpacing: 2.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── BACKGROUND ────────────────────────────────────────────────────────────
  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        Container(color: _bg),
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accent.withOpacity(0.10),
                  _accent.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primary.withOpacity(0.07),
                  _primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ACTION CARD
// ══════════════════════════════════════════════════════════════════════════════
class _ActionCard extends StatefulWidget {
  final LinearGradient gradient;
  final Color accentColor;
  final IconData icon;
  final String label;
  final String description;
  final String badge;
  final Color badgeColor;
  final IconData decorIcon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.gradient,
    required this.accentColor,
    required this.icon,
    required this.label,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.decorIcon,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Decorative large background icon
              Positioned(
                right: -28,
                bottom: -20,
                child: Icon(
                  widget.decorIcon,
                  size: 140,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              // Top-right circle
              Positioned(
                right: 14,
                top: -46,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withOpacity(0.08),
                  ),
                ),
              ),
              // Top shimmer line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor.withOpacity(0.0),
                        widget.accentColor.withOpacity(0.7),
                        widget.accentColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── CARD CONTENT ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Row: icon + badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Icon(widget.icon,
                              color: Colors.white, size: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.badgeColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: widget.badgeColor.withOpacity(0.45)),
                          ),
                          child: Text(
                            widget.badge,
                            style: TextStyle(
                              color: widget.badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Title + description + CTA
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // CTA pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  color: widget.gradient.colors.first,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: widget.gradient.colors.first,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}