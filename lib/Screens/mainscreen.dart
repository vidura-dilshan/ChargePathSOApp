import 'package:flutter/material.dart';
import 'package:chargepathso/Screens/home.dart';
import 'package:chargepathso/Screens/chargingstations.dart';
import 'package:chargepathso/Screens/routeplanning.dart';
import 'package:chargepathso/Screens/bookstation.dart';
import 'package:chargepathso/Widgets/navigationbar.dart';
import 'package:chargepathso/Screens/profilepage.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(
      ),
      const FindStations(),
      const RoutePlanningPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomNavBar(
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() => _selectedIndex = index);
              },
              onCenterTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookStation()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}