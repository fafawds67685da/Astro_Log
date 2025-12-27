import 'package:flutter/material.dart';
import 'books_screen.dart';
import 'research_papers_screen.dart';
import 'projects_screen.dart';

class AcademicsScreen extends StatelessWidget {
  const AcademicsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0E17),
        appBar: AppBar(
          title: const Text('Academics'),
          backgroundColor: const Color(0xFF1A1A2E),
          bottom: const TabBar(
            indicatorColor: Colors.purpleAccent,
            tabs: [
              Tab(text: 'Books', icon: Icon(Icons.menu_book)),
              Tab(text: 'Papers', icon: Icon(Icons.article)),
              Tab(text: 'Projects', icon: Icon(Icons.assignment)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BooksScreen(),
            ResearchPapersScreen(),
            ProjectsScreen(),
          ],
        ),
      ),
    );
  }
}
