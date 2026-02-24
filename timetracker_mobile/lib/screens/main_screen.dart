import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const AnalyticsScreen(),
    const CalendarScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0e27),
              Color(0xFF161b31),
            ],
          ),
        ),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1e223e),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: NavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          indicatorColor: const Color(0xFF667eea).withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF667eea)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF667eea)),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined, color: Colors.white70),
              selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF667eea)),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.white70),
              selectedIcon: Icon(Icons.person, color: Color(0xFF667eea)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
