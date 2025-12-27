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
  int? _selectedGenreId;
  List<Map<String, dynamic>> _genres = [];

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final genres = await _db.getGenres();
    setState(() {
      _genres = genres;
    });
  }

  Future<void> _manageGenres() async {
    await showDialog(
      context: context,
      builder: (context) => _GenreManagementDialog(
        genres: _genres,
        onGenresChanged: () async {
          await _loadGenres();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _addNewBook() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final titleController = TextEditingController();
    final authorController = TextEditingController();
    String status = 'To Read';
    int? genreId;

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('Add New Book', style: TextStyle(color: Colors.white)),
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
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purpleAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: authorController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purpleAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: genreId,
                      dropdownColor: const Color(0xFF16213E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No Genre'),
                        ),
                        const DropdownMenuItem<int?>(
                          value: -1,
                          child: Text('+ Add New Genre'),
                        ),
                        ..._genres.map((g) => DropdownMenuItem<int?>(
                          value: g['id'],
                          child: Text(g['name']),
                        )),
                      ],
                      onChanged: (value) async {
                        if (value == -1) {
                          final controller = TextEditingController();
                          final newGenre = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A2E),
                              title: const Text('New Genre', style: TextStyle(color: Colors.white)),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Genre Name',
                                  labelStyle: TextStyle(color: Colors.white70),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, controller.text),
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                          if (newGenre != null && newGenre.isNotEmpty) {
                            final id = await _db.insertGenre({
                              'name': newGenre,
                              'createdAt': DateTime.now().toIso8601String(),
                            });
                            await _loadGenres();
                            setDialogState(() => genreId = id);
                          }
                        } else {
                          setDialogState(() => genreId = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      dropdownColor: const Color(0xFF16213E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: ['Read', 'To Read', 'Reading'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (value) => setDialogState(() => status = value!),
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
                      'isRead': status == 'Read' ? 1 : 0,
                      'genreId': genreId,
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

  Future<void> _editBook(Map<String, dynamic> book) async {
    final titleController = TextEditingController(text: book['title']);
    final authorController = TextEditingController(text: book['author']);
    String status = book['isRead'] == 1 ? 'Read' : 'To Read';
    int? genreId = book['genreId'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text('Edit Book', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Book Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Author',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purpleAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: genreId,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No Genre'),
                    ),
                    const DropdownMenuItem<int?>(
                      value: -1,
                      child: Text('+ Add New Genre'),
                    ),
                    ..._genres.map((g) => DropdownMenuItem<int?>(
                      value: g['id'],
                      child: Text(g['name']),
                    )),
                  ],
                  onChanged: (value) async {
                    if (value == -1) {
                      final controller = TextEditingController();
                      final newGenre = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1A2E),
                          title: const Text('New Genre', style: TextStyle(color: Colors.white)),
                          content: TextField(
                            controller: controller,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Genre Name',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, controller.text),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                      if (newGenre != null && newGenre.isNotEmpty) {
                        final id = await _db.insertGenre({
                          'name': newGenre,
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                        await _loadGenres();
                        setDialogState(() => genreId = id);
                      }
                    } else {
                      setDialogState(() => genreId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  items: ['Read', 'To Read', 'Reading'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (value) => setDialogState(() => status = value!),
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
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a book title')),
                  );
                  return;
                }

                await _db.updateBook(book['id'], {
                  'title': titleController.text,
                  'author': authorController.text.isEmpty ? 'Unknown Author' : authorController.text,
                  'imagePath': book['imagePath'],
                  'isRead': status == 'Read' ? 1 : 0,
                  'genreId': genreId,
                  'createdAt': book['createdAt'],
                });

                if (context.mounted) Navigator.pop(context, true);
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

  Future<void> _changeBookStatus(Map<String, dynamic> book, String newStatus) async {
    await _db.updateBook(book['id'], {
      ...book,
      'isRead': newStatus == 'Read' ? 1 : 0,
    });
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved to $newStatus'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _deleteBook(int id, String imagePath) async {
    await _db.deleteBook(id);
    // Delete image file
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0E17),
        appBar: AppBar(
          title: const Text('My Books'),
          backgroundColor: const Color(0xFF1A1A2E),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<int?>(
                    value: _selectedGenreId,
                    dropdownColor: const Color(0xFF16213E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Filter by Genre',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.filter_list, color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Genres'),
                      ),
                      ..._genres.map((g) => DropdownMenuItem<int?>(
                        value: g['id'],
                        child: Text(g['name']),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGenreId = value;
                      });
                    },
                  ),
                ),
                const TabBar(
                  indicatorColor: Colors.purpleAccent,
                  tabs: [
                    Tab(text: 'Read', icon: Icon(Icons.check_circle)),
                    Tab(text: 'To Read', icon: Icon(Icons.radio_button_unchecked)),
                    Tab(text: 'Reading', icon: Icon(Icons.menu_book)),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _BookGrid(
              status: 'Read',
              genreId: _selectedGenreId,
              onEdit: _editBook,
              onChangeStatus: _changeBookStatus,
              onDelete: _deleteBook,
            ),
            _BookGrid(
              status: 'To Read',
              genreId: _selectedGenreId,
              onEdit: _editBook,
              onChangeStatus: _changeBookStatus,
              onDelete: _deleteBook,
            ),
            _BookGrid(
              status: 'Reading',
              genreId: _selectedGenreId,
              onEdit: _editBook,
              onChangeStatus: _changeBookStatus,
              onDelete: _deleteBook,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNewBook,
          backgroundColor: Colors.purpleAccent,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final String status;
  final int? genreId;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>, String) onChangeStatus;
  final Function(int, String) onDelete;

  const _BookGrid({
    required this.status,
    this.genreId,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        DatabaseHelper.instance.getBooksByGenre(
          genreId,
          isRead: status == 'Read' ? true : (status == 'To Read' ? false : null),
        ),
        DatabaseHelper.instance.getGenres(),
      ]).then((results) => <String, dynamic>{'books': results[0], 'genres': results[1]}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text(
                  'No $status books',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a book cover',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data as Map;
        final allBooks = data['books'] as List<Map<String, dynamic>>;
        final genres = data['genres'] as List<Map<String, dynamic>>;

        // Filter books by status
        final books = allBooks.where((book) {
          if (status == 'Read') return book['isRead'] == 1;
          if (status == 'To Read') return book['isRead'] == 0;
          return book['isRead'] == 0;
        }).toList();

        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text(
                  'No $status books',
                  style: const TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          );
        }

        // Group books by genre
        final Map<String, List<Map<String, dynamic>>> groupedBooks = {};
        
        // Add unassigned books first (only if there are any)
        final unassignedBooks = books.where((b) => b['genreId'] == null).toList();
        if (unassignedBooks.isNotEmpty) {
          groupedBooks['Unassigned'] = unassignedBooks;
        }
        
        // Add books grouped by genre
        for (var genre in genres) {
          final genreBooks = books.where((b) => b['genreId'] == genre['id']).toList();
          if (genreBooks.isNotEmpty) {
            groupedBooks[genre['name']] = genreBooks;
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedBooks.length,
          itemBuilder: (context, index) {
            final genreName = groupedBooks.keys.elementAt(index);
            final genreBooks = groupedBooks[genreName]!;

            return Container(
              margin: EdgeInsets.only(bottom: index < groupedBooks.length - 1 ? 24 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder, color: Colors.purpleAccent, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          genreName,
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${genreBooks.length}',
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: genreBooks.length,
                      itemBuilder: (ctx, idx) {
                        final book = genreBooks[idx];
                        return _BookCard(
                          book: book,
                          currentStatus: status,
                          onEdit: onEdit,
                          onChangeStatus: onChangeStatus,
                          onDelete: onDelete,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final String currentStatus;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>, String) onChangeStatus;
  final Function(int, String) onDelete;

  const _BookCard({
    required this.book,
    required this.currentStatus,
    required this.onEdit,
    required this.onChangeStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      color: const Color(0xFF1A1A2E),
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
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFF16213E),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: TextStyle(color: Colors.white)),
                ),
                if (currentStatus != 'Read')
                  const PopupMenuItem(
                    value: 'read',
                    child: Text('Mark as Read', style: TextStyle(color: Colors.white)),
                  ),
                if (currentStatus != 'To Read')
                  const PopupMenuItem(
                    value: 'toread',
                    child: Text('Mark as To Read', style: TextStyle(color: Colors.white)),
                  ),
                if (currentStatus != 'Reading')
                  const PopupMenuItem(
                    value: 'reading',
                    child: Text('Mark as Reading', style: TextStyle(color: Colors.white)),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit(book);
                } else if (value == 'delete') {
                  onDelete(book['id'], book['imagePath']);
                } else if (value == 'read') {
                  onChangeStatus(book, 'Read');
                } else if (value == 'toread') {
                  onChangeStatus(book, 'To Read');
                } else if (value == 'reading') {
                  onChangeStatus(book, 'Reading');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreManagementDialog extends StatefulWidget {
  final List<Map<String, dynamic>> genres;
  final VoidCallback onGenresChanged;

  const _GenreManagementDialog({
    required this.genres,
    required this.onGenresChanged,
  });

  @override
  State<_GenreManagementDialog> createState() => _GenreManagementDialogState();
}

class _GenreManagementDialogState extends State<_GenreManagementDialog> {
  final _db = DatabaseHelper.instance;

  Future<void> _addGenre() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Add Genre', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Genre Name',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _db.insertGenre({
                  'name': controller.text,
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (context.mounted) Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onGenresChanged();
    }
  }

  Future<void> _deleteGenre(int id) async {
    await _db.deleteGenre(id);
    widget.onGenresChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('Manage Genres', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.genres.length,
          itemBuilder: (context, index) {
            final genre = widget.genres[index];
            return ListTile(
              title: Text(genre['name'], style: const TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteGenre(genre['id']),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _addGenre,
          child: const Text('Add Genre'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
