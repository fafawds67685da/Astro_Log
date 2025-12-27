import 'package:flutter/material.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({Key? key}) : super(key: key);

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
            _BookList(isRead: true),
            _BookList(isRead: false),
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

class _BookList extends StatelessWidget {
  final bool isRead;
  
  const _BookList({required this.isRead});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: isRead ? 12 : 13,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.menu_book,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text('Book ${index + 1}'),
            subtitle: Text('Author Name'),
            trailing: Icon(
              isRead ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isRead ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
