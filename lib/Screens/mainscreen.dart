import 'package:flutter/material.dart';
import 'package:chargepathso/Screens/home.dart';
import 'registerstation.dart';
import 'package:chargepathso/Screens/profilepage.dart';
import 'package:chargepathso/Widgets/navigationbar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    RegisterStation(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── PAGE CONTENT ────────────────────────────────────────────────
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // ── BOTTOM NAV BAR ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            // CHANGED — removed the SafeArea wrapper; CustomNavBar now
            // absorbs MediaQuery's bottom inset internally via its own padding
            child: CustomNavBar(
              selectedIndex: _selectedIndex,
              onTabChange: (index) =>
                  setState(() => _selectedIndex = index),
            ),
          ),
        ],
      ),
    );
  }
}