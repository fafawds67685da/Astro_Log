import 'package:flutter/material.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AstroLog Dashboard'),
      ),
      body: SingleChildScrollView(
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
              read: 12,
              total: 25,
              readLabel: 'Read',
              unreadLabel: 'Unread',
            ),
            const SizedBox(height: 16),
            
            // Observatories Stats
            _StatCard(
              title: 'Observatories',
              icon: Icons.location_city,
              read: 5,
              total: 15,
              readLabel: 'Visited',
              unreadLabel: 'To Visit',
            ),
            const SizedBox(height: 16),
            
            // Constellations Stats
            _StatCard(
              title: 'Constellations',
              icon: Icons.stars,
              read: 35,
              total: 88,
              readLabel: 'Identified',
              unreadLabel: 'Not Yet',
            ),
            const SizedBox(height: 16),
            
            // Celestial Objects Stats
            _StatCard(
              title: 'Celestial Objects',
              icon: Icons.public,
              read: 48,
              total: 120,
              readLabel: 'Observed',
              unreadLabel: 'Not Yet',
            ),
            const SizedBox(height: 16),
            
            // Gallery Stats
            _StatCard(
              title: 'Gallery Images',
              icon: Icons.photo_library,
              read: 156,
              total: 156,
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
