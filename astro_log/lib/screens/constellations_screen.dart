import 'package:flutter/material.dart';

class ConstellationsScreen extends StatefulWidget {
  const ConstellationsScreen({Key? key}) : super(key: key);

  @override
  State<ConstellationsScreen> createState() => _ConstellationsScreenState();
}

class _ConstellationsScreenState extends State<ConstellationsScreen> {
  final List<Map<String, dynamic>> identifiedConstellations = List.generate(
    35,
    (i) => {'name': 'Constellation ${i + 1}', 'hemisphere': 'Northern', 'season': 'Winter'},
  );
  
  final List<Map<String, dynamic>> notYetConstellations = List.generate(
    53,
    (i) => {'name': 'Constellation ${i + 36}', 'hemisphere': 'Southern', 'season': 'Summer'},
  );

  void _moveToIdentified(int index) {
    setState(() {
      identifiedConstellations.add(notYetConstellations[index]);
      notYetConstellations.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as Identified'), duration: Duration(seconds: 1)),
    );
  }

  void _moveToNotYet(int index) {
    setState(() {
      notYetConstellations.add(identifiedConstellations[index]);
      identifiedConstellations.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to Not Yet'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = identifiedConstellations.length + notYetConstellations.length;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Constellations ($total)'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Identified (${identifiedConstellations.length})', icon: const Icon(Icons.stars)),
              Tab(text: 'Not Yet (${notYetConstellations.length})', icon: const Icon(Icons.star_border)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ConstellationList(constellations: identifiedConstellations, identified: true, onMove: _moveToNotYet),
            _ConstellationList(constellations: notYetConstellations, identified: false, onMove: _moveToIdentified),
          ],
        ),
      ),
    );
  }
}

class _ConstellationList extends StatelessWidget {
  final List<Map<String, dynamic>> constellations;
  final bool identified;
  final Function(int) onMove;
  
  const _ConstellationList({
    required this.constellations,
    required this.identified,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: constellations.length,
      itemBuilder: (context, index) {
        final constellation = constellations[index];
        return Dismissible(
          key: Key('${constellation['name']}_$index'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onMove(index),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: identified ? Colors.orange : Colors.amber,
            child: Icon(
              identified ? Icons.star_border : Icons.stars,
              color: Colors.white,
            ),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                identified ? Icons.stars : Icons.star_border,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(constellation['name']),
              subtitle: Text('${constellation['hemisphere']} Hemisphere • ${constellation['season']}'),
              trailing: IconButton(
                icon: Icon(
                  identified ? Icons.remove_circle : Icons.stars,
                  color: identified ? Colors.orange : Colors.amber,
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
