import 'package:flutter/material.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final List<Map<String, dynamic>> readBooks = List.generate(
    12,
    (i) => {'title': 'Book ${i + 1}', 'author': 'Author Name'},
  );
  
  final List<Map<String, dynamic>> unreadBooks = List.generate(
    13,
    (i) => {'title': 'Book ${i + 13}', 'author': 'Author Name'},
  );

  void _addNewBook() {
    showDialog(
      context: context,
      builder: (context) {
        final titleController = TextEditingController();
        final authorController = TextEditingController();
        bool isRead = false;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Book'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Book Title'),
                  ),
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(labelText: 'Author'),
                  ),
                  SwitchListTile(
                    title: const Text('Mark as Read'),
                    value: isRead,
                    onChanged: (value) => setDialogState(() => isRead = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      setState(() {
                        final book = {
                          'title': titleController.text,
                          'author': authorController.text.isEmpty 
                              ? 'Unknown Author' 
                              : authorController.text,
                        };
                        if (isRead) {
                          readBooks.add(book);
                        } else {
                          unreadBooks.add(book);
                        }
                      });
                      Navigator.pop(context);
                    }
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

  void _moveToRead(int index) {
    setState(() {
      readBooks.add(unreadBooks[index]);
      unreadBooks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to Read'), duration: Duration(seconds: 1)),
    );
  }

  void _moveToUnread(int index) {
    setState(() {
      unreadBooks.add(readBooks[index]);
      readBooks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to Unread'), duration: Duration(seconds: 1)),
    );
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
            _BookList(books: readBooks, isRead: true, onMove: _moveToUnread),
            _BookList(books: unreadBooks, isRead: false, onMove: _moveToRead),
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

class _BookList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  final bool isRead;
  final Function(int) onMove;
  
  const _BookList({
    required this.books,
    required this.isRead,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
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
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Dismissible(
          key: Key('${book['title']}_$index'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onMove(index),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: isRead ? Colors.orange : Colors.green,
            child: Icon(
              isRead ? Icons.radio_button_unchecked : Icons.check_circle,
              color: Colors.white,
            ),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.menu_book,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(book['title']),
              subtitle: Text(book['author']),
              trailing: IconButton(
                icon: Icon(
                  isRead ? Icons.remove_circle : Icons.check_circle,
                  color: isRead ? Colors.orange : Colors.green,
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
