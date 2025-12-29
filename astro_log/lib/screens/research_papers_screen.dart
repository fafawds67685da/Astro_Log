import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class ResearchPapersScreen extends StatefulWidget {
  const ResearchPapersScreen({super.key});

  @override
  State<ResearchPapersScreen> createState() => _ResearchPapersScreenState();
}

class _ResearchPapersScreenState extends State<ResearchPapersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addNewPaper() async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final linkController = TextEditingController();
    String status = 'Pending';
    String type = 'Research Paper';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Add Research Paper / Article', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: ['Research Paper', 'Article'].map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      type = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: authorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Author(s)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: ['Done', 'Pending', 'Underway'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      status = value!;
                    });
                  },
                ),
                if (status == 'Done') const SizedBox(height: 16),
                if (status == 'Done') TextField(
                  controller: linkController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Link (where it is posted)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
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
                if (titleController.text.isNotEmpty) {
                  await _dbHelper.insertResearchPaper({
                    'title': titleController.text,
                    'author': authorController.text,
                    'type': type,
                    'link': linkController.text.isEmpty ? null : linkController.text,
                    'imagePath': '',
                    'status': status,
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                  if (context.mounted) Navigator.pop(context, true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _changeStatus(int id, String currentStatus, String newStatus) async {
    final papers = await _dbHelper.getResearchPapers();
    final paper = papers.firstWhere((p) => p['id'] == id);
    
    String? link = paper['link'];
    
    // If marking as Done, ask for link
    if (newStatus == 'Done' && (link == null || link.isEmpty)) {
      final linkController = TextEditingController();
      final result = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Add Link', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: linkController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Link (where it is posted)',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.purpleAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, linkController.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      
      if (result != null && result.isNotEmpty) {
        link = result;
      }
    }
    
    await _dbHelper.updateResearchPaper(id, {
      'title': paper['title'],
      'author': paper['author'],
      'type': paper['type'] ?? 'Research Paper',
      'link': link,
      'imagePath': paper['imagePath'],
      'status': newStatus,
      'createdAt': paper['createdAt'],
    });
    
    setState(() {});
  }

  Future<void> _deletePaper(int id, String imagePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Paper?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: Colors.white70)),
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
      await _dbHelper.deleteResearchPaper(id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Research Papers / Articles'),
        backgroundColor: const Color(0xFF1A1A2E),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          tabs: const [
            Tab(text: 'Done'),
            Tab(text: 'Pending'),
            Tab(text: 'Underway'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PapersGrid(status: 'Done', onChangeStatus: _changeStatus, onDelete: _deletePaper),
          _PapersGrid(status: 'Pending', onChangeStatus: _changeStatus, onDelete: _deletePaper),
          _PapersGrid(status: 'Underway', onChangeStatus: _changeStatus, onDelete: _deletePaper),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPaper,
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PapersGrid extends StatelessWidget {
  final String status;
  final Function(int, String, String) onChangeStatus;
  final Function(int, String) onDelete;

  const _PapersGrid({
    required this.status,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getResearchPapers(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text(
                  'No $status Papers',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a research paper',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final papers = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: papers.length,
          itemBuilder: (context, index) {
            final paper = papers[index];
            return _PaperListTile(
              paper: paper,
              index: index + 1,
              status: status,
              onChangeStatus: onChangeStatus,
              onDelete: onDelete,
            );
          },
        );
      },
    );
  }
}

class _PaperListTile extends StatelessWidget {
  final Map<String, dynamic> paper;
  final int index;
  final String status;
  final Function(int, String, String) onChangeStatus;
  final Function(int, String) onDelete;

  const _PaperListTile({
    required this.paper,
    required this.index,
    required this.status,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = paper['type'] ?? 'Research Paper';
    final hasLink = paper['link'] != null && paper['link'].toString().isNotEmpty;
    
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purpleAccent,
          child: Text(
            '$index',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                paper['title'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: type == 'Article' ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: type == 'Article' ? Colors.orange : Colors.blue,
                  width: 1,
                ),
              ),
              child: Text(
                type == 'Article' ? 'A' : 'RP',
                style: TextStyle(
                  color: type == 'Article' ? Colors.orange : Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paper['author'] != null && paper['author'].toString().isNotEmpty)
              Text(
                paper['author'],
                style: const TextStyle(color: Colors.white60),
              ),
            if (hasLink)
              Row(
                children: [
                  const Icon(Icons.link, size: 14, color: Colors.purpleAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      paper['link'],
                      style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF16213E),
          itemBuilder: (context) => [
            if (status != 'Done')
              const PopupMenuItem(
                value: 'done',
                child: Text('Mark as Done', style: TextStyle(color: Colors.white)),
              ),
            if (status != 'Underway')
              const PopupMenuItem(
                value: 'underway',
                child: Text('Mark as Underway', style: TextStyle(color: Colors.white)),
              ),
            if (status != 'Pending')
              const PopupMenuItem(
                value: 'pending',
                child: Text('Mark as Pending', style: TextStyle(color: Colors.white)),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              onDelete(paper['id'], paper['imagePath'] ?? '');
            } else {
              String newStatus = value == 'done' ? 'Done' : value == 'underway' ? 'Underway' : 'Pending';
              onChangeStatus(paper['id'], status, newStatus);
            }
          },
        ),
      ),
    );
  }
}
