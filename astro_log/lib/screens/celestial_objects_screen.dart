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
  int? _selectedClassificationId;
  List<Map<String, dynamic>> _classifications = [];

  @override
  void initState() {
    super.initState();
    _loadClassifications();
  }

  Future<void> _loadClassifications() async {
    final classifications = await _db.getClassifications();
    setState(() {
      _classifications = classifications;
    });
  }

  Future<void> _manageClassifications() async {
    await showDialog(
      context: context,
      builder: (context) => _ClassificationManagementDialog(
        classifications: _classifications,
        onClassificationsChanged: () async {
          await _loadClassifications();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _addNewObject() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final nameController = TextEditingController();
    final magnitudeController = TextEditingController();
    int? classificationId = _classifications.isNotEmpty ? _classifications[0]['id'] : null;
    bool observed = false;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('Add Celestial Object', style: TextStyle(color: Colors.white)),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Object Name (e.g., M31)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purpleAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: classificationId,
                      dropdownColor: const Color(0xFF16213E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Classification',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No Classification'),
                        ),
                        const DropdownMenuItem<int?>(
                          value: -1,
                          child: Text('+ Add New Classification'),
                        ),
                        ..._classifications.map((c) => DropdownMenuItem<int?>(
                          value: c['id'],
                          child: Text(c['name']),
                        )),
                      ],
                      onChanged: (value) async {
                        if (value == -1) {
                          final controller = TextEditingController();
                          final newClass = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A2E),
                              title: const Text('New Classification', style: TextStyle(color: Colors.white)),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Classification Name',
                                  labelStyle: TextStyle(color: Colors.white70),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, controller.text),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                          if (newClass != null && newClass.isNotEmpty) {
                            final id = await _db.insertClassification({
                              'name': newClass,
                              'createdAt': DateTime.now().toIso8601String(),
                            });
                            await _loadClassifications();
                            setDialogState(() => classificationId = id);
                          }
                        } else {
                          setDialogState(() => classificationId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: magnitudeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Magnitude (optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purpleAccent),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Mark as Observed', style: TextStyle(color: Colors.white)),
                      value: observed,
                      activeColor: Colors.purpleAccent,
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
                    
                    // Get classification name for the type field
                    String typeName = 'Unknown';
                    if (classificationId != null) {
                      final classification = _classifications.firstWhere((c) => c['id'] == classificationId);
                      typeName = classification['name'];
                    }
                    
                    await _db.insertCelestialObject({
                      'name': nameController.text,
                      'type': typeName, // Keep for backward compatibility
                      'classificationId': classificationId,
                      'magnitude': magnitudeController.text.isEmpty ? null : magnitudeController.text,
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

  Future<void> _editObject(Map<String, dynamic> object) async {
    final nameController = TextEditingController(text: object['name']);
    final magnitudeController = TextEditingController(text: object['magnitude']?.toString() ?? '');
    int? classificationId = object['classificationId'];
    bool observed = object['isObserved'] == 1;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Edit Celestial Object', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Object Name (e.g., M31)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: classificationId,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Classification',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No Classification'),
                    ),
                    const DropdownMenuItem<int?>(
                      value: -1,
                      child: Text('+ Add New Classification'),
                    ),
                    ..._classifications.map((c) => DropdownMenuItem<int?>(
                      value: c['id'],
                      child: Text(c['name']),
                    )),
                  ],
                  onChanged: (value) async {
                    if (value == -1) {
                      final controller = TextEditingController();
                      final newClass = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          title: const Text('New Classification', style: TextStyle(color: Colors.white)),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Classification Name',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, controller.text),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                      if (newClass != null && newClass.isNotEmpty) {
                        final id = await _db.insertClassification({
                          'name': newClass,
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                        await _loadClassifications();
                        setDialogState(() => classificationId = id);
                      }
                    } else {
                      setDialogState(() => classificationId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: magnitudeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Magnitude (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Mark as Observed', style: TextStyle(color: Colors.white)),
                  value: observed,
                  activeColor: Colors.purpleAccent,
                  onChanged: (value) => setDialogState(() => observed = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
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

                // Get classification name for the type field
                String typeName = 'Unknown';
                if (classificationId != null) {
                  final classification = _classifications.firstWhere((c) => c['id'] == classificationId);
                  typeName = classification['name'];
                }

                await _db.updateCelestialObject(object['id'], {
                  'name': nameController.text,
                  'type': typeName,
                  'classificationId': classificationId,
                  'magnitude': magnitudeController.text.isEmpty ? null : magnitudeController.text,
                  'imagePath': object['imagePath'],
                  'isObserved': observed ? 1 : 0,
                  'createdAt': object['createdAt'],
                });

                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _toggleObserved(Map<String, dynamic> object) async {
    await _db.updateCelestialObject(object['id'], {
      ...object,
      'isObserved': object['isObserved'] == 1 ? 0 : 1,
    });
    setState(() {});
  }

  Future<void> _deleteObject(int id, String imagePath) async {
    await _db.deleteCelestialObject(id);
    // Delete image file
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0E17),
        appBar: AppBar(
          title: const Text('Celestial Objects'),
          backgroundColor: const Color(0xFF1A1A2E),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<int?>(
                    value: _selectedClassificationId,
                    dropdownColor: const Color(0xFF16213E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Filter by Classification',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.filter_list, color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Classifications'),
                      ),
                      ..._classifications.map((c) => DropdownMenuItem<int?>(
                        value: c['id'],
                        child: Text(c['name']),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedClassificationId = value;
                      });
                    },
                  ),
                ),
                const TabBar(
                  indicatorColor: Colors.cyanAccent,
                  tabs: [
                    Tab(text: 'Observed', icon: Icon(Icons.visibility)),
                    Tab(text: 'Not Yet', icon: Icon(Icons.visibility_off)),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _ObjectGrid(
              isObserved: true,
              classificationId: _selectedClassificationId,
              onEdit: _editObject,
              onToggle: _toggleObserved,
              onDelete: _deleteObject,
            ),
            _ObjectGrid(
              isObserved: false,
              classificationId: _selectedClassificationId,
              onEdit: _editObject,
              onToggle: _toggleObserved,
              onDelete: _deleteObject,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewObject,
          backgroundColor: Colors.cyanAccent,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}

class _ObjectGrid extends StatelessWidget {
  final bool isObserved;
  final int? classificationId;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onToggle;
  final Function(int, String) onDelete;

  const _ObjectGrid({
    required this.isObserved,
    this.classificationId,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        DatabaseHelper.instance.getCelestialObjectsByClassification(
          classificationId,
          isObserved: isObserved,
        ),
        DatabaseHelper.instance.getClassifications(),
      ]).then((results) => <String, dynamic>{'objects': results[0], 'classifications': results[1]}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text(
                  'No ${isObserved ? 'observed' : 'unobserved'} objects',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a celestial object',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data as Map;
        final objects = data['objects'] as List<Map<String, dynamic>>;
        final classifications = data['classifications'] as List<Map<String, dynamic>>;

        if (objects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.public, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text(
                  'No ${isObserved ? 'observed' : 'unobserved'} objects',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          );
        }

        // Group objects by classification
        final Map<String, List<Map<String, dynamic>>> groupedObjects = {};
        
        // Add unassigned objects first (only if there are any)
        final unassignedObjects = objects.where((o) => o['classificationId'] == null).toList();
        if (unassignedObjects.isNotEmpty) {
          groupedObjects['Unassigned'] = unassignedObjects;
        }
        
        // Add objects grouped by classification
        for (var classification in classifications) {
          final classObjects = objects.where((o) => o['classificationId'] == classification['id']).toList();
          if (classObjects.isNotEmpty) {
            groupedObjects[classification['name']] = classObjects;
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedObjects.length,
          itemBuilder: (context, index) {
            final classificationName = groupedObjects.keys.elementAt(index);
            final classObjects = groupedObjects[classificationName]!;

            return Container(
              margin: EdgeInsets.only(bottom: index < groupedObjects.length - 1 ? 24 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, color: Colors.cyanAccent, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          classificationName,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${classObjects.length}',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: classObjects.length,
                      itemBuilder: (ctx, idx) {
                        final object = classObjects[idx];
                        return _ObjectCard(
                          object: object,
                          onEdit: () => onEdit(object),
                          onToggle: () => onToggle(object),
                          onDelete: () => onDelete(object['id'], object['imagePath']),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ObjectCard extends StatelessWidget {
  final Map<String, dynamic> object;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ObjectCard({
    required this.object,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = object['magnitude'] != null && object['magnitude'].toString().isNotEmpty
        ? '${object['type']} • Mag ${object['magnitude']}'
        : object['type'];

    return ImageCard(
      imagePath: object['imagePath'],
      title: object['name'],
      subtitle: subtitle,
      topRightButton: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        color: const Color(0xFF16213E),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit', style: TextStyle(color: Colors.white)),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Text(
              object['isObserved'] == 1 ? 'Mark as Not Observed' : 'Mark as Observed',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            onEdit();
          } else if (value == 'toggle') {
            onToggle();
          } else if (value == 'delete') {
            onDelete();
          }
        },
      ),
    );
  }
}

class _ClassificationManagementDialog extends StatefulWidget {
  final List<Map<String, dynamic>> classifications;
  final VoidCallback onClassificationsChanged;

  const _ClassificationManagementDialog({
    required this.classifications,
    required this.onClassificationsChanged,
  });

  @override
  State<_ClassificationManagementDialog> createState() => _ClassificationManagementDialogState();
}

class _ClassificationManagementDialogState extends State<_ClassificationManagementDialog> {
  final _db = DatabaseHelper.instance;

  Future<void> _addClassification() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Add Classification', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Classification Name',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _db.insertClassification({
                  'name': controller.text,
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (context.mounted) Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onClassificationsChanged();
    }
  }

  Future<void> _deleteClassification(int id) async {
    await _db.deleteClassification(id);
    widget.onClassificationsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Manage Classifications', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.classifications.length,
          itemBuilder: (context, index) {
            final classification = widget.classifications[index];
            return ListTile(
              title: Text(classification['name'], style: const TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteClassification(classification['id']),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _addClassification,
          child: const Text('Add Classification'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
