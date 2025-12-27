import 'package:flutter/material.dart';
import 'themes/app_theme.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/books_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/research_papers_screen.dart';
import 'screens/space_screen.dart';

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
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    ProjectsScreen(),
    BooksScreen(),
    ResearchPapersScreen(),
    SpaceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Research',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rocket_launch),
            label: 'Space',
          ),
        ],
      ),
    );
  }
}
