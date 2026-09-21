import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'registerstation.dart';

class SoDashboard extends StatelessWidget {
  const SoDashboard({super.key});

  // ── THEME ──────────────────────────────────────────────────────────────────

  static const Color _primary = Color(0xFF0253A4);
  static const Color _primaryLight = Color(0xFF2979D4);
  static const Color _primarySurface = Color(0xFFE6EFF8);

  static const Color _bg = Color(0xFFF5F7FA);

  static const Color _textDark = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE4EAF2);

  static const Color _green = Color(0xFF16A34A);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFDC2626);

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double bottomInset =
        MediaQuery.of(context).padding.bottom;

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _buildHeader(context),

            const Expanded(
              child: Center(
                child: Text(
                  'You must be logged in to view your stations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('stations')
                  .where(
                'user_id',
                isEqualTo: currentUser.uid,
              )
                  .snapshots(),
              builder: (context, snapshot) {
                // ── ERROR ──────────────────────────────────────────────────

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: _red,
                            size: 42,
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Could not load your stations',
                            style: TextStyle(
                              color: _textDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ── LOADING ────────────────────────────────────────────────

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _primary,
                    ),
                  );
                }

                final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                stationDocuments =
                    snapshot.data?.docs ?? [];

                final int totalStations =
                    stationDocuments.length;

                // ── TOTAL REVENUE ─────────────────────────────────────────

                double totalRevenue = 0.0;

                for (final stationDocument
                in stationDocuments) {
                  final Map<String, dynamic> station =
                  stationDocument.data();

                  totalRevenue += _doubleValue(
                    station['total_income'],
                  );
                }

                // ── PENDING BOOKING REQUESTS ───────────────────────────────
                //
                // Driver app is frozen.
                //
                // Therefore we do NOT depend on:
                //
                // is_booking_requested == "1"
                //
                // A booking is considered pending when:
                //
                // booking_user_id is not empty
                // AND
                // is_booking_confirmed != "1"
                //
                // ----------------------------------------------------------------

                final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                pendingBookings =
                stationDocuments.where(
                      (
                      QueryDocumentSnapshot<
                          Map<String, dynamic>>
                      document,
                      ) {
                    final Map<String, dynamic> data =
                    document.data();

                    final String bookingUserId =
                    _stringValue(
                      data['booking_user_id'],
                      fallback: '',
                    );

                    final String bookingConfirmed =
                    _stringValue(
                      data['is_booking_confirmed'],
                      fallback: '0',
                    );

                    return bookingUserId.isNotEmpty &&
                        bookingConfirmed != '1';
                  },
                ).toList();

                return SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    14,
                    18,
                    14,
                    24 + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      // ── TOP STAT CARDS ───────────────────────────────────

                      _buildQuickStats(
                        totalStations: totalStations,
                        totalRevenue: totalRevenue,
                      ),

                      const SizedBox(height: 18),

                      // ── OWNER STATIONS ───────────────────────────────────

                      _buildMyStationsSection(
                        context,
                        stationDocuments,
                      ),

                      const SizedBox(height: 18),

                      // ── BOOKING REQUESTS ─────────────────────────────────
                      //
                      // Weekly Earnings and Weekly Vehicles are temporarily
                      // removed from the dashboard and replaced by this.
                      // ----------------------------------------------------------------

                      _buildBookingRequestsSection(
                        pendingBookings,
                      ),

                      const SizedBox(height: 18),

                      // ── NOTIFICATIONS ────────────────────────────────────

                      _buildNotificationsSection(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── NAVIGATION ─────────────────────────────────────────────────────────────

  void _goToRegisterStation(
      BuildContext context,
      ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) {
          return const RegisterStation();
        },
        transitionsBuilder: (
            _,
            animation,
            __,
            child,
            ) {
          final Animation<Offset> slideAnimation =
          Tween<Offset>(
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
        transitionDuration:
        const Duration(milliseconds: 380),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context,
      ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary,
            _primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            8,
            8,
            20,
            20,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                  color: Colors.white.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius:
                  BorderRadius.circular(14),
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

  Widget _buildQuickStats({
    required int totalStations,
    required double totalRevenue,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Revenue',
            value:
            'Rs. ${totalRevenue.toStringAsFixed(2)}',
            icon: Icons.payments_rounded,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _StatCard(
            label: 'Total Stations',
            value: totalStations.toString(),
            icon: Icons.ev_station_rounded,
          ),
        ),
      ],
    );
  }

  // ── MY STATIONS ────────────────────────────────────────────────────────────

  Widget _buildMyStationsSection(
      BuildContext context,
      List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>
      stationDocuments,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _buildSectionHead(
          title: 'My Stations',
          actionText: 'Add station',
          onActionTap: () {
            _goToRegisterStation(context);
          },
        ),

        if (stationDocuments.isEmpty)
          _buildNoStationsCard(context)
        else
          Column(
            children: List.generate(
              stationDocuments.length,
                  (int index) {
                final QueryDocumentSnapshot<
                    Map<String, dynamic>>
                stationDocument =
                stationDocuments[index];

                final Map<String, dynamic> station =
                stationDocument.data();

                final String stationName =
                _stringValue(
                  station['station_name'],
                  fallback: 'Unnamed Station',
                );

                final String connectorType =
                _stringValue(
                  station[
                  'supported_connector_types'],
                  fallback: 'Unknown connector',
                );

                final String chargingPower =
                _stringValue(
                  station['charging_power'],
                  fallback: '0',
                );

                final String costPerKw =
                _stringValue(
                  station['cost_per_kw'],
                  fallback: '0',
                );

                final String status =
                _stringValue(
                  station['status'],
                  fallback: 'Pending',
                );

                final String verificationStatus =
                _stringValue(
                  station['verification_status'],
                  fallback: 'Pending',
                );

                final double actualIncome =
                _doubleValue(
                  station['actual_income'],
                );

                final double totalIncome =
                _doubleValue(
                  station['total_income'],
                );

                final String stationMeta =
                    '$connectorType · '
                    '$chargingPower kW · '
                    'Rs. $costPerKw/kW';

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index ==
                        stationDocuments.length -
                            1
                        ? 0
                        : 10,
                  ),
                  child: _StationCard(
                    stationId:
                    stationDocument.id,
                    stationName:
                    stationName,
                    stationMeta:
                    stationMeta,
                    status:
                    status,
                    verificationStatus:
                    verificationStatus,
                    actualIncome:
                    actualIncome,
                    totalIncome:
                    totalIncome,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── BOOKING REQUESTS ───────────────────────────────────────────────────────

  Widget _buildBookingRequestsSection(
      List<
          QueryDocumentSnapshot<
              Map<String, dynamic>>>
      pendingBookings,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Booking Requests',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            if (pendingBookings.isNotEmpty)
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _amber.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(999),
                ),
                child: Text(
                  '${pendingBookings.length} pending',
                  style: const TextStyle(
                    color: _amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 11),

        if (pendingBookings.isEmpty)
          _buildNoBookingRequestsCard()
        else
          Column(
            children: List.generate(
              pendingBookings.length,
                  (int index) {
                final QueryDocumentSnapshot<
                    Map<String, dynamic>>
                document =
                pendingBookings[index];

                final Map<String, dynamic> data =
                document.data();

                final String stationName =
                _stringValue(
                  data['station_name'],
                  fallback: 'Unnamed Station',
                );

                final String bookingDate =
                _stringValue(
                  data['booking_date'],
                  fallback: 'Date unavailable',
                );

                final String bookingTime =
                _stringValue(
                  data['booking_time'],
                  fallback: 'Time unavailable',
                );

                final String bookingUserId =
                _stringValue(
                  data['booking_user_id'],
                  fallback: '',
                );

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index ==
                        pendingBookings.length - 1
                        ? 0
                        : 10,
                  ),
                  child: _BookingRequestCard(
                    stationId: document.id,
                    stationName: stationName,
                    bookingDate: bookingDate,
                    bookingTime: bookingTime,
                    bookingUserId:
                    bookingUserId,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── NO BOOKING REQUESTS ────────────────────────────────────────────────────

  Widget _buildNoBookingRequestsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(
              alpha: 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: _primary,
                size: 23,
              ),
            ),
          ),

          SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'No pending bookings',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'New driver booking requests will appear here.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NO STATIONS ────────────────────────────────────────────────────────────

  Widget _buildNoStationsCard(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(
              alpha: 0.08,
            ),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            const BoxDecoration(
              color: _primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ev_station_outlined,
              color: _primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'No stations yet',
            style: TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Register your first charging station to start managing it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              _goToRegisterStation(context);
            },
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text(
              'Register Station',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── VALUE HELPERS ──────────────────────────────────────────────────────────

  String _stringValue(
      dynamic value, {
        required String fallback,
      }) {
    if (value == null) {
      return fallback;
    }

    final String result =
    value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  double _doubleValue(
      dynamic value,
      ) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    ) ??
        0.0;
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────────────────────

  Widget _buildNotificationsSection() {
    return Column(
      children: [
        _buildSectionHead(
          title: 'Notifications',
        ),

        _buildPanel(
          child: const Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: _muted,
                size: 20,
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'No new notifications.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SECTION HEADER ─────────────────────────────────────────────────────────

  Widget _buildSectionHead({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2,
        0,
        2,
        11,
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
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

  // ── PANEL ──────────────────────────────────────────────────────────────────

  Widget _buildPanel({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: _border,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(
              alpha: 0.08,
            ),
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
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: SoDashboard._border,
        ),
        boxShadow: [
          BoxShadow(
            color:
            SoDashboard._primary.withValues(
              alpha: 0.08,
            ),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
              SoDashboard._primarySurface,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color:
              SoDashboard._primary,
              size: 21,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color:
              SoDashboard._muted,
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
              color:
              SoDashboard._textDark,
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

class _StationCard extends StatefulWidget {
  final String stationId;
  final String stationName;
  final String stationMeta;
  final String status;
  final String verificationStatus;

  final double actualIncome;
  final double totalIncome;

  const _StationCard({
    required this.stationId,
    required this.stationName,
    required this.stationMeta,
    required this.status,
    required this.verificationStatus,
    required this.actualIncome,
    required this.totalIncome,
  });

  @override
  State<_StationCard> createState() =>
      _StationCardState();
}

class _StationCardState
    extends State<_StationCard> {
  bool _isUpdating = false;

  // ── STATUS HELPERS ─────────────────────────────────────────────────────────

  String get _normalizedStatus {
    return widget.status
        .trim()
        .toLowerCase();
  }

  bool get _isActive {
    return _normalizedStatus == 'active';
  }

  bool get _isPending {
    return _normalizedStatus == 'pending' ||
        widget.verificationStatus
            .trim()
            .toLowerCase() ==
            'pending';
  }

  bool get _isRejected {
    return _normalizedStatus == 'rejected' ||
        widget.verificationStatus
            .trim()
            .toLowerCase() ==
            'rejected';
  }

  bool get _isApproved {
    return widget.verificationStatus
        .trim()
        .toLowerCase() ==
        'approved';
  }

  bool get _canChangeStatus {
    return _isApproved &&
        (_normalizedStatus == 'active' ||
            _normalizedStatus == 'inactive');
  }

  Color get _statusColor {
    if (_isPending) {
      return SoDashboard._amber;
    }

    if (_isRejected) {
      return SoDashboard._red;
    }

    if (_isActive) {
      return SoDashboard._green;
    }

    return SoDashboard._muted;
  }

  IconData get _statusIcon {
    if (_isPending) {
      return Icons.pending_actions_rounded;
    }

    if (_isRejected) {
      return Icons.cancel_outlined;
    }

    if (_isActive) {
      return Icons.power_rounded;
    }

    return Icons.power_settings_new_rounded;
  }

  String get _statusLabel {
    if (_isPending) {
      return 'PENDING';
    }

    if (_isRejected) {
      return 'REJECTED';
    }

    if (_isActive) {
      return 'ACTIVE';
    }

    return 'INACTIVE';
  }

  // ── CHANGE STATION STATUS ──────────────────────────────────────────────────

  Future<void> _changeStationStatus(
      bool makeActive,
      ) async {
    if (!_canChangeStatus ||
        _isUpdating) {
      return;
    }

    final String newStatus =
    makeActive
        ? 'Active'
        : 'Inactive';

    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('stations')
          .doc(widget.stationId)
          .update({
        'status': newStatus,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior.floating,
            duration:
            const Duration(seconds: 2),
            margin:
            const EdgeInsets.all(14),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(14),
            ),
            content: Row(
              children: [
                Icon(
                  makeActive
                      ? Icons.check_circle_rounded
                      : Icons
                      .power_settings_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    makeActive
                        ? '${widget.stationName} is now active'
                        : '${widget.stationName} is now inactive',
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior.floating,
            backgroundColor:
            SoDashboard._red,
            duration:
            const Duration(seconds: 3),
            margin:
            const EdgeInsets.all(14),
            content: Text(
              'Could not change station status: '
                  '${e.message ?? e.code}',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(17),
        border: Border.all(
          color: SoDashboard._border,
        ),
        boxShadow: [
          BoxShadow(
            color:
            SoDashboard._primary.withValues(
              alpha: 0.08,
            ),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
              _statusColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              _statusIcon,
              color: _statusColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stationName,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    SoDashboard._textDark,
                    fontSize: 13.3,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  widget.stationMeta,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color:
                    SoDashboard._muted,
                    fontSize: 11.5,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildRevenueBadge(
                      label: 'Latest',
                      value:
                      widget.actualIncome,
                      icon:
                      Icons.payments_outlined,
                    ),

                    _buildRevenueBadge(
                      label: 'Total',
                      value:
                      widget.totalIncome,
                      icon: Icons
                          .account_balance_wallet_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                        _statusColor
                            .withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          999,
                        ),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color:
                          _statusColor,
                          fontSize: 9,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing:
                          0.25,
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        widget.stationId,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          color:
                          SoDashboard._muted,
                          fontSize: 9.5,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              if (_isUpdating)
                const SizedBox(
                  width: 38,
                  height: 38,
                  child: Padding(
                    padding:
                    EdgeInsets.all(9),
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      SoDashboard._primary,
                    ),
                  ),
                )
              else
                Transform.scale(
                  scale: 0.82,
                  child:
                  Switch.adaptive(
                    value: _isActive,
                    onChanged:
                    _canChangeStatus
                        ? (bool value) {
                      _changeStationStatus(
                        value,
                      );
                    }
                        : null,
                    activeThumbColor:
                    Colors.white,
                    activeTrackColor:
                    SoDashboard._green,
                    inactiveThumbColor:
                    Colors.white,
                    inactiveTrackColor:
                    SoDashboard._muted
                        .withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),

              Transform.translate(
                offset:
                const Offset(0, -4),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 8.5,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing:
                    0.25,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBadge({
    required String label,
    required double value,
    required IconData icon,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
        SoDashboard._green.withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(8),
        border: Border.all(
          color:
          SoDashboard._green.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
            SoDashboard._green,
            size: 12,
          ),

          const SizedBox(width: 4),

          Text(
            '$label: '
                'Rs. ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              color:
              SoDashboard._green,
              fontSize: 9.5,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BOOKING REQUEST CARD
// ══════════════════════════════════════════════════════════════════════════════

class _BookingRequestCard
    extends StatefulWidget {
  final String stationId;
  final String stationName;

  final String bookingDate;
  final String bookingTime;
  final String bookingUserId;

  const _BookingRequestCard({
    required this.stationId,
    required this.stationName,
    required this.bookingDate,
    required this.bookingTime,
    required this.bookingUserId,
  });

  @override
  State<_BookingRequestCard> createState() =>
      _BookingRequestCardState();
}

class _BookingRequestCardState
    extends State<_BookingRequestCard> {
  bool _isUpdating = false;

  // ── SHORT DRIVER ID ────────────────────────────────────────────────────────

  String get _shortDriverId {
    final String id =
    widget.bookingUserId.trim();

    if (id.length <= 12) {
      return id;
    }

    return '${id.substring(0, 6)}...'
        '${id.substring(id.length - 4)}';
  }

  // ── ACCEPT BOOKING ─────────────────────────────────────────────────────────

  Future<void> _acceptBooking() async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception(
          'You must be logged in.',
        );
      }

      final DocumentReference<
          Map<String, dynamic>>
      stationReference =
      FirebaseFirestore.instance
          .collection('stations')
          .doc(widget.stationId);

      // Transaction verifies that:
      //
      // 1. station still belongs to this owner
      // 2. same driver's booking is still present
      //
      // before accepting it.
      await FirebaseFirestore.instance
          .runTransaction(
            (
            Transaction transaction,
            ) async {
          final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await transaction.get(
            stationReference,
          );

          if (!snapshot.exists) {
            throw Exception(
              'Station no longer exists.',
            );
          }

          final Map<String, dynamic> data =
          snapshot.data()!;

          final String ownerId =
              data['user_id']
                  ?.toString()
                  .trim() ??
                  '';

          if (ownerId !=
              currentUser.uid) {
            throw Exception(
              'You do not own this station.',
            );
          }

          final String bookingUserId =
              data['booking_user_id']
                  ?.toString()
                  .trim() ??
                  '';

          if (bookingUserId !=
              widget.bookingUserId) {
            throw Exception(
              'This booking request has changed.',
            );
          }

          if (bookingUserId.isEmpty) {
            throw Exception(
              'This booking request no longer exists.',
            );
          }

          transaction.update(
            stationReference,
            {
              'is_booking_requested':
              '0',

              'is_booking_confirmed':
              '1',
            },
          );
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior.floating,
            backgroundColor:
            SoDashboard._green,
            duration:
            const Duration(
              seconds: 2,
            ),
            margin:
            const EdgeInsets.all(
              14,
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Booking accepted for '
                        '${widget.stationName}.',
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message =
      e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior.floating,
            backgroundColor:
            SoDashboard._red,
            content: Text(
              'Could not accept booking: '
                  '$message',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ── REJECT BOOKING ─────────────────────────────────────────────────────────

  Future<void> _rejectBooking() async {
    if (_isUpdating) {
      return;
    }

    final bool? shouldReject =
    await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
          title: const Text(
            'Reject booking?',
          ),
          content: Text(
            'Reject the booking request for '
                '${widget.stationName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
              const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                SoDashboard._red,
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text(
                'Reject',
              ),
            ),
          ],
        );
      },
    );

    if (shouldReject != true) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception(
          'You must be logged in.',
        );
      }

      final DocumentReference<
          Map<String, dynamic>>
      stationReference =
      FirebaseFirestore.instance
          .collection('stations')
          .doc(widget.stationId);

      await FirebaseFirestore.instance
          .runTransaction(
            (
            Transaction transaction,
            ) async {
          final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await transaction.get(
            stationReference,
          );

          if (!snapshot.exists) {
            throw Exception(
              'Station no longer exists.',
            );
          }

          final Map<String, dynamic> data =
          snapshot.data()!;

          final String ownerId =
              data['user_id']
                  ?.toString()
                  .trim() ??
                  '';

          if (ownerId !=
              currentUser.uid) {
            throw Exception(
              'You do not own this station.',
            );
          }

          final String bookingUserId =
              data['booking_user_id']
                  ?.toString()
                  .trim() ??
                  '';

          if (bookingUserId !=
              widget.bookingUserId) {
            throw Exception(
              'This booking request has changed.',
            );
          }

          transaction.update(
            stationReference,
            {
              'booking_date': '',
              'booking_time': '',
              'booking_user_id': '',

              'is_booking_requested':
              '0',

              'is_booking_confirmed':
              '0',
            },
          );
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior.floating,
            backgroundColor:
            SoDashboard._red,
            duration:
            const Duration(
              seconds: 2,
            ),
            margin:
            const EdgeInsets.all(
              14,
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  color: Colors.white,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Booking rejected for '
                        '${widget.stationName}.',
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message =
      e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior.floating,
            backgroundColor:
            SoDashboard._red,
            content: Text(
              'Could not reject booking: '
                  '$message',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          SoDashboard._border,
        ),
        boxShadow: [
          BoxShadow(
            color:
            SoDashboard._primary
                .withValues(
              alpha: 0.07,
            ),
            blurRadius: 20,
            offset:
            const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ── TOP ──────────────────────────────────────────────────────────

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color:
                  SoDashboard._amber
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .event_note_rounded,
                  color:
                  SoDashboard._amber,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      widget.stationName,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        color:
                        SoDashboard
                            ._textDark,
                        fontSize: 14,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        SoDashboard
                            ._amber
                            .withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          999,
                        ),
                      ),
                      child:
                      const Text(
                        'PENDING APPROVAL',
                        style:
                        TextStyle(
                          color:
                          SoDashboard
                              ._amber,
                          fontSize: 9,
                          fontWeight:
                          FontWeight
                              .w900,
                          letterSpacing:
                          0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 15,
          ),

          // ── BOOKING DETAILS ──────────────────────────────────────────────

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(
              12,
            ),
            decoration:
            BoxDecoration(
              color:
              SoDashboard._bg,
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Column(
              children: [
                _BookingDetailRow(
                  icon:
                  Icons.calendar_today_rounded,
                  label:
                  'Date',
                  value:
                  widget.bookingDate,
                ),

                const SizedBox(
                  height: 9,
                ),

                _BookingDetailRow(
                  icon:
                  Icons.access_time_rounded,
                  label:
                  'Time',
                  value:
                  widget.bookingTime,
                ),

                const SizedBox(
                  height: 9,
                ),

                _BookingDetailRow(
                  icon:
                  Icons.person_outline_rounded,
                  label:
                  'Driver',
                  value:
                  _shortDriverId,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ── ACTION BUTTONS ───────────────────────────────────────────────

          if (_isUpdating)
            const SizedBox(
              height: 46,
              child:
              Center(
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  SoDashboard._primary,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child:
                  OutlinedButton.icon(
                    onPressed:
                    _rejectBooking,
                    icon:
                    const Icon(
                      Icons.close_rounded,
                      size: 18,
                    ),
                    label:
                    const Text(
                      'Reject',
                    ),
                    style:
                    OutlinedButton
                        .styleFrom(
                      foregroundColor:
                      SoDashboard._red,
                      side:
                      const BorderSide(
                        color:
                        SoDashboard._red,
                      ),
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical:
                        12,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                  ElevatedButton.icon(
                    onPressed:
                    _acceptBooking,
                    icon:
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                    ),
                    label:
                    const Text(
                      'Accept',
                    ),
                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      SoDashboard._green,
                      foregroundColor:
                      Colors.white,
                      elevation: 0,
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical:
                        12,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),
                    ),
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
// BOOKING DETAIL ROW
// ══════════════════════════════════════════════════════════════════════════════

class _BookingDetailRow
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BookingDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color:
          SoDashboard._primary,
          size: 17,
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 48,
          child: Text(
            label,
            style:
            const TextStyle(
              color:
              SoDashboard._muted,
              fontSize: 11.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style:
            const TextStyle(
              color:
              SoDashboard._textDark,
              fontSize: 12,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}