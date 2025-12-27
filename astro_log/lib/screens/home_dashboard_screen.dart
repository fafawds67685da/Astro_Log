import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../services/database_helper.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> with TickerProviderStateMixin {
  Map<String, int> _stats = {};
  bool _isLoading = true;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _loadStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final db = DatabaseHelper.instance;
      
      final books = await db.getBooksByGenre(null);
      final readBooks = books.where((b) => b['isRead'] == 1).length;
      
      final objects = await db.getCelestialObjectsByClassification(null);
      final observedObjects = objects.where((o) => o['isObserved'] == 1).length;
      
      final projects = await db.getProjects();
      final doneProjects = projects.where((p) => p['status'] == 'Done').length;
      
      final papers = await db.getResearchPapers();
      final readPapers = papers.where((p) => p['status'] == 'Read').length;
      
      final albums = await db.getGalleryAlbums();
      final images = await db.getGalleryImages();

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
            'albumsTotal': albums.length,
            'imagesTotal': images.length,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = {
            'booksRead': 0, 'booksTotal': 0,
            'objectsObserved': 0, 'objectsTotal': 0,
            'projectsDone': 0, 'projectsTotal': 0,
            'papersRead': 0, 'papersTotal': 0,
            'albumsTotal': 0, 'imagesTotal': 0,
          };
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
                painter: StarfieldPainter(_rotateController.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.cyanAccent.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading cosmic data...',
                          style: TextStyle(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Custom App Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Colors.cyanAccent, Colors.purpleAccent],
                                    ).createShader(bounds),
                                    child: const Text(
                                      'AstroLog',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your Cosmic Journey',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.5),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              GlassButton(
                                icon: Icons.refresh,
                                onPressed: _loadStats,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Quick Stats Summary
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: GlassContainer(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _QuickStat(
                                    label: 'Books',
                                    value: '${_stats['booksTotal'] ?? 0}',
                                    icon: Icons.menu_book,
                                    color: Colors.purpleAccent,
                                  ),
                                  _QuickStat(
                                    label: 'Objects',
                                    value: '${_stats['objectsTotal'] ?? 0}',
                                    icon: Icons.public,
                                    color: Colors.cyanAccent,
                                  ),
                                  _QuickStat(
                                    label: 'Projects',
                                    value: '${_stats['projectsTotal'] ?? 0}',
                                    icon: Icons.rocket_launch,
                                    color: Colors.orangeAccent,
                                  ),
                                  _QuickStat(
                                    label: 'Images',
                                    value: '${_stats['imagesTotal'] ?? 0}',
                                    icon: Icons.photo_library,
                                    color: Colors.pinkAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Stats Cards
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            CosmicStatCard(
                              title: 'Book Library',
                              icon: Icons.menu_book,
                              completed: _stats['booksRead'] ?? 0,
                              total: _stats['booksTotal'] ?? 0,
                              completedLabel: 'Read',
                              pendingLabel: 'To Read',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                              ),
                              pulseAnimation: _pulseController,
                            ),
                            const SizedBox(height: 16),
                            
                            CosmicStatCard(
                              title: 'Celestial Objects',
                              icon: Icons.public,
                              completed: _stats['objectsObserved'] ?? 0,
                              total: _stats['objectsTotal'] ?? 0,
                              completedLabel: 'Observed',
                              pendingLabel: 'Pending',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D4FF), Color(0xFF0091AD)],
                              ),
                              pulseAnimation: _pulseController,
                            ),
                            const SizedBox(height: 16),
                            
                            CosmicStatCard(
                              title: 'Research Projects',
                              icon: Icons.rocket_launch,
                              completed: _stats['projectsDone'] ?? 0,
                              total: _stats['projectsTotal'] ?? 0,
                              completedLabel: 'Completed',
                              pendingLabel: 'In Progress',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                              ),
                              pulseAnimation: _pulseController,
                            ),
                            const SizedBox(height: 16),
                            
                            CosmicStatCard(
                              title: 'Research Papers',
                              icon: Icons.article,
                              completed: _stats['papersRead'] ?? 0,
                              total: _stats['papersTotal'] ?? 0,
                              completedLabel: 'Read',
                              pendingLabel: 'Unread',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                              ),
                              pulseAnimation: _pulseController,
                            ),
                            const SizedBox(height: 16),
                            
                            GlassContainer(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.cyanAccent.withOpacity(0.3),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.photo_library,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Gallery Collection',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_stats['albumsTotal'] ?? 0} Albums • ${_stats['imagesTotal'] ?? 0} Images',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;

  const GlassContainer({
    Key? key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(opacity * 0.5),
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

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const GlassButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class CosmicStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int completed;
  final int total;
  final String completedLabel;
  final String pendingLabel;
  final Gradient gradient;
  final Animation<double> pulseAnimation;

  const CosmicStatCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.completed,
    required this.total,
    required this.completedLabel,
    required this.pendingLabel,
    required this.gradient,
    required this.pulseAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (completed / total) : 0.0;
    final pending = total - completed;

    return GlassContainer(
      blur: 15,
      opacity: 0.12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total Total Items',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (bounds) => gradient.createShader(bounds),
                      child: Text(
                        '${(percentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: gradient.colors.first.withOpacity(
                                0.3 + (pulseAnimation.value * 0.3),
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress Ring
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        gradient.colors.first,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completed',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          completedLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pending',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          pendingLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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

class StarfieldPainter extends CustomPainter {
  final double animationValue;
  
  StarfieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);
    
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final starSize = random.nextDouble() * 2 + 0.5;
      final opacity = (math.sin(animationValue * math.pi * 2 + i) + 1) / 2;
      
      paint.color = Colors.white.withOpacity(opacity * 0.6);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
