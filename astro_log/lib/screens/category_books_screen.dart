import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/database_helper.dart';
import '../services/image_service.dart';
import '../models/enums.dart';
import 'dart:io';

class CategoryBooksScreen extends StatefulWidget {
  final String categoryType; // 'genre', 'series', 'author', 'standalone'
  final int? categoryId;
  final String categoryName;
  final Set<ReadingStatus> statusFilters;

  const CategoryBooksScreen({
    Key? key,
    required this.categoryType,
    this.categoryId,
    required this.categoryName,
    required this.statusFilters,
  }) : super(key: key);

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImageService _imageService = ImageService.instance;

  Future<List<Map<String, dynamic>>> _getCategoryBooks() async {
    List<Map<String, dynamic>> books = [];
    
    switch (widget.categoryType) {
      case 'genre':
        if (widget.statusFilters.contains(ReadingStatus.all)) {
          books = await _db.getBooksByGenreNew(widget.categoryId!);
        } else {
          if (widget.statusFilters.contains(ReadingStatus.read)) {
            books.addAll(await _db.getBooksByGenreNew(widget.categoryId!, readingStatus: 'read'));
          }
          if (widget.statusFilters.contains(ReadingStatus.reading)) {
            books.addAll(await _db.getBooksByGenreNew(widget.categoryId!, readingStatus: 'reading'));
          }
          if (widget.statusFilters.contains(ReadingStatus.notRead)) {
            books.addAll(await _db.getBooksByGenreNew(widget.categoryId!, readingStatus: 'not_read'));
          }
        }
        break;
        
      case 'series':
        if (widget.statusFilters.contains(ReadingStatus.all)) {
          books = await _db.getBooksBySeries(widget.categoryId!);
        } else {
          if (widget.statusFilters.contains(ReadingStatus.read)) {
            books.addAll(await _db.getBooksBySeries(widget.categoryId!, readingStatus: 'read'));
          }
          if (widget.statusFilters.contains(ReadingStatus.reading)) {
            books.addAll(await _db.getBooksBySeries(widget.categoryId!, readingStatus: 'reading'));
          }
          if (widget.statusFilters.contains(ReadingStatus.notRead)) {
            books.addAll(await _db.getBooksBySeries(widget.categoryId!, readingStatus: 'not_read'));
          }
        }
        // Sort by series number
        books.sort((a, b) => (a['seriesNumber'] ?? 999).compareTo(b['seriesNumber'] ?? 999));
        break;
        
      case 'standalone':
        List<Map<String, dynamic>> allBooks = [];
        if (widget.statusFilters.contains(ReadingStatus.all)) {
          allBooks = await _db.getAllBooks();
        } else {
          if (widget.statusFilters.contains(ReadingStatus.read)) {
            allBooks.addAll(await _db.getAllBooks(readingStatus: 'read'));
          }
          if (widget.statusFilters.contains(ReadingStatus.reading)) {
            allBooks.addAll(await _db.getAllBooks(readingStatus: 'reading'));
          }
          if (widget.statusFilters.contains(ReadingStatus.notRead)) {
            allBooks.addAll(await _db.getAllBooks(readingStatus: 'not_read'));
          }
        }
        books = allBooks.where((book) => book['seriesId'] == null).toList();
        break;
        
      case 'author':
        List<Map<String, dynamic>> allBooks = [];
        if (widget.statusFilters.contains(ReadingStatus.all)) {
          allBooks = await _db.getAllBooks();
        } else {
          if (widget.statusFilters.contains(ReadingStatus.read)) {
            allBooks.addAll(await _db.getAllBooks(readingStatus: 'read'));
          }
          if (widget.statusFilters.contains(ReadingStatus.reading)) {
            allBooks.addAll(await _db.getAllBooks(readingStatus: 'reading'));
          }
          if (widget.statusFilters.contains(ReadingStatus.notRead)) {
            allBooks.addAll(await _db.getAllBooks(readingStatus: 'not_read'));
          }
        }
        books = allBooks.where((book) => (book['author'] ?? 'Unknown') == widget.categoryName).toList();
        break;
    }
    
    return books;
  }

