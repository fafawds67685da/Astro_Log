import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'observatories_screen.dart';
import 'constellations_screen.dart';
import 'celestial_objects_screen.dart';
import 'gallery_screen.dart';
import '../services/database_helper.dart';

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadStats();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final db = DatabaseHelper.instance;
      final objects = await db.getCelestialObjectsByClassification(null);
      final constellations = await db.getConstellations();
      final observatories = await db.getObservatories();
      final albums = await db.getGalleryAlbums();

      if (mounted) {
        setState(() {
          _stats = {
            'objects': objects.length,
            'constellations': constellations.length,
            'observatories': observatories.length,
            'albums': albums.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = {'objects': 0, 'constellations': 0, 'observatories': 0, 'albums': 0};
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cosmic gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0E17),
                  Color(0xFF1a0b2e),
                  Color(0xFF16213E),
                  Color(0xFF0F0E17),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Animated stars
          AnimatedBuilder(
            animation: _rotateController,
            builder: (context, child) {
              return CustomPaint(
                painter: _StarfieldPainter(_rotateController.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.cyanAccent, Colors.purpleAccent, Colors.pinkAccent],
                          ).createShader(bounds),
                          child: const Text(
                            'Astronomy',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explore the Cosmos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Quick Stats
                if (!_isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: _GlassContainer(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MiniStat(
                                value: '${_stats['objects'] ?? 0}',
                                label: 'Objects',
                                icon: Icons.public,
                                color: Colors.cyanAccent,
                              ),
                              _MiniStat(
                                value: '${_stats['constellations'] ?? 0}',
                                label: 'Patterns',
                                icon: Icons.stars,
                                color: Colors.purpleAccent,
                              ),
                              _MiniStat(
                                value: '${_stats['observatories'] ?? 0}',
                                label: 'Sites',
                                icon: Icons.location_on,
                                color: Colors.orangeAccent,
                              ),
                              _MiniStat(
                                value: '${_stats['albums'] ?? 0}',
                                label: 'Albums',
                                icon: Icons.photo_library,
                                color: Colors.pinkAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Menu Cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _CosmicMenuCard(
                        icon: Icons.public,
                        title: 'Celestial Objects',
                        subtitle: 'Planets, stars, galaxies & more',
                        count: _stats['objects'] ?? 0,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF0091AD)],
                        ),
                        pulseAnimation: _pulseController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CelestialObjectsScreen()),
                          ).then((_) => _loadStats());
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _CosmicMenuCard(
                        icon: Icons.stars,
                        title: 'Constellations',
                        subtitle: 'Star patterns & sky navigation',
                        count: _stats['constellations'] ?? 0,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                        ),
                        pulseAnimation: _pulseController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ConstellationsScreen()),
                          ).then((_) => _loadStats());
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _CosmicMenuCard(
                        icon: Icons.location_on,
                        title: 'Observatories',
                        subtitle: 'Observation sites & locations',
                        count: _stats['observatories'] ?? 0,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                        ),
                        pulseAnimation: _pulseController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ObservatoriesScreen()),
                          ).then((_) => _loadStats());
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _CosmicMenuCard(
                        icon: Icons.photo_library,
                        title: 'Photo Gallery',
                        subtitle: 'Astrophotography collection',
                        count: _stats['albums'] ?? 0,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                        ),
                        pulseAnimation: _pulseController,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GalleryScreen()),
                          ).then((_) => _loadStats());
                        },
                      ),
                      const SizedBox(height: 40),
                    ]),
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

class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _CosmicMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Gradient gradient;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _CosmicMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.gradient,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.colors.first.withOpacity(
                              0.3 + (pulseAnimation.value * 0.2),
                            ),
                            blurRadius: 12 + (pulseAnimation.value * 4),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.4),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double animationValue;
  
  _StarfieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);
    
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = random.nextDouble() * 2 + 0.5;
      final opacity = (math.sin(animationValue * math.pi * 2 + i) + 1) / 2;
      
      paint.color = Colors.white.withOpacity(opacity * 0.5);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
