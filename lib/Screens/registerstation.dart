import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class RegisterStation extends StatefulWidget {
  const RegisterStation({super.key});

  @override
  State<RegisterStation> createState() => _RegisterStationState();
}

class _RegisterStationState extends State<RegisterStation>
    with SingleTickerProviderStateMixin {
  // ── THEME ──────────────────────────────────────────────────────────────────
  static const Color _primary        = Color(0xFF0253A4);
  static const Color _primaryLight   = Color(0xFF2979D4);
  static const Color _primarySurface = Color(0xFFE6EFF8);
  static const Color _bg             = Color(0xFFF5F7FA);

  // ── CONTROLLERS ────────────────────────────────────────────────────────────
  final _formKey              = GlobalKey<FormState>();
  final _stationNameCtrl      = TextEditingController();
  final _chargingPowerCtrl    = TextEditingController();
  final _connectorSlotsCtrl   = TextEditingController();
  final _costPerKwCtrl        = TextEditingController();
  final _avgWaitingTimeCtrl   = TextEditingController();
  final _chargingDurationCtrl = TextEditingController();

  // ── PAGE CONTROLLER  (must be a field, NOT created inside build) ───────────
  late PageController _pageController;

  // ── ANIMATION ──────────────────────────────────────────────────────────────
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  // ── STATE ──────────────────────────────────────────────────────────────────
  LatLng? _selectedLocation;
  String  _selectedConnectorType = 'Type 1';
  String  _fastCharging          = 'No';
  bool    _isSubmitting          = false;
  int     _currentStep           = 0;

  // ── OPTIONS ────────────────────────────────────────────────────────────────
  static const List<String> _connectorTypes = [
    'Type 1', 'Type 2', 'Type 3', 'CCS2', 'CHAdeMO', 'GBT',
  ];

  // ── LIFECYCLE ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // PageController initialised ONCE here
    _pageController = PageController(initialPage: 0);

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose(); // dispose here too
    _animCtrl.dispose();
    _stationNameCtrl.dispose();
    _chargingPowerCtrl.dispose();
    _connectorSlotsCtrl.dispose();
    _costPerKwCtrl.dispose();
    _avgWaitingTimeCtrl.dispose();
    _chargingDurationCtrl.dispose();
    super.dispose();
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  String _generateStationId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'CS${ts.toString().substring(ts.toString().length - 6)}';
  }

  /// Move forward one step, animating the PageView
  void _nextStep() {
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Move back one step, animating the PageView
  void _prevStep() {
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── LOCATION ───────────────────────────────────────────────────────────────
  Future<void> _pickCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.', isError: true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied.', isError: true);
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _selectedLocation = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      _showSnack('Could not get location: $e', isError: true);
    }
  }

  // ── FIRESTORE SUBMIT ───────────────────────────────────────────────────────
  Future<void> _submitStation() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill all required fields.', isError: true);
      return;
    }
    if (_selectedLocation == null) {
      _showSnack('Please select a station location.', isError: true);
      setState(() => _currentStep = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final int    slots     = int.tryParse(_connectorSlotsCtrl.text.trim()) ?? 1;
      final String stationId = _generateStationId();

      // ── All fields match the Firestore schema exactly ────────────────────
      await FirebaseFirestore.instance.collection('users').add({
        'station_id'              : stationId,
        'station_name'            : _stationNameCtrl.text.trim(),
        'latitude'                : _selectedLocation!.latitude.toString(),
        'longitude'               : _selectedLocation!.longitude.toString(),
        'supported_connector_types': _selectedConnectorType,
        'charging_power'          : _chargingPowerCtrl.text.trim(),
        'connector_slots'         : slots.toString(),
        'available_plugs'         : slots.toString(), // equals total slots at registration
        'cost_per_kw'             : _costPerKwCtrl.text.trim(),
        'fast_charging'           : _fastCharging,
        'average_waiting_time'    : _avgWaitingTimeCtrl.text.trim(),
        'charging_duration'       : _chargingDurationCtrl.text.trim(),
        'status'                  : 'Active',
        'registered_at'           : FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog(stationId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack('Registration failed: $e', isError: true);
      }
    }
  }

  // ── SNACKBAR ───────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? Colors.red.shade600 : _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ── SUCCESS DIALOG ─────────────────────────────────────────────────────────
  void _showSuccessDialog(String stationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.ev_station_rounded,
                  color: _primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Station Registered!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your station has been successfully added to ChargePath.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag, color: _primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Station ID: $stationId',
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // go back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController, // ← use the field
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
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
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Register Your Station',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Join the ChargePath network',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.ev_station_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP INDICATOR ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    const labels = ['Station Info', 'Location', 'Charger Setup'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (i) {
          final isDone   = i < _currentStep;
          final isActive = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green
                            : isActive
                                ? _primary
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: _primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? _primary
                            : isDone
                                ? Colors.green
                                : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: isDone ? Colors.green : Colors.grey.shade200,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── STEP 1 : STATION INFO ──────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Station Details', Icons.store_outlined),
          const SizedBox(height: 16),
          _buildField(
            controller: _stationNameCtrl,
            label: 'Station Name',
            hint: 'e.g. Colombo / Galle Road',
            icon: Icons.ev_station_outlined,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Station name is required'
                : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _avgWaitingTimeCtrl,
            label: 'Average Waiting Time (minutes)',
            hint: 'e.g. 10',
            icon: Icons.timer_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _chargingDurationCtrl,
            label: 'Charging Duration (minutes)',
            hint: 'e.g. 120',
            icon: Icons.hourglass_bottom_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _costPerKwCtrl,
            label: 'Cost per kW (LKR)',
            hint: 'e.g. 90',
            icon: Icons.attach_money_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          _sectionTitle('Status', Icons.info_outline),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Status: Active',
            subtitle: 'Your station will be visible to users immediately.',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── STEP 2 : LOCATION ──────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Station Location', Icons.location_on_outlined),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to use your current location, or tap on the map to pin your station.',
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Map preview
          Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selectedLocation != null
                    ? _primary.withOpacity(0.4)
                    : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: _selectedLocation == null
                ? _buildMapPlaceholder()
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('station'),
                        position: _selectedLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueAzure,
                        ),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    liteModeEnabled: true,
                    onTap: (latlng) =>
                        setState(() => _selectedLocation = latlng),
                  ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _pickCurrentLocation,
              icon: const Icon(Icons.my_location_rounded, size: 20),
              label: const Text(
                'Use My Current Location',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: null,
            icon: Icon(Icons.touch_app_outlined,
                size: 18, color: Colors.grey.shade500),
            label: Text(
              'Or tap on the map to set location',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_selectedLocation != null) ...[
            const SizedBox(height: 20),
            _buildInfoCard(
              icon: Icons.location_on,
              iconColor: _primary,
              title: 'Location Selected',
              subtitle:
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)},  '
                  'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: const Color(0xFFF0F4FA),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No location selected',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "Use My Current Location" below',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── STEP 3 : CHARGER SETUP ─────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Charger Configuration', Icons.settings_outlined),
          const SizedBox(height: 16),
          _buildField(
            controller: _chargingPowerCtrl,
            label: 'Charging Power (kW)',
            hint: 'e.g. 7',
            icon: Icons.flash_on_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
            ],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _connectorSlotsCtrl,
            label: 'Connector Slots (Total)',
            hint: 'e.g. 2',
            icon: Icons.cable_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if ((int.tryParse(v) ?? 0) < 1) return 'Must be at least 1';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _sectionTitle('Connector Type', Icons.power_outlined),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _connectorTypes.map((type) {
              final bool isSelected = _selectedConnectorType == type;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedConnectorType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _primary : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _primary.withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Fast Charging', Icons.bolt_outlined),
          const SizedBox(height: 12),
          Row(
            children: ['Yes', 'No'].map((val) {
              final bool isSelected = _fastCharging == val;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _fastCharging = val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: val == 'Yes' ? 8 : 0,
                      left: val == 'No' ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? _primary : Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _primary.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          val == 'Yes'
                              ? Icons.bolt_rounded
                              : Icons.bolt_outlined,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          val == 'Yes' ? 'Fast Charge' : 'Standard',
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            icon: Icons.info_outline,
            iconColor: _primary,
            title: 'About Available Plugs',
            subtitle:
                'available_plugs is automatically set equal to connector_slots '
                'on registration and updates as bookings are made.',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── BOTTOM ACTIONS ─────────────────────────────────────────────────────────
  Widget _buildBottomActions() {
    final bool isLast = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _prevStep, // ← uses _prevStep
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: _primary),
                  label: const Text(
                    'Back',
                    style: TextStyle(
                        color: _primary, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (isLast) {
                            _submitStation();
                          } else {
                            _nextStep(); // ← uses _nextStep
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Register Station' : 'Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward_ios_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── REUSABLE WIDGETS ───────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primarySurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: _primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.red.shade400, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}