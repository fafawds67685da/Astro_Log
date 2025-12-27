import 'package:flutter/material.dart';

class ConstellationsScreen extends StatelessWidget {
  const ConstellationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Constellations (88)'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Identified', icon: Icon(Icons.stars)),
              Tab(text: 'Not Yet', icon: Icon(Icons.star_border)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ConstellationList(isIdentified: true),
            _ConstellationList(isIdentified: false),
          ],
        ),
      ),
    );
  }
}

class _ConstellationList extends StatelessWidget {
  final bool isIdentified;
  
  const _ConstellationList({required this.isIdentified});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: isIdentified ? 35 : 53,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              isIdentified ? Icons.stars : Icons.star_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('Constellation ${index + 1}'),
            subtitle: Text('Northern Hemisphere • Winter'),
            trailing: Icon(
              isIdentified ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isIdentified ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
