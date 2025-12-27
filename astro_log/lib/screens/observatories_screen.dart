import 'package:flutter/material.dart';

class ObservatoriesScreen extends StatefulWidget {
  const ObservatoriesScreen({Key? key}) : super(key: key);

  @override
  State<ObservatoriesScreen> createState() => _ObservatoriesScreenState();
}

class _ObservatoriesScreenState extends State<ObservatoriesScreen> {
  final List<Map<String, dynamic>> visitedObservatories = List.generate(
    5,
    (i) => {'name': 'Observatory ${i + 1}', 'location': 'Location, Country'},
  );
  
  final List<Map<String, dynamic>> toVisitObservatories = List.generate(
    10,
    (i) => {'name': 'Observatory ${i + 6}', 'location': 'Location, Country'},
  );

  void _addNewObservatory() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final locationController = TextEditingController();
        bool visited = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Observatory'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Observatory Name'),
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
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
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      setState(() {
                        final observatory = {
                          'name': nameController.text,
                          'location': locationController.text.isEmpty 
                              ? 'Unknown Location' 
                              : locationController.text,
                        };
                        if (visited) {
                          visitedObservatories.add(observatory);
                        } else {
                          toVisitObservatories.add(observatory);
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

  void _moveToVisited(int index) {
    setState(() {
      visitedObservatories.add(toVisitObservatories[index]);
      toVisitObservatories.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to Visited'), duration: Duration(seconds: 1)),
    );
  }

  void _moveToVisit(int index) {
    setState(() {
      toVisitObservatories.add(visitedObservatories[index]);
      visitedObservatories.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to To Visit'), duration: Duration(seconds: 1)),
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
            _ObservatoryList(observatories: visitedObservatories, visited: true, onMove: _moveToVisit),
            _ObservatoryList(observatories: toVisitObservatories, visited: false, onMove: _moveToVisited),
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

class _ObservatoryList extends StatelessWidget {
  final List<Map<String, dynamic>> observatories;
  final bool visited;
  final Function(int) onMove;
  
  const _ObservatoryList({
    required this.observatories,
    required this.visited,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (observatories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No ${visited ? 'visited' : 'planned'} observatories yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: observatories.length,
      itemBuilder: (context, index) {
        final observatory = observatories[index];
        return Dismissible(
          key: Key('${observatory['name']}_$index'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onMove(index),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: visited ? Colors.orange : Colors.green,
            child: Icon(
              visited ? Icons.location_on : Icons.check_circle,
              color: Colors.white,
            ),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.location_city,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(observatory['name']),
              subtitle: Text(observatory['location']),
              trailing: IconButton(
                icon: Icon(
                  visited ? Icons.remove_circle : Icons.check_circle,
                  color: visited ? Colors.orange : Colors.green,
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
