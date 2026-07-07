import 'package:flutter/material.dart';
import 'registerstation.dart';

class SoDashboard extends StatelessWidget {
  const SoDashboard({super.key});

  // ── THEME ──────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0253A4);
  static const Color _primaryLight = Color(0xFF2979D4);
  static const Color _primaryDark = Color(0xFF013C78);
  static const Color _primarySurface = Color(0xFFE6EFF8);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE4EAF2);
  static const Color _green = Color(0xFF16A34A);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14, 18, 14, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(),

                  const SizedBox(height: 18),

                  _buildMyStationsSection(context),

                  const SizedBox(height: 18),

                  _buildWeeklyEarningsSection(),

                  const SizedBox(height: 18),

                  _buildWeeklyVehiclesSection(),

                  const SizedBox(height: 18),

                  _buildNotificationsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NAVIGATION ─────────────────────────────────────────────────────────────
  void _goToRegisterStation(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const RegisterStation(),
        transitionsBuilder: (_, animation, __, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          return SlideTransition(
            position: slideAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SO Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track your charging network',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── QUICK STATS ────────────────────────────────────────────────────────────
  Widget _buildQuickStats() {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "Today's Revenue",
            value: 'Rs. 8,420',
            icon: Icons.payments_rounded,
          ),
        ),

        SizedBox(width: 12),

        Expanded(
          child: _StatCard(
            label: 'Total Stations',
            value: '5',
            icon: Icons.ev_station_rounded,
          ),
        ),
      ],
    );
  }

  // ── MY STATIONS ────────────────────────────────────────────────────────────
  Widget _buildMyStationsSection(BuildContext context) {
    return Column(
      children: [
        _buildSectionHead(
          title: 'My Stations',
          actionText: 'Add station',
          onActionTap: () => _goToRegisterStation(context),
        ),

        Column(
          children: const [
            _StationCard(
              stationName: 'Panadura / Bandaragama Rd',
              stationMeta: 'Type 1 · 7 kW · Rs. 12.50/hr',
              badgeText: 'Online',
              badgeColor: _green,
              icon: Icons.power_rounded,
            ),

            SizedBox(height: 10),

            _StationCard(
              stationName: 'Udawalawe Area',
              stationMeta: 'Type 2 · 11 kW · Rs. 15.00/hr',
              badgeText: 'Online',
              badgeColor: _green,
              icon: Icons.power_rounded,
            ),

            SizedBox(height: 10),

            _StationCard(
              stationName: 'Colombo / Galle Road',
              stationMeta: 'CCS · 22 kW · Rs. 18.00/hr',
              badgeText: 'Maint.',
              badgeColor: _amber,
              icon: Icons.settings_rounded,
            ),

            SizedBox(height: 10),

            _StationCard(
              stationName: 'Kalutara Junction',
              stationMeta: 'Type 1 · 7 kW · Rs. 12.00/hr',
              badgeText: 'Offline',
              badgeColor: _red,
              icon: Icons.warning_rounded,
            ),
          ],
        ),
      ],
    );
  }

  // ── WEEKLY EARNINGS GRAPH ──────────────────────────────────────────────────
  Widget _buildWeeklyEarningsSection() {
    return Column(
      children: [
        _buildSectionHead(
          title: 'Weekly Earnings',
          actionText: 'Details',
        ),

        const _GraphCard(
          title: 'Rs. 47,860',
          subtitle: 'Last 7 days · 5 stations',
          values: [38, 55, 44, 70, 50, 82, 65],
          labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          footerLabel: 'Next payout · Jul 10',
          footerValue: 'Rs. 32,450',
          footerButtonText: 'Statement',
        ),
      ],
    );
  }

  // ── COMPACT WEEKLY VEHICLES GRAPH ──────────────────────────────────────────
  Widget _buildWeeklyVehiclesSection() {
    return Column(
      children: [
        _buildSectionHead(
          title: 'Weekly Vehicles',
          actionText: 'Details',
        ),

        const _MiniVehicleGraphCard(
          totalVehicles: '214',
          subtitle: 'Vehicles charged this week',
          values: [28, 36, 24, 42, 31, 53, 40],
          labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        ),
      ],
    );
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────────────────────
  Widget _buildNotificationsSection() {
    return Column(
      children: [
        _buildSectionHead(
          title: 'Notifications',
          actionText: 'Mark read',
        ),

        _buildPanel(
          child: const Column(
            children: [
              _NotificationTile(
                color: _red,
                message: 'Kalutara Junction went offline unexpectedly',
                time: '18 minutes ago',
              ),

              _DividerLine(),

              _NotificationTile(
                color: _green,
                message: 'New booking request at Panadura / Bandaragama Rd',
                time: '1 hour ago',
              ),

              _DividerLine(),

              _NotificationTile(
                color: _primary,
                message: 'Payout of Rs. 28,900 was deposited',
                time: 'Yesterday',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── REUSABLE SECTION HEADER ────────────────────────────────────────────────
  Widget _buildSectionHead({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),

          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── REUSABLE PANEL ─────────────────────────────────────────────────────────
  Widget _buildPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STAT CARD
// ══════════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 132,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SoDashboard._border),
        boxShadow: [
          BoxShadow(
            color: SoDashboard._primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SoDashboard._primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: SoDashboard._primary,
              size: 21,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SoDashboard._muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SoDashboard._textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATION CARD
// ══════════════════════════════════════════════════════════════════════════════

class _StationCard extends StatelessWidget {
  final String stationName;
  final String stationMeta;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;

  const _StationCard({
    required this.stationName,
    required this.stationMeta,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SoDashboard._border),
        boxShadow: [
          BoxShadow(
            color: SoDashboard._primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SoDashboard._primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: SoDashboard._primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SoDashboard._textDark,
                    fontSize: 13.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  stationMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SoDashboard._muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText.toUpperCase(),
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LARGE WEEKLY EARNINGS GRAPH CARD
// ══════════════════════════════════════════════════════════════════════════════

class _GraphCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<double> values;
  final List<String> labels;
  final String footerLabel;
  final String footerValue;
  final String footerButtonText;

  const _GraphCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labels,
    required this.footerLabel,
    required this.footerValue,
    required this.footerButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SoDashboard._primary, SoDashboard._primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: SoDashboard._primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -85,
            top: -75,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 92,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(values.length, (index) {
                    final bool isLastBar = index == values.length - 1;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == values.length - 1 ? 0 : 7,
                        ),
                        child: FractionallySizedBox(
                          heightFactor: values[index] / 100,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isLastBar
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.36),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                                bottomLeft: Radius.circular(3),
                                bottomRight: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 7),

              Row(
                children: List.generate(labels.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == labels.length - 1 ? 0 : 7,
                      ),
                      child: Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            footerLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.73),
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            footerValue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        footerButtonText,
                        style: const TextStyle(
                          color: SoDashboard._primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SMALL WEEKLY VEHICLES GRAPH CARD
// ══════════════════════════════════════════════════════════════════════════════

class _MiniVehicleGraphCard extends StatelessWidget {
  final String totalVehicles;
  final String subtitle;
  final List<double> values;
  final List<String> labels;

  const _MiniVehicleGraphCard({
    required this.totalVehicles,
    required this.subtitle,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final double maxValue = values.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SoDashboard._border),
        boxShadow: [
          BoxShadow(
            color: SoDashboard._primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  color: SoDashboard._primary,
                  size: 24,
                ),

                const SizedBox(height: 10),

                Text(
                  totalVehicles,
                  style: const TextStyle(
                    color: SoDashboard._textDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: SoDashboard._muted,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(values.length, (index) {
                      final double heightFactor = values[index] / maxValue;
                      final bool isHighest = values[index] == maxValue;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == values.length - 1 ? 0 : 6,
                          ),
                          child: FractionallySizedBox(
                            heightFactor: heightFactor,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isHighest
                                    ? SoDashboard._primary
                                    : SoDashboard._primary.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(7),
                                  topRight: Radius.circular(7),
                                  bottomLeft: Radius.circular(3),
                                  bottomRight: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: List.generate(labels.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == labels.length - 1 ? 0 : 6,
                        ),
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SoDashboard._muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION TILE
// ══════════════════════════════════════════════════════════════════════════════

class _NotificationTile extends StatelessWidget {
  final Color color;
  final String message;
  final String time;

  const _NotificationTile({
    required this.color,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(top: 5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: SoDashboard._textDark,
                  fontSize: 12.4,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                time,
                style: const TextStyle(
                  color: SoDashboard._muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIVIDER LINE
// ══════════════════════════════════════════════════════════════════════════════

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 11),
      color: SoDashboard._border,
    );
  }
}