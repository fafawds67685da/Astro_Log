import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = DatabaseHelper.instance;
      
      // Get all data counts
      final books = await db.getBooksByGenre(null);
      final readBooks = books.where((b) => b['isRead'] == 1).length;
      
      final objects = await db.getCelestialObjectsByClassification(null);
      final observedObjects = objects.where((o) => o['isObserved'] == 1).length;
      
      final projects = await db.getProjects();
      final doneProjects = projects.where((p) => p['status'] == 'Done').length;
      
      final papers = await db.getResearchPapers();
      final readPapers = papers.where((p) => p['status'] == 'Read').length;
      
      final gallery = await db.getGalleryImages();

      if (mounted) {
        setState(() {
          _stats = {
            'booksRead': readBooks,
            'booksTotal': books.length,
            'objectsObserved': observedObjects,
            'objectsTotal': objects.length,
            'projectsDone': doneProjects,
            'projectsTotal': projects.length,
            'papersRead': readPapers,
            'papersTotal': papers.length,
            'galleryTotal': gallery.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = {
            'booksRead': 0,
            'booksTotal': 0,
            'objectsObserved': 0,
            'objectsTotal': 0,
            'projectsDone': 0,
            'projectsTotal': 0,
            'papersRead': 0,
            'papersTotal': 0,
            'galleryTotal': 0,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AstroLog Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadStats();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Astronomy Journey',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Books Stats
                  _StatCard(
                    title: 'Books',
                    icon: Icons.menu_book,
                    read: _stats['booksRead'] ?? 0,
                    total: _stats['booksTotal'] ?? 0,
                    readLabel: 'Read',
                    unreadLabel: 'To Read',
                  ),
                  const SizedBox(height: 16),
                  
                  // Celestial Objects Stats
                  _StatCard(
                    title: 'Celestial Objects',
                    icon: Icons.public,
                    read: _stats['objectsObserved'] ?? 0,
                    total: _stats['objectsTotal'] ?? 0,
                    readLabel: 'Observed',
                    unreadLabel: 'Not Yet',
                  ),
                  const SizedBox(height: 16),
                  
                  // Projects Stats
                  _StatCard(
                    title: 'Projects',
                    icon: Icons.rocket_launch,
                    read: _stats['projectsDone'] ?? 0,
                    total: _stats['projectsTotal'] ?? 0,
                    readLabel: 'Done',
                    unreadLabel: 'Pending',
                  ),
                  const SizedBox(height: 16),
                  
                  // Research Papers Stats
                  _StatCard(
                    title: 'Research Papers',
                    icon: Icons.article,
                    read: _stats['papersRead'] ?? 0,
                    total: _stats['papersTotal'] ?? 0,
                    readLabel: 'Read',
                    unreadLabel: 'To Read',
                  ),
                  const SizedBox(height: 16),
                  
                  // Gallery Stats
                  _StatCard(
                    title: 'Gallery Images',
                    icon: Icons.photo_library,
                    read: _stats['galleryTotal'] ?? 0,
                    total: _stats['galleryTotal'] ?? 0,
                    readLabel: 'Images',
                    unreadLabel: '',
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int read;
  final int total;
  final String readLabel;
  final String unreadLabel;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.read,
    required this.total,
    required this.readLabel,
    required this.unreadLabel,
  });

  @override
  Widget build(BuildContext context) {
    final unread = total - read;
    final percentage = total > 0 ? (read / total * 100).toStringAsFixed(1) : '0';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            LinearProgressIndicator(
              value: total > 0 ? read / total : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$read $readLabel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                    if (unreadLabel.isNotEmpty)
                      Text(
                        '$unread $unreadLabel',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