  @override
  Widget build(BuildContext context) {
    IconData categoryIcon;
    Color categoryColor;
    
    switch (widget.categoryType) {
      case 'genre':
        categoryIcon = Icons.folder;
        categoryColor = Colors.purpleAccent;
        break;
      case 'series':
        categoryIcon = Icons.collections_bookmark;
        categoryColor = Colors.cyanAccent;
        break;
      case 'standalone':
        categoryIcon = Icons.book;
        categoryColor = Colors.orangeAccent;
        break;
      case 'author':
        categoryIcon = Icons.person;
        categoryColor = Colors.tealAccent;
        break;
      default:
        categoryIcon = Icons.folder;
        categoryColor = Colors.purpleAccent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(categoryIcon, color: categoryColor),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.categoryName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getCategoryBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: categoryColor));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(categoryIcon, size: 80, color: categoryColor.withOpacity(0.3)),
                  SizedBox(height: 16),
                  Text(
                    'No books found',
                    style: TextStyle(color: Colors.white70, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            );
          }
          
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final book = snapshot.data![index];
              return _buildBookCard(book, categoryColor, cardIndex: index + 1);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book, Color accentColor, {int? cardIndex}) {
    final hasImage = book['imagePath'] != null && book['imagePath'].toString().isNotEmpty;
    final imagePath = book['imagePath'];
    final readingStatus = book['readingStatus'] ?? 'not_read';
    final seriesNumber = book['seriesNumber'];
    
    Color statusColor;
    IconData statusIcon;
    switch (readingStatus) {
      case 'read':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle;
        break;
      case 'reading':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.auto_stories;
        break;
      default:
        statusColor = Colors.blueAccent;
        statusIcon = Icons.circle_outlined;
    }

    return GestureDetector(
      onTap: () => _showBookDetails(book),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2A2A3E).withOpacity(0.9),
              Color(0xFF1A1A2E).withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    else
                      _buildPlaceholder(),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, size: 16, color: Colors.white),
                      ),
                    ),
                    // Series number badge
                    if (seriesNumber != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$seriesNumber',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Card index badge
                    if (cardIndex != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '#$cardIndex',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'] ?? 'Untitled',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        book['author'] ?? 'Unknown Author',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      if (book['totalPages'] != null && book['totalPages'] > 0) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Page ${book['currentPage'] ?? 0} / ${book['totalPages']}',
                                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${((book['currentPage'] ?? 0) / book['totalPages'] * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: (book['currentPage'] ?? 0) / book['totalPages'],
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Color(0xFF1A1A2E),
      child: Icon(Icons.menu_book, size: 64, color: Colors.white24),
    );
  }

  void _showBookDetails(Map<String, dynamic> book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] ?? 'Untitled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'by ${book['author'] ?? 'Unknown'}',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem(
                          Icons.book,
                          'Pages',
                          '${book['currentPage'] ?? 0}/${book['totalPages'] ?? 0}',
                        ),
                        _buildDetailItem(
                          Icons.auto_stories,
                          'Status',
                          _getStatusText(book['readingStatus']),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editBook(book);
                            },
                            icon: Icon(Icons.edit),
                            label: Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteBook(book);
                            },
                            icon: Icon(Icons.delete),
                            label: Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.purpleAccent, size: 32),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 12)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'read':
        return 'Read';
      case 'reading':
        return 'Reading';
      case 'not_read':
        return 'Not Read';
      default:
        return 'Unknown';
    }
  }

  Future<void> _editBook(Map<String, dynamic> book) async {
    // Navigate back to main screen and trigger edit there
    Navigator.pop(context);
    // You'll need to handle this via a callback or state management
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please edit from the main books screen'),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  Future<void> _deleteBook(Map<String, dynamic> book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text('Delete Book', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${book['title']}"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _db.deleteBook(book['id']);
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book deleted'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
