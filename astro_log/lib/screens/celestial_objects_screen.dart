import 'package:flutter/material.dart';

class CelestialObjectsScreen extends StatefulWidget {
  const CelestialObjectsScreen({Key? key}) : super(key: key);

  @override
  State<CelestialObjectsScreen> createState() => _CelestialObjectsScreenState();
}

class _CelestialObjectsScreenState extends State<CelestialObjectsScreen> {
  final List<Map<String, dynamic>> observedObjects = List.generate(
    48,
    (i) => {'name': 'Object ${i + 1}', 'type': 'Galaxy', 'magnitude': '8.4'},
  );
  
  final List<Map<String, dynamic>> notYetObjects = List.generate(
    72,
    (i) => {'name': 'Object ${i + 49}', 'type': 'Nebula', 'magnitude': '9.2'},
  );

  void _addNewObject() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final magnitudeController = TextEditingController();
        String selectedType = 'Galaxy';
        bool observed = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Celestial Object'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Object Name (e.g., M31)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: ['Galaxy', 'Nebula', 'Star Cluster', 'Planet', 'Comet', 'Supernova']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedType = value!),
                    ),
                    TextField(
                      controller: magnitudeController,
                      decoration: const InputDecoration(labelText: 'Magnitude (optional)'),
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
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        final object = {
                          'name': nameController.text,
                          'type': selectedType,
                          'magnitude': magnitudeController.text.isEmpty 
                              ? 'Unknown' 
                              : magnitudeController.text,
                        };
                        if (observed) {
                          observedObjects.add(object);
                        } else {
                          notYetObjects.add(object);
                        }
                      });
                      Navigator.pop(context);
                    }
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

  void _moveToObserved(int index) {
    setState(() {
      observedObjects.add(notYetObjects[index]);
      notYetObjects.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as Observed'), duration: Duration(seconds: 1)),
    );
  }

  void _moveToNotYet(int index) {
    setState(() {
      notYetObjects.add(observedObjects[index]);
      observedObjects.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to Not Yet'), duration: Duration(seconds: 1)),
    );
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
            _ObjectList(objects: observedObjects, observed: true, onMove: _moveToNotYet),
            _ObjectList(objects: notYetObjects, observed: false, onMove: _moveToObserved),
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

class _ObjectList extends StatelessWidget {
  final List<Map<String, dynamic>> objects;
  final bool observed;
  final Function(int) onMove;
  
  const _ObjectList({
    required this.objects,
    required this.observed,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (objects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ${observed ? 'observed' : 'planned'} objects yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: objects.length,
      itemBuilder: (context, index) {
        final object = objects[index];
        return Dismissible(
          key: Key('${object['name']}_$index'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onMove(index),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: observed ? Colors.orange : Colors.blue,
            child: Icon(
              observed ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.public,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(object['name']),
              subtitle: Text('${object['type']} • Magnitude ${object['magnitude']}'),
              trailing: IconButton(
                icon: Icon(
                  observed ? Icons.remove_circle : Icons.visibility,
                  color: observed ? Colors.orange : Colors.blue,
                ),
                onPressed: () => onMove(index),
              ),
            ),
          ),
        );
      },
    );
  }
}
