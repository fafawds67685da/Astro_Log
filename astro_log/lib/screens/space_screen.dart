import 'package:flutter/material.dart';
import 'observatories_screen.dart';
import 'constellations_screen.dart';
import 'celestial_objects_screen.dart';
import 'gallery_screen.dart';

class SpaceScreen extends StatelessWidget {
  const SpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Space'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SpaceMenuButton(
              icon: Icons.location_on,
              title: 'Observatories',
              subtitle: 'Track visited locations',
              color: Colors.blueAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ObservatoriesScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _SpaceMenuButton(
              icon: Icons.stars,
              title: 'Constellations',
              subtitle: 'Identify star patterns',
              color: Colors.purpleAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConstellationsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _SpaceMenuButton(
              icon: Icons.public,
              title: 'Celestial Objects',
              subtitle: 'Catalog observed objects',
              color: Colors.cyanAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CelestialObjectsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _SpaceMenuButton(
              icon: Icons.photo_library,
              title: 'Gallery',
              subtitle: 'Telescope images collection',
              color: Colors.pinkAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GalleryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceMenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SpaceMenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A2E),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
