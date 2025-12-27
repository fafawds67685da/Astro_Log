import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../widgets/image_card.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  final List<String> telescopes = [
    'James Webb',
    'Hubble',
    'Chandra',
    'Spitzer',
    'My Telescope',
  ];

  Future<void> _addImage(String telescope) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final titleController = TextEditingController();
    final descController = TextEditingController();

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add to $telescope'),
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
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Image Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a title')),
                  );
                  return;
                }

                final savedPath = await _db.saveImage(File(image.path));
                await _db.insertGalleryImage({
                  'telescope': telescope,
                  'imagePath': savedPath,
                  'title': titleController.text,
                  'description': descController.text,
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
  }

  Future<void> _deleteImage(int id) async {
    await _db.deleteGalleryImage(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: telescopes.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Telescope Gallery'),
          bottom: TabBar(
            isScrollable: true,
            tabs: telescopes.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: TabBarView(
          children: telescopes.map((telescope) {
            return _TelescopeGallery(
              telescope: telescope,
              onAdd: () => _addImage(telescope),
              onDelete: _deleteImage,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TelescopeGallery extends StatelessWidget {
  final String telescope;
  final VoidCallback onAdd;
  final Function(int) onDelete;

  const _TelescopeGallery({
    required this.telescope,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getGalleryImages(telescope: telescope),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final images = snapshot.data ?? [];
        
        return Stack(
          children: [
            if (images.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No images in $telescope gallery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add images',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final img = images[index];
                  return ImageCard(
                    imagePath: img['imagePath'],
                    title: img['title'],
                    subtitle: img['description'] ?? '',
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Image?'),
                          content: Text('Remove "${img['title']}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete(img['id']);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: onAdd,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}
