import 'package:flutter/material.dart';
import 'screens/home_dashboard.dart';
import 'screens/explore_screen.dart';
import 'screens/track_screen.dart';
import 'screens/events_screen.dart';
import 'screens/profile_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(const AstroLogApp());
}

class AstroLogApp extends StatelessWidget {
  const AstroLogApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroLog',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
      routes: {
        '/home': (context) => const HomeDashboard(),
        '/explore': (context) => const ExploreScreen(),
        '/track': (context) => const TrackScreen(),
        '/events': (context) => const EventsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDashboard(),
    const ExploreScreen(),
    const TrackScreen(),
    const EventsScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.explore),
      label: 'Explore',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.track_changes),
      label: 'Track',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.event),
      label: 'Events',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: _navItems,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}
