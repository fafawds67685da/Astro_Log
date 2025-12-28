import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class GenreSeriesManagerScreen extends StatefulWidget {
  const GenreSeriesManagerScreen({Key? key}) : super(key: key);

  @override
  State<GenreSeriesManagerScreen> createState() => _GenreSeriesManagerScreenState();
}

class _GenreSeriesManagerScreenState extends State<GenreSeriesManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseHelper.instance;
  
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _series = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _genres = await _db.getGenres();
    _series = await _db.getBookSeries();
    setState(() => _isLoading = false);
  }
  
  // === GENRE METHODS ===
  
  Future<void> _showGenreDialog({Map<String, dynamic>? genre}) async {
    final nameController = TextEditingController(text: genre?['name'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(genre == null ? 'Add Genre' : 'Edit Genre'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Genre Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              
              if (genre == null) {
                await _db.insertGenre({'name': name});
              } else {
                await _db.updateGenre(genre['id'], {'name': name});
              }
              
              await _loadData();
              if (mounted) Navigator.pop(context);
            },
            child: Text(genre == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteGenre(Map<String, dynamic> genre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Genre'),
        content: Text('Delete "${genre['name']}"?\n\nThis will remove the genre from all books.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _db.deleteGenre(genre['id']);
      await _loadData();
    }
  }
  
  // === SERIES METHODS ===
  
  Future<void> _showSeriesDialog({Map<String, dynamic>? series}) async {
    final nameController = TextEditingController(text: series?['name'] ?? '');
    final descController = TextEditingController(text: series?['description'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(series == null ? 'Add Series' : 'Edit Series'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Series Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              
              final data = {
                'name': name,
                'description': descController.text.trim(),
              };
              
              if (series == null) {
                await _db.insertBookSeries(data);
              } else {
                await _db.updateBookSeries(series['id'], data);
              }
              
              await _loadData();
              if (mounted) Navigator.pop(context);
            },
            child: Text(series == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteSeries(Map<String, dynamic> series) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Series'),
        content: Text('Delete "${series['name']}"?\n\nBooks in this series will become standalone books.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _db.deleteBookSeries(series['id']);
      await _loadData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Genres & Series'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Genres'),
            Tab(icon: Icon(Icons.collections_bookmark), text: 'Series'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGenresTab(),
                _buildSeriesTab(),
              ],
            ),
    );
  }
  
  Widget _buildGenresTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Delete genres you no longer need. Add new genres while creating/editing books.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _genres.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category_outlined, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text('No genres yet', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Tap "Add Genre" to create one'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(genre['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGenre(genre),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildSeriesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Delete series you no longer need. Add new series while creating/editing books.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _series.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text('No series yet', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Tap "Add Series" to create one'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _series.length,
                  itemBuilder: (context, index) {
                    final series = _series[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: const Icon(Icons.collections_bookmark),
                        ),
                        title: Text(series['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: series['description']?.toString().isNotEmpty == true
                            ? Text(series['description'])
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSeries(series),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
