import 'package:flutter/material.dart';

class ObservatoriesScreen extends StatelessWidget {
  const ObservatoriesScreen({Key? key}) : super(key: key);

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
            _ObservatoryList(isVisited: true),
            _ObservatoryList(isVisited: false),
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

class _ObservatoryList extends StatelessWidget {
  final bool isVisited;
  
  const _ObservatoryList({required this.isVisited});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: isVisited ? 5 : 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.location_city,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('Observatory ${index + 1}'),
            subtitle: Text('Location, Country'),
            trailing: Icon(
              isVisited ? Icons.check_circle : Icons.location_on,
              color: isVisited ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }
}
