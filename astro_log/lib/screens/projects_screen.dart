import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> with SingleTickerProviderStateMixin {
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

  Future<void> _addNewProject() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String status = 'Pending';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Add New Project', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Project Title',
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
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
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
                  await _dbHelper.insertProject({
                    'title': titleController.text,
                    'description': descriptionController.text,
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

  Future<void> _editProject(Map<String, dynamic> project) async {
    final titleController = TextEditingController(text: project['title']);
    final descriptionController = TextEditingController(text: project['description']);
    String status = project['status'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Edit Project', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Project Title',
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
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
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
                  await _dbHelper.updateProject(project['id'], {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'status': status,
                    'createdAt': project['createdAt'],
                  });
                  if (context.mounted) Navigator.pop(context, true);
                }
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

  Future<void> _deleteProject(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Project?', style: TextStyle(color: Colors.white)),
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
      await _dbHelper.deleteProject(id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Projects'),
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
          _ProjectsList(status: 'Done', onEdit: _editProject, onDelete: _deleteProject),
          _ProjectsList(status: 'Pending', onEdit: _editProject, onDelete: _deleteProject),
          _ProjectsList(status: 'Underway', onEdit: _editProject, onDelete: _deleteProject),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProject,
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectsList extends StatelessWidget {
  final String status;
  final Function(Map<String, dynamic>) onEdit;
  final Function(int) onDelete;

  const _ProjectsList({
    required this.status,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getProjects(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text(
                  'No $status Projects',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a new project',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final projects = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return Card(
              color: const Color(0xFF1A1A2E),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  project['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: project['description'] != null && project['description'].isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          project['description'],
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => onEdit(project),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => onDelete(project['id']),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
