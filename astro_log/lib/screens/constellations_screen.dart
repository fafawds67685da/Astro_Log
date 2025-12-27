import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../widgets/image_card.dart';

class ConstellationsScreen extends StatefulWidget {
  const ConstellationsScreen({Key? key}) : super(key: key);

  @override
  State<ConstellationsScreen> createState() => _ConstellationsScreenState();
}

class _ConstellationsScreenState extends State<ConstellationsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _addNewConstellation() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final nameController = TextEditingController();
    String selectedHemisphere = 'Northern';
    String selectedSeason = 'Winter';
    bool identified = false;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Constellation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Constellation Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedHemisphere,
                      decoration: const InputDecoration(
                        labelText: 'Hemisphere',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Northern', 'Southern', 'Equatorial']
                          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedHemisphere = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedSeason,
                      decoration: const InputDecoration(
                        labelText: 'Best Season',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Winter', 'Spring', 'Summer', 'Autumn', 'Year-round']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedSeason = value!),
                    ),
                    SwitchListTile(
                      title: const Text('Mark as Identified'),
                      value: identified,
                      onChanged: (value) => setDialogState(() => identified = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter constellation name')),
                      );
                      return;
                    }

                    final savedPath = await _db.saveImage(File(image.path));
                    await _db.insertConstellation({
                      'name': nameController.text,
                      'hemisphere': selectedHemisphere,
                      'season': selectedSeason,
                      'imagePath': savedPath,
                      'isIdentified': identified ? 1 : 0,
                      'createdAt': DateTime.now().toIso8601String(),
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleIdentified(Map<String, dynamic> constellation) async {
    await _db.updateConstellation(constellation['id'], {
      ...constellation,
      'isIdentified': constellation['isIdentified'] == 1 ? 0 : 1,
    });
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(constellation['isIdentified'] == 1 ? 'Moved to Not Yet' : 'Marked as Identified'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteConstellation(int id) async {
    await _db.deleteConstellation(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getConstellations(),
      builder: (context, snapshot) {
        final identified = snapshot.data?.where((c) => c['isIdentified'] == 1).length ?? 0;
        final notYet = snapshot.data?.where((c) => c['isIdentified'] == 0).length ?? 0;
        final total = identified + notYet;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Constellations ($total)'),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Identified ($identified)', icon: const Icon(Icons.stars)),
                  Tab(text: 'Not Yet ($notYet)', icon: const Icon(Icons.star_border)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ConstellationGrid(isIdentified: true, onToggle: _toggleIdentified, onDelete: _deleteConstellation),
                _ConstellationGrid(isIdentified: false, onToggle: _toggleIdentified, onDelete: _deleteConstellation),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _addNewConstellation,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}

class _ConstellationGrid extends StatelessWidget {
  final bool isIdentified;
  final Function(Map<String, dynamic>) onToggle;
  final Function(int) onDelete;

  const _ConstellationGrid({
    required this.isIdentified,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getConstellations(isIdentified: isIdentified),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nights_stay, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${isIdentified ? 'identified' : 'unidentified'} constellations yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add constellation image',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final constellations = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: constellations.length,
          itemBuilder: (context, index) {
            final constellation = constellations[index];
            return ImageCard(
              imagePath: constellation['imagePath'],
              title: constellation['name'],
              subtitle: '${constellation['hemisphere']} • ${constellation['season']}',
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Constellation?'),
                    content: Text('Remove "${constellation['name']}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete(constellation['id']);
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              topRightButton: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.6),
                radius: 18,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    constellation['isIdentified'] == 1 ? Icons.remove_circle : Icons.stars,
                    color: constellation['isIdentified'] == 1 ? Colors.orange : Colors.amber,
                    size: 20,
                  ),
                  onPressed: () => onToggle(constellation),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
