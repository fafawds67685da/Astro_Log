import 'package:flutter/material.dart';

class CelestialObjectsScreen extends StatelessWidget {
  const CelestialObjectsScreen({Key? key}) : super(key: key);

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
            _ObjectList(isObserved: true),
            _ObjectList(isObserved: false),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ObjectList extends StatelessWidget {
  final bool isObserved;
  
  const _ObjectList({required this.isObserved});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: isObserved ? 48 : 72,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.public,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('Object ${index + 1}'),
            subtitle: Text('Galaxy • Magnitude 8.4'),
            trailing: Icon(
              isObserved ? Icons.visibility : Icons.visibility_off,
              color: isObserved ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
