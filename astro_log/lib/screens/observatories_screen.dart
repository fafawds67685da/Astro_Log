import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/database_helper.dart';
import '../widgets/image_card.dart';

class ObservatoriesScreen extends StatefulWidget {
  const ObservatoriesScreen({Key? key}) : super(key: key);

  @override
  State<ObservatoriesScreen> createState() => _ObservatoriesScreenState();
}

class _ObservatoriesScreenState extends State<ObservatoriesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _addNewObservatory() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    bool visited = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Observatory'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Observatory Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Mark as Visited'),
                    value: visited,
                    onChanged: (value) => setDialogState(() => visited = value),
                  ),
                ],
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
                        const SnackBar(content: Text('Please enter observatory name')),
                      );
                      return;
                    }

                    await _db.insertObservatory({
                      'name': nameController.text,
                      'location': locationController.text.isEmpty ? 'Unknown' : locationController.text,
                      'isVisited': visited ? 1 : 0,
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

  Future<void> _toggleVisited(Map<String, dynamic> observatory) async {
    await _db.updateObservatory(observatory['id'], {
      ...observatory,
      'isVisited': observatory['isVisited'] == 1 ? 0 : 1,
    });
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(observatory['isVisited'] == 1 ? 'Moved to To Visit' : 'Marked as Visited'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteObservatory(int id) async {
    await _db.deleteObservatory(id);
    setState(() {});
  }

  Future<void> _addImageToObservatory(int observatoryId, String name) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final captionController = TextEditingController();

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Photo to $name'),
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
                  controller: captionController,
                  decoration: const InputDecoration(
                    labelText: 'Caption (optional)',
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
                final savedPath = await _db.saveImage(File(image.path));
                await _db.insertObservatoryImage({
                  'observatoryId': observatoryId,
                  'imagePath': savedPath,
                  'caption': captionController.text,
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Observatories'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Visited', icon: Icon(Icons.check_circle)),
              Tab(text: 'To Visit', icon: Icon(Icons.location_on)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _VisitedList(
              onToggle: _toggleVisited,
              onDelete: _deleteObservatory,
              onAddImage: _addImageToObservatory,
            ),
            _ToVisitList(
              onToggle: _toggleVisited,
              onDelete: _deleteObservatory,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewObservatory,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// VISITED - Rich image cards
class _VisitedList extends StatelessWidget {
  final Function(Map<String, dynamic>) onToggle;
  final Function(int) onDelete;
  final Function(int, String) onAddImage;

  const _VisitedList({
    required this.onToggle,
    required this.onDelete,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getObservatories(isVisited: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_city, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No visited observatories yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mark an observatory as visited to add photos',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final observatories = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: observatories.length,
          itemBuilder: (context, index) {
            final obs = observatories[index];
            return _ObservatoryCard(
              observatory: obs,
              onToggle: () => onToggle(obs),
              onDelete: () => onDelete(obs['id']),
              onAddImage: () => onAddImage(obs['id'], obs['name']),
            );
          },
        );
      },
    );
  }
}

class _ObservatoryCard extends StatelessWidget {
  final Map<String, dynamic> observatory;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onAddImage;

  const _ObservatoryCard({
    required this.observatory,
    required this.onToggle,
    required this.onDelete,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(
              observatory['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(observatory['location']),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: onToggle,
                  child: const Row(
                    children: [
                      Icon(Icons.remove_circle, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Move to To Visit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: onDelete,
                  child: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseHelper.instance.getObservatoryImages(observatory['id']),
            builder: (context, snapshot) {
              final images = snapshot.data ?? [];
              
              return Column(
                children: [
                  if (images.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No photos yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: images.length,
                        itemBuilder: (context, idx) {
                          final img = images[idx];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(img['imagePath']),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton.icon(
                      onPressed: onAddImage,
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Photo'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// TO VISIT - Simple text list
class _ToVisitList extends StatelessWidget {
  final Function(Map<String, dynamic>) onToggle;
  final Function(int) onDelete;

  const _ToVisitList({
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getObservatories(isVisited: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No planned observatories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add one',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final observatories = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: observatories.length,
          itemBuilder: (context, index) {
            final obs = observatories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: Text(obs['name']),
                subtitle: Text(obs['location']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => onToggle(obs),
                      tooltip: 'Mark as Visited',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete?'),
                            content: Text('Remove "${obs['name']}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete(obs['id']);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
