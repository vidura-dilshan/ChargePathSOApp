import 'dart:ui';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // ── COLORS ──────────────────────────────────────────────────────────────────
  static const Color _primaryColor    = Color(0xFF0253A4);
  static const Color _accentColor     = Color(0xFF00C2FF);
  static const Color _darkBg          = Color(0xFF011C3A);
  static const Color _cardDark        = Color(0xFF012B55);
  static const Color _lightFillColor  = Color(0xFFE6EFF8);

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── DISPLAY NAME ─────────────────────────────────────────────────────────────
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
          .map((w) =>
              w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ')
          .trim();
    }
    return 'User';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim  = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── NAVIGATE PLACEHOLDERS ────────────────────────────────────────────────────
  void _goToRegister() {
    // TODO: Navigator.push to your RegisterStationPage
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar('Register Your Station — coming soon!', Icons.cell_tower_rounded),
    );
  }

  void _goToDashboard() {
    // TODO: Navigator.push to your SODashboardPage
    ScaffoldMessenger.of(context).showSnackBar(
      _snackBar('SO Dashboard — coming soon!', Icons.dashboard_rounded),
    );
  }

  SnackBar _snackBar(String msg, IconData icon) => SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      );

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // ── DECORATIVE BACKGROUND ──────────────────────────────────────────
          _buildBackground(size),

          // ── CONTENT ───────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── TOP BAR ──────────────────────────────────────────────
                    _buildTopBar(),

                    const SizedBox(height: 10),

                    // ── HERO TAGLINE ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Station Owner\nPortal',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -1.0,
                              shadows: [
                                Shadow(
                                  color: _accentColor.withOpacity(0.3),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _accentColor.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'Manage · Monitor · Grow',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── STATS STRIP ───────────────────────────────────────────
                    _buildStatsStrip(),

                    const SizedBox(height: 36),

                    // ── SECTION LABEL ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'QUICK ACTIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── ACTION CARDS ─────────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        child: Column(
                          children: [
                            // REGISTER YOUR STATION
                            Expanded(
                              child: _ActionCard(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0253A4), Color(0xFF0372D9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                accentColor: _accentColor,
                                icon: Icons.cell_tower_rounded,
                                label: 'Register Your\nStation',
                                description:
                                    'List your EV charging point on ChargePath and start earning.',
                                badge: 'FREE',
                                badgeColor: Colors.greenAccent,
                                decorIcon: Icons.add_location_alt_rounded,
                                onTap: _goToRegister,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // SO DASHBOARD
                            Expanded(
                              child: _ActionCard(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF012B55), Color(0xFF01406E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                accentColor: const Color(0xFF00E5C3),
                                icon: Icons.dashboard_rounded,
                                label: 'SO Dashboard',
                                description:
                                    'View sessions, revenue, and live status of your stations.',
                                badge: 'LIVE',
                                badgeColor: const Color(0xFF00E5C3),
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

  // ── TOP BAR ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _glassBtn(Icons.notifications_outlined),
              const SizedBox(width: 10),
              _glassBtn(Icons.person_outline_rounded),
            ],
          ),
        ],
      ),
    );
  }

  // ── STATS STRIP ──────────────────────────────────────────────────────────────
  Widget _buildStatsStrip() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        children: const [
          _StatChip(value: '0', label: 'Stations', icon: Icons.ev_station_rounded),
          SizedBox(width: 12),
          _StatChip(value: '0', label: 'Sessions', icon: Icons.bolt_rounded),
          SizedBox(width: 12),
          _StatChip(value: 'Rs 0', label: 'Revenue', icon: Icons.account_balance_wallet_rounded),
          SizedBox(width: 12),
          _StatChip(value: '0', label: 'Reviews', icon: Icons.star_rounded),
        ],
      ),
    );
  }

  // ── DECORATIVE BACKGROUND ────────────────────────────────────────────────────
  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF011C3A), Color(0xFF01274F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Glowing orb top-right
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accentColor.withOpacity(0.18),
                  _accentColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Glowing orb bottom-left
        Positioned(
          bottom: 100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryColor.withOpacity(0.25),
                  _primaryColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Subtle dot grid
        CustomPaint(
          size: size,
          painter: _DotGridPainter(),
        ),
      ],
    );
  }

  Widget _glassBtn(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ── STAT CHIP ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatChip({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00C2FF), size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ACTION CARD ───────────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
                color: widget.gradient.colors.first.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // ── DECORATIVE LARGE ICON ────────────────────────────────────
              Positioned(
                right: -24,
                bottom: -20,
                child: Icon(
                  widget.decorIcon,
                  size: 150,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              // ── DECORATIVE CIRCLE ────────────────────────────────────────
              Positioned(
                right: 24,
                top: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withOpacity(0.08),
                  ),
                ),
              ),

              // ── CONTENT ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + Badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: widget.badgeColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            widget.badge,
                            style: TextStyle(
                              color: widget.badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Label
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // CTA Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  color: widget.gradient.colors.first,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
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

// ── DOT GRID PAINTER ─────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeCap = StrokeCap.round;

    const spacing = 28.0;
    final cols = (size.width / spacing).ceil();
    final rows = (size.height / spacing).ceil();

    for (int c = 0; c <= cols; c++) {
      for (int r = 0; r <= rows; r++) {
        canvas.drawCircle(
          Offset(c * spacing, r * spacing),
          1.2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}