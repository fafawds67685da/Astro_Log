import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_helper.dart';
import '../widgets/image_card.dart';

class ResearchPapersScreen extends StatefulWidget {
  const ResearchPapersScreen({super.key});

  @override
  State<ResearchPapersScreen> createState() => _ResearchPapersScreenState();
}

class _ResearchPapersScreenState extends State<ResearchPapersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _dbHelper = DatabaseHelper.instance;
  final _picker = ImagePicker();

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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final titleController = TextEditingController();
    final authorController = TextEditingController();
    String status = 'Pending';

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Add Research Paper', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Paper Title',
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
                  final imagePath = await _dbHelper.saveImage(File(image.path));
                  await _dbHelper.insertResearchPaper({
                    'title': titleController.text,
                    'author': authorController.text,
                    'imagePath': imagePath,
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
    
    await _dbHelper.updateResearchPaper(id, {
      'title': paper['title'],
      'author': paper['author'],
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
      // Delete image file
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Research Papers'),
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
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: papers.length,
          itemBuilder: (context, index) {
            final paper = papers[index];
            return _PaperCard(
              paper: paper,
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

class _PaperCard extends StatelessWidget {
  final Map<String, dynamic> paper;
  final String status;
  final Function(int, String, String) onChangeStatus;
  final Function(int, String) onDelete;

  const _PaperCard({
    required this.paper,
    required this.status,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ImageCard(
      imagePath: paper['imagePath'],
      title: paper['title'],
      subtitle: paper['author'],
      topRightButton: PopupMenuButton<String>(
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
            onDelete(paper['id'], paper['imagePath']);
          } else {
            String newStatus = value == 'done' ? 'Done' : value == 'underway' ? 'Underway' : 'Pending';
            onChangeStatus(paper['id'], status, newStatus);
          }
        },
      ),
    );
  }
}
