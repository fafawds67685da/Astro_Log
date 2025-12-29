import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class BooksToBuyScreen extends StatefulWidget {
  const BooksToBuyScreen({Key? key}) : super(key: key);

  @override
  State<BooksToBuyScreen> createState() => _BooksToBuyScreenState();
}

class _BooksToBuyScreenState extends State<BooksToBuyScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Books to Buy'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addWishlistBook,
            tooltip: 'Add Book to Buy',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getWishlistBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white30),
                  SizedBox(height: 16),
                  Text(
                    'No books in wishlist',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addWishlistBook,
                    icon: Icon(Icons.add),
                    label: Text('Add Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          final books = snapshot.data!;
          
          // Calculate total cost
          double totalCost = 0;
          for (var book in books) {
            if (book['price'] != null) {
              totalCost += (book['price'] as num).toDouble();
            }
          }
          
          final formatter = NumberFormat('#,##,###');

          return Column(
            children: [
              // Total Cost Header
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFFB300).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.currency_rupee, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Cost',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '₹${formatter.format(totalCost.toInt())}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${books.length} ${books.length == 1 ? 'Book' : 'Books'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isPinned = book['isPinned'] == 1;
              
              return Card(
                color: const Color(0xFF1A1A2E),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPinned ? Colors.amber : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => _editWishlistBook(book),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Book Image
                        Container(
                          width: 80,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade800,
                          ),
                          child: book['imagePath'] != null && File(book['imagePath']).existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(book['imagePath']),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.book, size: 40, color: Colors.white54),
                        ),
                        SizedBox(width: 16),
                        // Book Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isPinned)
                                Row(
                                  children: [
                                    Icon(Icons.push_pin, size: 16, color: Colors.amber),
                                    SizedBox(width: 4),
                                    Text(
                                      'PINNED',
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              if (isPinned) SizedBox(height: 4),
                              Text(
                                book['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (book['author'] != null && book['author'].isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(
                                  'by ${book['author']}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              if (book['price'] != null) ...[
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.green, width: 1),
                                  ),
                                  child: Text(
                                    '₹${NumberFormat('#,##,###').format((book['price'] as num).toInt())}',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Actions
                        Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: isPinned ? Colors.amber : Colors.white54,
                              ),
                              onPressed: () => _togglePin(book),
                              tooltip: isPinned ? 'Unpin' : 'Pin',
                            ),
                            if (book['link'] != null && book['link'].isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.open_in_new, color: Colors.cyanAccent),
                                onPressed: () => _openLink(book['link']),
                                tooltip: 'Open Link',
                              ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteWishlistBook(book),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addWishlistBook() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditWishlistBookScreen(),
      ),
    );
    setState(() {});
  }

  Future<void> _editWishlistBook(Map<String, dynamic> book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditWishlistBookScreen(book: book),
      ),
    );
    setState(() {});
  }

  Future<void> _togglePin(Map<String, dynamic> book) async {
    final isPinned = book['isPinned'] == 1;
    
    try {
      await _db.toggleWishlistBookPin(book['id'], !isPinned);
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPinned ? 'Book unpinned' : 'Book pinned'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteWishlistBook(Map<String, dynamic> book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Book', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${book['title']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteWishlistBook(book['id']);
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book deleted'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Add/Edit Wishlist Book Screen
class AddEditWishlistBookScreen extends StatefulWidget {
  final Map<String, dynamic>? book;

  const AddEditWishlistBookScreen({Key? key, this.book}) : super(key: key);

  @override
  State<AddEditWishlistBookScreen> createState() => _AddEditWishlistBookScreenState();
}

class _AddEditWishlistBookScreenState extends State<AddEditWishlistBookScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImagePicker _picker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _linkController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!['title'] ?? '';
      _authorController.text = widget.book!['author'] ?? '';
      _linkController.text = widget.book!['link'] ?? '';
      _priceController.text = widget.book!['price']?.toString() ?? '';
      _imagePath = widget.book!['imagePath'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _linkController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.book != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Book' : 'Add Book to Buy'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Book Image
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade800,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: _imagePath != null && File(_imagePath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.white54),
                            SizedBox(height: 8),
                            Text(
                              'Add Cover',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Title
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title *',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Author
            TextFormField(
              controller: _authorController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Author',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Link
            TextFormField(
              controller: _linkController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Link (URL)',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.link, color: Colors.cyanAccent),
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 16),
            
            // Price
            TextFormField(
              controller: _priceController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Price',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: Colors.greenAccent),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isEditing ? 'Update Book' : 'Add Book',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Copy to permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'wishlist_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bookData = {
      'title': _titleController.text.trim(),
      'author': _authorController.text.trim(),
      'imagePath': _imagePath,
      'link': _linkController.text.trim(),
      'price': _priceController.text.isNotEmpty 
          ? double.tryParse(_priceController.text.trim()) 
          : null,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      if (widget.book != null) {
        // Update existing book
        await _db.updateWishlistBook(widget.book!['id'], bookData);
      } else {
        // Create new book
        bookData['isPinned'] = 0;
        await _db.createWishlistBook(bookData);
      }

      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.book != null ? 'Book updated' : 'Book added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
