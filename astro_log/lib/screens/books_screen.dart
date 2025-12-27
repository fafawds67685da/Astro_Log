import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/database_helper.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _addNewBook() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final titleController = TextEditingController();
    final authorController = TextEditingController();
    bool isRead = false;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Book'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        height: 150,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Mark as Read'),
                      value: isRead,
                      onChanged: (value) => setDialogState(() => isRead = value),
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
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a book title')),
                      );
                      return;
                    }

                    final savedPath = await _db.saveImage(File(image.path));
                    await _db.insertBook({
                      'title': titleController.text,
                      'author': authorController.text.isEmpty ? 'Unknown Author' : authorController.text,
                      'imagePath': savedPath,
                      'isRead': isRead ? 1 : 0,
                      'createdAt': DateTime.now().toIso8601String(),
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                    setState(() {});
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

  Future<void> _toggleReadStatus(Map<String, dynamic> book) async {
    await _db.updateBook(book['id'], {
      ...book,
      'isRead': book['isRead'] == 1 ? 0 : 1,
    });
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(book['isRead'] == 1 ? 'Moved to Unread' : 'Moved to Read'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteBook(int id) async {
    await _db.deleteBook(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Books'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Read', icon: Icon(Icons.check_circle)),
              Tab(text: 'Unread', icon: Icon(Icons.radio_button_unchecked)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookGrid(isRead: true, onToggle: _toggleReadStatus, onDelete: _deleteBook),
            _BookGrid(isRead: false, onToggle: _toggleReadStatus, onDelete: _deleteBook),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewBook,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final bool isRead;
  final Function(Map<String, dynamic>) onToggle;
  final Function(int) onDelete;

  const _BookGrid({
    required this.isRead,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getBooks(isRead: isRead),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No ${isRead ? 'read' : 'unread'} books yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a book cover',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final books = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return _BookCard(
              book: book,
              onToggle: () => onToggle(book),
              onDelete: () => onDelete(book['id']),
            );
          },
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BookCard({
    required this.book,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Book?'),
              content: Text('Remove "${book['title']}" from your library?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(book['imagePath']),
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book['author'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.6),
                radius: 18,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    book['isRead'] == 1 ? Icons.remove_circle : Icons.check_circle,
                    color: book['isRead'] == 1 ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                  onPressed: onToggle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
