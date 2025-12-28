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
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _readingStats = {};
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
      
      // Get reading statistics
      _readingStats = await db.getReadingStatistics();
      
      final books = await db.getBooksByGenre(null);
      
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
            'booksRead': _readingStats['booksRead'],
            'booksTotal': _readingStats['totalBooks'],
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
          _readingStats = {};
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
                      
                      // Reading Statistics
                      if (_readingStats.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                            child: Text(
                              '📚 Reading Statistics',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ),
                        
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GlassContainer(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Books breakdown
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _StatPill(
                                          label: 'Read',
                                          value: '${_readingStats['booksRead']}',
                                          icon: '✓',
                                          color: Colors.green,
                                        ),
                                        _StatPill(
                                          label: 'Reading',
                                          value: '${_readingStats['booksReading']}',
                                          icon: '📖',
                                          color: Colors.blue,
                                        ),
                                        _StatPill(
                                          label: 'To Read',
                                          value: '${_readingStats['booksNotRead']}',
                                          icon: '○',
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    
                                    if (_readingStats['totalPages'] > 0) ...[
                                      const Divider(height: 32),
                                      
                                      // Overall progress bar
                                      Text(
                                        'Overall Reading Progress',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: _readingStats['overallProgress'] / 100,
                                          minHeight: 12,
                                          backgroundColor: Colors.grey[800],
                                          valueColor: const AlwaysStoppedAnimation(Colors.purpleAccent),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${_readingStats['overallProgress'].toStringAsFixed(1)}% Complete',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.purpleAccent.withOpacity(0.8),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${_readingStats['totalPagesCompleted']} / ${_readingStats['totalPages']} pages',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Stats grid
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _StatsBox(
                                              label: 'Pages Read',
                                              value: '${_readingStats['pagesRead']}',
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatsBox(
                                              label: 'Currently Reading',
                                              value: '${_readingStats['currentlyReadingPages']}',
                                              subtitle: 'of ${_readingStats['currentlyReadingTotalPages']}',
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _StatsBox(
                                              label: 'Remaining',
                                              value: '${_readingStats['pagesRemaining']}',
                                              subtitle: 'pages to go',
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _StatsBox(
                                              label: 'Read Rate',
                                              value: '${_readingStats['readPercentage'].toStringAsFixed(0)}%',
                                              subtitle: 'of collection',
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      // Stats Cards
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            const SizedBox(height: 24),
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

// Helper widget for stat pills
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;
  
  const _StatPill({
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

// Helper widget for stats boxes
class _StatsBox extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  
  const _StatsBox({
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}
