import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../widgets/image_card.dart';

class CelestialObjectsScreen extends StatefulWidget {
  const CelestialObjectsScreen({Key? key}) : super(key: key);

  @override
  State<CelestialObjectsScreen> createState() => _CelestialObjectsScreenState();
}

class _CelestialObjectsScreenState extends State<CelestialObjectsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _addNewObject() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final nameController = TextEditingController();
    final magnitudeController = TextEditingController();
    String selectedType = 'Galaxy';
    bool observed = false;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Celestial Object'),
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
                        labelText: 'Object Name (e.g., M31)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Galaxy', 'Nebula', 'Star Cluster', 'Planet', 'Comet', 'Supernova']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedType = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: magnitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Magnitude (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SwitchListTile(
                      title: const Text('Mark as Observed'),
                      value: observed,
                      onChanged: (value) => setDialogState(() => observed = value),
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
                        const SnackBar(content: Text('Please enter object name')),
                      );
                      return;
                    }

                    final savedPath = await _db.saveImage(File(image.path));
                    await _db.insertCelestialObject({
                      'name': nameController.text,
                      'type': selectedType,
                      'magnitude': magnitudeController.text.isEmpty ? 'Unknown' : magnitudeController.text,
                      'imagePath': savedPath,
                      'isObserved': observed ? 1 : 0,
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

  Future<void> _toggleObserved(Map<String, dynamic> object) async {
    await _db.updateCelestialObject(object['id'], {
      ...object,
      'isObserved': object['isObserved'] == 1 ? 0 : 1,
    });
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(object['isObserved'] == 1 ? 'Moved to Not Yet' : 'Marked as Observed'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteObject(int id) async {
    await _db.deleteCelestialObject(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Celestial Objects'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Observed', icon: Icon(Icons.visibility)),
              Tab(text: 'Not Yet', icon: Icon(Icons.visibility_off)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ObjectGrid(isObserved: true, onToggle: _toggleObserved, onDelete: _deleteObject),
            _ObjectGrid(isObserved: false, onToggle: _toggleObserved, onDelete: _deleteObject),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewObject,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ObjectGrid extends StatelessWidget {
  final bool isObserved;
  final Function(Map<String, dynamic>) onToggle;
  final Function(int) onDelete;

  const _ObjectGrid({
    required this.isObserved,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getCelestialObjects(isObserved: isObserved),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${isObserved ? 'observed' : 'planned'} objects yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add an object image',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final objects = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: objects.length,
          itemBuilder: (context, index) {
            final object = objects[index];
            return ImageCard(
              imagePath: object['imagePath'],
              title: object['name'],
              subtitle: '${object['type']} • Mag ${object['magnitude']}',
              onLongPress: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Object?'),
                    content: Text('Remove "${object['name']}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete(object['id']);
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
                    object['isObserved'] == 1 ? Icons.remove_circle : Icons.visibility,
                    color: object['isObserved'] == 1 ? Colors.orange : Colors.blue,
                    size: 20,
                  ),
                  onPressed: () => onToggle(object),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
