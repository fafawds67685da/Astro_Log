import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';
import '../services/database_helper.dart';
import '../services/image_service.dart';
import '../models/enums.dart';
import 'genre_series_manager_screen.dart';
import 'category_books_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImageService _imageService = ImageService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  ViewMode _viewMode = ViewMode.all;
  Set<ReadingStatus> _statusFilters = {ReadingStatus.all};
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0E17),
      appBar: AppBar(
        title: const Text('Book Library'),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewBook,
            tooltip: 'Add Book',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _manageGenresAndSeries,
            tooltip: 'Manage Genres & Series',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildStatusFilters(),
          _buildSearchBar(),
          Expanded(child: _buildContentByMode()),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: _getSearchHint(),
          hintStyle: TextStyle(color: Colors.white38),
          prefixIcon: Icon(Icons.search, color: Colors.purpleAccent),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Color(0xFF1A1A2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purpleAccent.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purpleAccent),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }
  
  String _getSearchHint() {
    switch (_viewMode) {
      case ViewMode.all:
        return 'Search books by title or author...';
      case ViewMode.genres:
        return 'Search genres...';
      case ViewMode.series:
        return 'Search series...';
      case ViewMode.authors:
        return 'Search authors...';
    }
  }
  
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.menu_book, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'View Options',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.list, color: _viewMode == ViewMode.all ? Colors.purpleAccent : Colors.white70),
            title: Text('All Books', style: TextStyle(color: Colors.white)),
            selected: _viewMode == ViewMode.all,
            selectedTileColor: Colors.purpleAccent.withOpacity(0.1),
            onTap: () {
              setState(() => _viewMode = ViewMode.all);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.folder, color: _viewMode == ViewMode.genres ? Colors.purpleAccent : Colors.white70),
            title: Text('By Genres', style: TextStyle(color: Colors.white)),
            selected: _viewMode == ViewMode.genres,
            selectedTileColor: Colors.purpleAccent.withOpacity(0.1),
            onTap: () {
              setState(() => _viewMode = ViewMode.genres);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.collections_bookmark, color: _viewMode == ViewMode.series ? Colors.purpleAccent : Colors.white70),
            title: Text('By Series', style: TextStyle(color: Colors.white)),
            selected: _viewMode == ViewMode.series,
            selectedTileColor: Colors.purpleAccent.withOpacity(0.1),
            onTap: () {
              setState(() => _viewMode = ViewMode.series);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: _viewMode == ViewMode.authors ? Colors.purpleAccent : Colors.white70),
            title: Text('By Authors', style: TextStyle(color: Colors.white)),
            selected: _viewMode == ViewMode.authors,
            selectedTileColor: Colors.purpleAccent.withOpacity(0.1),
            onTap: () {
              setState(() => _viewMode = ViewMode.authors);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: Text('All'),
            selected: _statusFilters.contains(ReadingStatus.all),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _statusFilters = {ReadingStatus.all};
                } else if (_statusFilters.length > 1) {
                  _statusFilters.remove(ReadingStatus.all);
                }
              });
            },
            backgroundColor: Color(0xFF1A1A2E),
            selectedColor: Colors.purpleAccent,
            labelStyle: TextStyle(color: Colors.white),
          ),
          FilterChip(
            label: Text('Read ✓'),
            selected: _statusFilters.contains(ReadingStatus.read),
            onSelected: (selected) {
              setState(() {
                _statusFilters.remove(ReadingStatus.all);
                if (selected) {
                  _statusFilters.add(ReadingStatus.read);
                } else {
                  _statusFilters.remove(ReadingStatus.read);
                }
                if (_statusFilters.isEmpty) _statusFilters = {ReadingStatus.all};
              });
            },
            backgroundColor: Color(0xFF1A1A2E),
            selectedColor: Colors.greenAccent,
            labelStyle: TextStyle(color: Colors.white),
          ),
          FilterChip(
            label: Text('Reading 📖'),
            selected: _statusFilters.contains(ReadingStatus.reading),
            onSelected: (selected) {
              setState(() {
                _statusFilters.remove(ReadingStatus.all);
                if (selected) {
                  _statusFilters.add(ReadingStatus.reading);
                } else {
                  _statusFilters.remove(ReadingStatus.reading);
                }
                if (_statusFilters.isEmpty) _statusFilters = {ReadingStatus.all};
              });
            },
            backgroundColor: Color(0xFF1A1A2E),
            selectedColor: Colors.orangeAccent,
            labelStyle: TextStyle(color: Colors.white),
          ),
          FilterChip(
            label: Text('Not Read ○'),
            selected: _statusFilters.contains(ReadingStatus.notRead),
            onSelected: (selected) {
              setState(() {
                _statusFilters.remove(ReadingStatus.all);
                if (selected) {
                  _statusFilters.add(ReadingStatus.notRead);
                } else {
                  _statusFilters.remove(ReadingStatus.notRead);
                }
                if (_statusFilters.isEmpty) _statusFilters = {ReadingStatus.all};
              });
            },
            backgroundColor: Color(0xFF1A1A2E),
            selectedColor: Colors.blueAccent,
            labelStyle: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentByMode() {
    switch (_viewMode) {
      case ViewMode.all:
        return _buildAllBooksView();
      case ViewMode.genres:
        return _buildGenresView();
      case ViewMode.series:
        return _buildSeriesView();
      case ViewMode.authors:
        return _buildAuthorsView();
    }
  }
  
  Widget _buildAllBooksView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No books found', 'Add your first book to get started');
        }
        
        // Filter by search query
        final filteredBooks = snapshot.data!.where((book) {
          if (_searchQuery.isEmpty) return true;
          final title = (book['title'] ?? '').toString().toLowerCase();
          final author = (book['author'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery) || author.contains(_searchQuery);
        }).toList();
        
        if (filteredBooks.isEmpty) {
          return _buildEmptyState('No books match your search', 'Try a different search term');
        }
        
        return Column(
          children: [
            // Count header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.book, color: Colors.purpleAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '${filteredBooks.length} ${filteredBooks.length == 1 ? 'Book' : 'Books'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
                  return _buildBookCard(book, cardIndex: index + 1);
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildGenresView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getGenres(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No genres', 'Create genres in settings');
        }
        
        // Filter by search query
        final filteredGenres = snapshot.data!.where((genre) {
          if (_searchQuery.isEmpty) return true;
          final name = (genre['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();
        
        if (filteredGenres.isEmpty) {
          return _buildEmptyState('No genres match your search', 'Try a different search term');
        }
        
        return Column(
          children: [
            // Count header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.purpleAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '${filteredGenres.length} ${filteredGenres.length == 1 ? 'Genre' : 'Genres'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredGenres.length,
                itemBuilder: (context, index) {
                  final genre = filteredGenres[index];
                  final genreName = genre['name'] as String? ?? 'Unnamed Genre';
                  final genreId = genre['id'] as int?;
                  return _buildCategoryCard(
                    name: genreName,
                    icon: Icons.folder,
                    color: Colors.purpleAccent,
                    onTap: () => _navigateToCategoryBooks('genre', genreId, genreName),
                    genreId: genreId,
                    categoryType: 'genre',
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSeriesView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.getBookSeries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No series', 'Create book series in settings');
        }
        
        final allItems = [...snapshot.data!, {'id': null, 'name': 'Standalone Books', 'isStandalone': true}];
        
        // Filter by search query
        final filteredItems = allItems.where((series) {
          if (_searchQuery.isEmpty) return true;
          final name = (series['name'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery);
        }).toList();
        
        if (filteredItems.isEmpty) {
          return _buildEmptyState('No series match your search', 'Try a different search term');
        }
        
        return Column(
          children: [
            // Count header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.collections_bookmark, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '${filteredItems.length} ${filteredItems.length == 1 ? 'Series' : 'Series'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final series = filteredItems[index];
                  final isStandalone = series['isStandalone'] == true;
                  final seriesName = series['name'] as String? ?? 'Unnamed Series';
                  final seriesId = series['id'] as int?;
                  return _buildCategoryCard(
                    name: seriesName,
                    icon: isStandalone ? Icons.book : Icons.collections_bookmark,
                    color: isStandalone ? Colors.orangeAccent : Colors.cyanAccent,
                    onTap: () => _navigateToCategoryBooks(
                      isStandalone ? 'standalone' : 'series',
                      seriesId,
                      seriesName,
                    ),
                    seriesId: isStandalone ? null : seriesId,
                    categoryType: isStandalone ? null : 'series',
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildAuthorsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFilteredBooks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No books', 'Add books to see authors');
        }
        
        // Group books by author
        Map<String, List<Map<String, dynamic>>> booksByAuthor = {};
        for (var book in snapshot.data!) {
          String author = book['author'] ?? 'Unknown';
          if (!booksByAuthor.containsKey(author)) {
            booksByAuthor[author] = [];
          }
          booksByAuthor[author]!.add(book);
        }
        
        final authors = booksByAuthor.keys.toList()..sort();
        
        // Filter by search query
        final filteredAuthors = authors.where((author) {
          if (_searchQuery.isEmpty) return true;
          return author.toLowerCase().contains(_searchQuery);
        }).toList();
        
        if (filteredAuthors.isEmpty) {
          return _buildEmptyState('No authors match your search', 'Try a different search term');
        }
        
        return Column(
          children: [
            // Count header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.tealAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '${filteredAuthors.length} ${filteredAuthors.length == 1 ? 'Author' : 'Authors'}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredAuthors.length,
                itemBuilder: (context, index) {
                  final author = filteredAuthors[index];
                  return _buildCategoryCard(
                    name: author,
                    icon: Icons.person,
                    color: Colors.tealAccent,
                    onTap: () => _navigateToCategoryBooks('author', null, author),
                    bookCount: booksByAuthor[author]!.length,
                    categoryType: 'author',
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildCategoryCard({
    required String name,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int? genreId,
    int? seriesId,
    int? bookCount,
    String? categoryType,
  }) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCategoryCardData(categoryType, seriesId, name, genreId, bookCount),
      builder: (context, snapshot) {
        final count = snapshot.data?['count'] ?? 0;
        final coverImage = snapshot.data?['coverImage'] as String?;
        final showMenu = (categoryType == 'series' && seriesId != null) || 
                        categoryType == 'author' || 
                        (categoryType == 'genre' && genreId != null);
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: coverImage == null || !File(coverImage).existsSync()
                  ? LinearGradient(
                      colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
              image: coverImage != null && File(coverImage).existsSync()
                  ? DecorationImage(
                      image: FileImage(File(coverImage)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Gradient overlay for text readability (only when image exists)
                  if (coverImage != null && File(coverImage).existsSync())
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.3, 1.0],
                        ),
                      ),
                    ),
                  // Content
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (coverImage == null || !File(coverImage).existsSync())
                          ...[
                            Icon(icon, size: 48, color: color),
                            SizedBox(height: 8),
                          ],
                        // Text container with glassmorphism
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.8),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count ${count == 1 ? 'book' : 'books'}',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu button
                  if (showMenu)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.white, size: 20),
                          color: Color(0xFF1A1A2E),
                          onSelected: (value) {
                            if (value == 'edit') {
                              if (categoryType == 'genre') {
                                _editCategory('genre', genreId, name);
                              } else if (categoryType == 'series') {
                                _editCategory('series', seriesId, name);
                              } else if (categoryType == 'author') {
                                _editCategory('author', null, name);
                              }
                            } else if (value == 'delete') {
                              if (categoryType == 'genre') {
                                _deleteCategory('genre', genreId, name);
                              } else if (categoryType == 'series') {
                                _deleteCategory('series', seriesId, name);
                              } else if (categoryType == 'author') {
                                _deleteCategory('author', null, name);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.cyanAccent, size: 20),
                                  SizedBox(width: 12),
                                  Text('Edit', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                  SizedBox(width: 12),
                                  Text('Delete', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Future<Map<String, dynamic>> _getCategoryCardData(
    String? categoryType,
    int? seriesId,
    String name,
    int? genreId,
    int? bookCount,
  ) async {
    int count = 0;
    String? coverImage;
    
    // Get book count
    if (bookCount != null) {
      count = bookCount;
    } else if (genreId != null) {
      count = (await _getBooksByGenreFiltered(genreId)).length;
    } else if (seriesId != null) {
      count = (await _getBooksBySeriesFiltered(seriesId)).length;
    } else {
      count = (await _getStandaloneBooks()).length;
    }
    
    // Get cover image
    if (categoryType == 'series' && seriesId != null) {
      final allSeries = await _db.getBookSeries();
      final series = allSeries.firstWhere(
        (s) => s['id'] == seriesId,
        orElse: () => <String, dynamic>{},
      );
      coverImage = series['coverImagePath'] as String?;
    } else if (categoryType == 'author') {
      final authors = await _db.getAuthors();
      final author = authors.firstWhere(
        (a) => a['name'] == name,
        orElse: () => <String, dynamic>{},
      );
      coverImage = author['coverImagePath'] as String?;
    } else if (categoryType == 'genre' && genreId != null) {
      final allGenres = await _db.getGenres();
      final genre = allGenres.firstWhere(
        (g) => g['id'] == genreId,
        orElse: () => <String, dynamic>{},
      );
      coverImage = genre['coverImagePath'] as String?;
    }
    
    return {'count': count, 'coverImage': coverImage};
  }
  
  void _navigateToCategoryBooks(String type, int? id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryBooksScreen(
          categoryType: type,
          categoryId: id,
          categoryName: name,
          statusFilters: _statusFilters,
        ),
      ),
    ).then((_) => setState(() {}));
  }
  
  Widget _buildGenreFolder(Map<String, dynamic> genre) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getBooksByGenreFiltered(genre['id']),
      builder: (context, snapshot) {
        final bookCount = snapshot.data?.length ?? 0;
        if (bookCount == 0 && !_statusFilters.contains(ReadingStatus.all)) {
          return SizedBox.shrink();
        }
        
        return ExpansionTile(
          leading: Icon(Icons.folder, color: Colors.purpleAccent, size: 32),
          title: Text(
            genre['name'],
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$bookCount books',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          backgroundColor: Color(0xFF1A1A2E),
          collapsedBackgroundColor: Color(0xFF1A1A2E),
          children: snapshot.data?.asMap().entries.map((entry) => 
            _buildBookCard(entry.value, cardIndex: entry.key + 1)
          ).toList() ?? [],
        );
      },
    );
  }
  
  Widget _buildSeriesFolder(Map<String, dynamic> series) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getBooksBySeriesFiltered(series['id']),
      builder: (context, snapshot) {
        final bookCount = snapshot.data?.length ?? 0;
        if (bookCount == 0 && !_statusFilters.contains(ReadingStatus.all)) {
          return SizedBox.shrink();
        }
        
        return ExpansionTile(
          leading: Icon(Icons.collections_bookmark, color: Colors.cyanAccent, size: 32),
          title: Text(
            series['name'],
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$bookCount books',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          backgroundColor: Color(0xFF1A1A2E),
          collapsedBackgroundColor: Color(0xFF1A1A2E),
          children: snapshot.data?.asMap().entries.map((entry) => 
            _buildBookCard(entry.value, showSeriesNumber: true, cardIndex: entry.key + 1)
          ).toList() ?? [],
        );
      },
    );
  }
  
  Widget _buildStandaloneBooksFolder() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getStandaloneBooks(),
      builder: (context, snapshot) {
        final bookCount = snapshot.data?.length ?? 0;
        if (bookCount == 0) return SizedBox.shrink();
        
        return ExpansionTile(
          leading: Icon(Icons.book, color: Colors.orangeAccent, size: 32),
          title: Text(
            'Standalone Books',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$bookCount books',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          backgroundColor: Color(0xFF1A1A2E),
          collapsedBackgroundColor: Color(0xFF1A1A2E),
          children: snapshot.data?.asMap().entries.map((entry) => 
            _buildBookCard(entry.value, cardIndex: entry.key + 1)
          ).toList() ?? [],
        );
      },
    );
  }
  
  Widget _buildBookCard(Map<String, dynamic> book, {bool showSeriesNumber = false, int? cardIndex}) {
    final readingStatus = book['readingStatus'] ?? 'not_read';
    IconData statusIcon;
    Color statusColor;
    
    switch (readingStatus) {
      case 'read':
        statusIcon = Icons.check_circle;
        statusColor = Colors.greenAccent;
        break;
      case 'reading':
        statusIcon = Icons.menu_book;
        statusColor = Colors.orangeAccent;
        break;
      default:
        statusIcon = Icons.circle_outlined;
        statusColor = Colors.blueAccent;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2A2A3E).withOpacity(0.8),
            Color(0xFF1A1A2E).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(book['imagePath']),
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey,
                      child: Icon(Icons.book, color: Colors.white),
                    ),
                  ),
                ),
                if (cardIndex != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9D50BB), Color(0xFF6E48AA)],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '#$cardIndex',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        title: Row(
          children: [
            if (showSeriesNumber && book['seriesNumber'] != null)
              Container(
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '#${book['seriesNumber']}',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            Expanded(
              child: Text(
                book['title'],
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(statusIcon, color: statusColor, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book['author'] != null)
              Text(
                book['author'],
                style: TextStyle(color: Colors.white70),
              ),
            SizedBox(height: 4),
            // Progress bar and page info
            if (book['totalPages'] != null && book['totalPages'] > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: (book['readingStatus'] == 'read')
                        ? Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.greenAccent, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Completed!',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Page ${book['currentPage'] ?? 0} of ${book['totalPages']}',
                                    style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${((book['currentPage'] ?? 0) / book['totalPages'] * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (book['currentPage'] ?? 0) / book['totalPages'],
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _db.getBookGenres(book['id']),
              builder: (context, genreSnapshot) {
                if (!genreSnapshot.hasData || genreSnapshot.data!.isEmpty) {
                  return SizedBox.shrink();
                }
                return Wrap(
                  spacing: 4,
                  children: genreSnapshot.data!.take(3).map((genre) => 
                    Chip(
                      label: Text(
                        genre['name'],
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      backgroundColor: Colors.purpleAccent.withOpacity(0.3),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ).toList(),
                );
              },
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white70),
          color: Color(0xFF16213E),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text('View', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.cyanAccent),
                  SizedBox(width: 8),
                  Text('Download Image', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'view':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: book),
                  ),
                );
                break;
              case 'download':
                await _downloadBookImage(book);
                break;
              case 'edit':
                await _editBook(book);
                break;
              case 'delete':
                await _deleteBook(book);
                break;
            }
          },
        ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: Colors.purpleAccent.withOpacity(0.3)),
          SizedBox(height: 16),
          Text(title, style: TextStyle(color: Colors.white70, fontSize: 24)),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
  
  Future<List<Map<String, dynamic>>> _getFilteredBooks() async {
    if (_statusFilters.contains(ReadingStatus.all)) {
      return await _db.getAllBooks();
    }
    
    List<Map<String, dynamic>> allBooks = [];
    if (_statusFilters.contains(ReadingStatus.read)) {
      final books = await _db.getAllBooks(readingStatus: 'read');
      allBooks.addAll(books);
    }
    if (_statusFilters.contains(ReadingStatus.reading)) {
      final books = await _db.getAllBooks(readingStatus: 'reading');
      allBooks.addAll(books);
    }
    if (_statusFilters.contains(ReadingStatus.notRead)) {
      final books = await _db.getAllBooks(readingStatus: 'not_read');
      allBooks.addAll(books);
    }
    return allBooks;
  }
  
  Future<List<Map<String, dynamic>>> _getBooksByGenreFiltered(int genreId) async {
    if (_statusFilters.contains(ReadingStatus.all)) {
      return await _db.getBooksByGenreNew(genreId);
    }
    
    List<Map<String, dynamic>> allBooks = [];
    if (_statusFilters.contains(ReadingStatus.read)) {
      final books = await _db.getBooksByGenreNew(genreId, readingStatus: 'read');
      allBooks.addAll(books);
    }
    if (_statusFilters.contains(ReadingStatus.reading)) {
      final books = await _db.getBooksByGenreNew(genreId, readingStatus: 'reading');
      allBooks.addAll(books);
    }
    if (_statusFilters.contains(ReadingStatus.notRead)) {
      final books = await _db.getBooksByGenreNew(genreId, readingStatus: 'not_read');
      allBooks.addAll(books);
    }
    return allBooks;
  }
  
  Future<List<Map<String, dynamic>>> _getBooksBySeriesFiltered(int seriesId) async {
    if (_statusFilters.contains(ReadingStatus.all)) {
      return await _db.getBooksBySeries(seriesId);
    }
    
    List<Map<String, dynamic>> allBooks = [];
    if (_statusFilters.contains(ReadingStatus.read)) {
      final books = await _db.getBooksBySeries(seriesId, readingStatus: 'read');
      allBooks.addAll(books);
    }
    if (_statusFilters.contains(ReadingStatus.reading)) {
      final books = await _db.getBooksBySeries(seriesId, readingStatus: 'reading');
      allBooks.addAll(books);
    }
    if (_statusFilters.contains(ReadingStatus.notRead)) {
      final books = await _db.getBooksBySeries(seriesId, readingStatus: 'not_read');
      allBooks.addAll(books);
    }
    return allBooks;
  }
  
  Future<List<Map<String, dynamic>>> _getStandaloneBooks() async {
    final allBooks = await _getFilteredBooks();
    return allBooks.where((book) => book['seriesId'] == null).toList();
  }
  
  Future<void> _downloadBookImage(Map<String, dynamic> book) async {
    final success = await _imageService.downloadImageToGallery(book['imagePath']);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Image saved to gallery!' : 'Failed to save image'),
        backgroundColor: success ? Colors.green : Colors.red,
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
          'Delete "${book['title']}"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await File(book['imagePath']).delete();
      await _db.deleteBook(book['id']);
      setState(() {});
    }
  }
  
  Future<void> _deleteCategory(String categoryType, int? categoryId, String name) async {
    String typeLabel = categoryType == 'series' ? 'Series' : 
                      categoryType == 'genre' ? 'Genre' : 'Author';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text('Delete $typeLabel', 
                   style: TextStyle(color: Colors.white)),
        content: Text(
          categoryType == 'series'
            ? 'Delete series "$name"? All books will be moved to standalone.'
            : categoryType == 'genre'
              ? 'Delete genre "$name"? Genre will be removed from all books.'
              : 'Delete all books by "$name"? This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      if (categoryType == 'series' && categoryId != null) {
        // Remove series from all books (set seriesId and seriesNumber to null)
        final books = await _db.getBooksBySeries(categoryId);
        for (var book in books) {
          await _db.updateBook(book['id'], {
            ...book,
            'seriesId': null,
            'seriesNumber': null,
          });
        }
        // Delete the series itself
        await _db.deleteBookSeries(categoryId);
      } else if (categoryType == 'genre' && categoryId != null) {
        // Remove genre from all books
        final allBooks = await _db.getAllBooks();
        for (var book in allBooks) {
          final bookGenres = await _db.getBookGenres(book['id']);
          if (bookGenres.any((g) => g['id'] == categoryId)) {
            await _db.removeGenreFromBook(book['id'], categoryId);
          }
        }
        // Delete the genre itself
        await _db.deleteGenre(categoryId);
      } else if (categoryType == 'author') {
        // Delete all books by this author
        final allBooks = await _db.getAllBooks();
        final authorBooks = allBooks.where((b) => b['author'] == name).toList();
        for (var book in authorBooks) {
          if (book['imagePath'] != null) {
            try {
              await File(book['imagePath']).delete();
            } catch (e) {
              // Image might not exist
            }
          }
          await _db.deleteBook(book['id']);
        }
      }
      setState(() {});
    }
  }
  
  void _editCategory(String categoryType, int? categoryId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(
          categoryType: categoryType,
          categoryId: categoryId,
          categoryName: name,
        ),
      ),
    ).then((_) => setState(() {}));
  }
  
  void _addNewBook() {
    // TODO: Navigate to AddEditBookScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditBookScreen()),
    ).then((_) => setState(() {}));
  }
  
  Future<void> _editBook(Map<String, dynamic> book) async {
    // TODO: Navigate to AddEditBookScreen with book data
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditBookScreen(book: book)),
    );
    setState(() {});
  }
  
  Future<void> _manageGenresAndSeries() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GenreSeriesManagerScreen()),
    );
    setState(() {}); // Refresh after returning
  }
}

// Add/Edit Book Screen
class AddEditBookScreen extends StatefulWidget {
  final Map<String, dynamic>? book;
  
  const AddEditBookScreen({Key? key, this.book}) : super(key: key);
  
  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _currentPageController = TextEditingController();
  
  String? _imagePath;
  String? _selectedAuthor;
  ReadingStatus _readingStatus = ReadingStatus.notRead;
  Set<int> _selectedGenres = {};
  int? _selectedSeriesId;
  int? _seriesNumber;
  int _totalPages = 0;
  int _currentPage = 0;
  
  List<Map<String, dynamic>> _allGenres = [];
  List<Map<String, dynamic>> _allSeries = [];
  List<Map<String, dynamic>> _allAuthors = [];
  
  final _db = DatabaseHelper.instance;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final genres = await _db.getGenres();
    final series = await _db.getBookSeries();
    final authors = await _db.getAuthors();
    
    print('Loaded ${genres.length} genres, ${series.length} series, and ${authors.length} authors');
    
    setState(() {
      _allGenres = genres;
      _allSeries = series;
      _allAuthors = authors;
    });
    
    if (widget.book != null) {
      // Editing existing book
      _titleController.text = widget.book!['title'] ?? '';
      _selectedAuthor = widget.book!['author'];
      _imagePath = widget.book!['imagePath'];
      
      // Load page numbers
      _totalPages = widget.book!['totalPages'] ?? 0;
      _currentPage = widget.book!['currentPage'] ?? 0;
      _totalPagesController.text = _totalPages > 0 ? _totalPages.toString() : '';
      _currentPageController.text = _currentPage > 0 ? _currentPage.toString() : '';
      
      // Load reading status
      final status = widget.book!['readingStatus'];
      if (status == 'read') {
        _readingStatus = ReadingStatus.read;
      } else if (status == 'reading') {
        _readingStatus = ReadingStatus.reading;
      } else {
        _readingStatus = ReadingStatus.notRead;
      }
      
      // Load series info
      _selectedSeriesId = widget.book!['seriesId'];
      _seriesNumber = widget.book!['seriesNumber'];
      
      // Load genres
      final bookGenres = await _db.getBookGenres(widget.book!['id']);
      _selectedGenres = bookGenres.map((g) => g['id'] as int).toSet();
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _addNewGenre() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Genre'),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.trim().isNotEmpty) {
      final genreId = await _db.insertGenre({
        'name': nameController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      // Reload data and refresh UI
      final genres = await _db.getGenres();
      print('After adding genre, total genres: ${genres.length}');
      setState(() {
        _allGenres = genres;
        _selectedGenres.add(genreId);
      });
    }
  }
  
  Future<void> _addNewSeries() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Series'),
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
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.trim().isNotEmpty) {
      final seriesId = await _db.insertBookSeries({
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      // Reload data and refresh UI
      final series = await _db.getBookSeries();
      print('After adding series, total series: ${series.length}, selected: $seriesId');
      setState(() {
        _allSeries = series;
        _selectedSeriesId = seriesId;
      });
    }
  }
  
  Future<void> _addNewAuthor() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Author'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Author Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.trim().isNotEmpty) {
      await _db.insertAuthor({
        'name': nameController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      // Reload data and refresh UI
      final authors = await _db.getAuthors();
      print('After adding author, total authors: ${authors.length}');
      setState(() {
        _allAuthors = authors;
        _selectedAuthor = nameController.text.trim();
      });
    }
  }
  
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'book_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }
  
  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one genre')),
      );
      return;
    }
    
    if (_selectedAuthor == null || _selectedAuthor!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an author')),
      );
      return;
    }
    
    final bookData = {
      'title': _titleController.text,
      'author': _selectedAuthor!,
      'imagePath': _imagePath,
      'readingStatus': _readingStatus == ReadingStatus.read 
          ? 'read' 
          : _readingStatus == ReadingStatus.reading 
              ? 'reading' 
              : 'not_read',
      'seriesId': _selectedSeriesId,
      'seriesNumber': _seriesNumber,
      'totalPages': _totalPages,
      'currentPage': _currentPage,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    try {
      int bookId;
      if (widget.book == null) {
        // Insert new book
        bookId = await _db.insertBook(bookData);
      } else {
        // Update existing book
        bookId = widget.book!['id'];
        await _db.updateBook(bookId, bookData);
        
        // Remove old genre associations
        final oldGenres = await _db.getBookGenres(bookId);
        for (var genre in oldGenres) {
          await _db.removeGenreFromBook(bookId, genre['id']);
        }
      }
      
      // Add genre associations
      for (var genreId in _selectedGenres) {
        await _db.addGenreToBook(bookId, genreId);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.book == null ? 'Book added!' : 'Book updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving book: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'Add Book' : 'Edit Book'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBook,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 200,
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: _imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 64, color: Colors.purple[300]),
                                    const SizedBox(height: 8),
                                    Text('Tap to add cover', style: TextStyle(color: Colors.purple[300])),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Author
                    DropdownButtonFormField<String>(
                      value: _selectedAuthor,
                      decoration: const InputDecoration(
                        labelText: 'Author *',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '__add_new__',
                          child: Row(
                            children: [
                              Icon(Icons.add, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Add New Author', style: TextStyle(color: Colors.purple)),
                            ],
                          ),
                        ),
                        ..._allAuthors.map((author) => DropdownMenuItem<String>(
                          value: author['name'] as String,
                          child: Text(author['name'] as String),
                        )),
                      ],
                      onChanged: (value) async {
                        if (value == '__add_new__') {
                          await _addNewAuthor();
                        } else {
                          setState(() {
                            _selectedAuthor = value;
                          });
                        }
                      },
                      validator: (v) => v == null || v.isEmpty || v == '__add_new__' ? 'Please select an author' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // Page Numbers
                    const Text('Page Count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalPagesController,
                            decoration: const InputDecoration(
                              labelText: 'Total Pages',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.book),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              _totalPages = int.tryParse(v) ?? 0;
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _currentPageController,
                            decoration: InputDecoration(
                              labelText: _readingStatus == ReadingStatus.reading ? 'Current Page' : 'Pages Read',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.bookmark),
                              enabled: _readingStatus == ReadingStatus.reading || _readingStatus == ReadingStatus.read,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              _currentPage = int.tryParse(v) ?? 0;
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_totalPages > 0 && _currentPage > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: _currentPage / _totalPages,
                          minHeight: 8,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation(
                            _readingStatus == ReadingStatus.read ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    if (_totalPages > 0 && _currentPage > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${(_currentPage / _totalPages * 100).toStringAsFixed(1)}% • ${_totalPages - _currentPage} pages remaining',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Reading Status
                    const Text('Reading Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('✓ Read'),
                          selected: _readingStatus == ReadingStatus.read,
                          onSelected: (s) => setState(() => _readingStatus = ReadingStatus.read),
                        ),
                        ChoiceChip(
                          label: const Text('📖 Reading'),
                          selected: _readingStatus == ReadingStatus.reading,
                          onSelected: (s) => setState(() => _readingStatus = ReadingStatus.reading),
                        ),
                        ChoiceChip(
                          label: const Text('○ Not Read'),
                          selected: _readingStatus == ReadingStatus.notRead,
                          onSelected: (s) => setState(() => _readingStatus = ReadingStatus.notRead),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Genres (multi-select)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Genres * (tap multiple)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _addNewGenre,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add New'),
                          style: TextButton.styleFrom(foregroundColor: Colors.purpleAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _allGenres.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No genres yet. Click "Add New" to create one.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          )
                        : Wrap(
                            spacing: 8,
                            children: _allGenres.map((genre) {
                              final isSelected = _selectedGenres.contains(genre['id']);
                              return FilterChip(
                                label: Text(genre['name']),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedGenres.add(genre['id']);
                                    } else {
                                      _selectedGenres.remove(genre['id']);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 24),
                    
                    // Series
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Series (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _addNewSeries,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add New'),
                          style: TextButton.styleFrom(foregroundColor: Colors.purpleAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedSeriesId,
                      decoration: const InputDecoration(
                        labelText: 'Select Series',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ..._allSeries.map((series) => DropdownMenuItem(
                          value: series['id'],
                          child: Text(series['name']),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSeriesId = value;
                          if (value == null) _seriesNumber = null;
                        });
                      },
                    ),
                    
                    if (_selectedSeriesId != null) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _seriesNumber?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Book # in Series',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _seriesNumber = int.tryParse(v),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveBook,
                        icon: const Icon(Icons.save),
                        label: Text(widget.book == null ? 'Add Book' : 'Update Book'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _totalPagesController.dispose();
    _currentPageController.dispose();
    super.dispose();
  }
}

// ==================== BOOK DETAIL SCREEN ====================

class BookDetailScreen extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _genres = [];
  Map<String, dynamic>? _series;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  Future<void> _loadBookDetails() async {
    final genres = await _db.getBookGenres(widget.book['id']);
    Map<String, dynamic>? series;
    if (widget.book['seriesId'] != null) {
      final allSeries = await _db.getBookSeries();
      series = allSeries.firstWhere(
        (s) => s['id'] == widget.book['seriesId'],
        orElse: () => {},
      );
    }
    setState(() {
      _genres = genres;
      _series = series;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'read': return Colors.greenAccent;
      case 'reading': return Colors.orangeAccent;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'read': return 'Read';
      case 'reading': return 'Reading';
      default: return 'Not Read';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.book['readingStatus'] ?? 'not_read';
    final statusColor = _getStatusColor(status);
    final currentPage = widget.book['currentPage'] ?? 0;
    final totalPages = widget.book['totalPages'] ?? 1;
    final progress = (currentPage / totalPages * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      appBar: AppBar(
        title: Text('Book Details'),
        backgroundColor: Color(0xFF16213E),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Image Section
                  Container(
                    width: double.infinity,
                    height: 500,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF16213E),
                          Color(0xFF0A0E27),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'book_${widget.book['id']}',
                        child: Container(
                          margin: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.book['imagePath'] != null
                                ? Image.file(
                                    File(widget.book['imagePath']),
                                    fit: BoxFit.contain,
                                  )
                                : Container(
                                    width: 300,
                                    height: 450,
                                    color: Colors.grey[800],
                                    child: Icon(Icons.book, size: 100, color: Colors.white54),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Book Details Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          widget.book['title'] ?? 'Untitled',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Author
                        Text(
                          'by ${widget.book['author'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 12, color: statusColor),
                              SizedBox(width: 8),
                              Text(
                                _getStatusText(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Reading Progress
                        if (totalPages > 0) ...[
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1A1F3A),
                                  Color(0xFF16213E),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: status == 'read'
                                ? Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.greenAccent,
                                          size: 48,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Completed!',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '$totalPages pages',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Reading Progress',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '$progress%',
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: currentPage / totalPages,
                                          backgroundColor: Colors.white.withOpacity(0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                          minHeight: 10,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Page $currentPage of $totalPages',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          SizedBox(height: 24),
                        ],

                        // Series Information
                        if (_series != null && _series!.isNotEmpty) ...[
                          _buildInfoCard(
                            'Series',
                            _series!['name'] ?? '',
                            Icons.collections_bookmark,
                            Colors.purpleAccent,
                            subtitle: widget.book['seriesNumber'] != null 
                                ? 'Book #${widget.book['seriesNumber']}'
                                : null,
                          ),
                          SizedBox(height: 16),
                        ],

                        // Genres
                        if (_genres.isNotEmpty) ...[
                          Text(
                            'Genres',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _genres.map((genre) => 
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purpleAccent.withOpacity(0.3),
                                      Colors.cyanAccent.withOpacity(0.2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.purpleAccent.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  genre['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                          SizedBox(height: 24),
                        ],

                        // Additional Info
                        _buildInfoCard(
                          'Added',
                          _formatDate(widget.book['createdAt']),
                          Icons.calendar_today,
                          Colors.cyanAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1A1F3A),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

// Edit Category Screen (for Series, Authors, and Genres)
class EditCategoryScreen extends StatefulWidget {
  final String categoryType; // 'series', 'author', or 'genre'
  final int? categoryId; // seriesId or genreId
  final String categoryName;

  const EditCategoryScreen({
    Key? key,
    required this.categoryType,
    this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ImageService _imageService = ImageService.instance;
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _categoryBooks = [];
  List<Map<String, dynamic>> _availableBooks = [];
  String? _coverImagePath;
  
  @override
  void initState() {
    super.initState();
    _nameController.text = widget.categoryName;
    _loadBooks();
    _loadCoverImage();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCoverImage() async {
    if (widget.categoryType == 'series') {
      final allSeries = await _db.getBookSeries();
      final series = allSeries.firstWhere(
        (s) => s['id'] == widget.categoryId,
        orElse: () => <String, dynamic>{},
      );
      if (series.isNotEmpty && series['coverImagePath'] != null) {
        setState(() {
          _coverImagePath = series['coverImagePath'];
        });
      }
    } else if (widget.categoryType == 'genre') {
      final allGenres = await _db.getGenres();
      final genre = allGenres.firstWhere(
        (g) => g['id'] == widget.categoryId,
        orElse: () => <String, dynamic>{},
      );
      if (genre.isNotEmpty && genre['coverImagePath'] != null) {
        setState(() {
          _coverImagePath = genre['coverImagePath'];
        });
      }
    } else {
      final authors = await _db.getAuthors();
      final author = authors.firstWhere(
        (a) => a['name'] == widget.categoryName,
        orElse: () => <String, dynamic>{},
      );
      if (author.isNotEmpty && author['coverImagePath'] != null) {
        setState(() {
          _coverImagePath = author['coverImagePath'];
        });
      }
    }
  }

  Future<void> _loadBooks() async {
    if (widget.categoryType == 'series') {
      _categoryBooks = List.from(await _db.getBooksBySeries(widget.categoryId!));
      final allBooks = await _db.getAllBooks();
      _availableBooks = allBooks.where((b) => b['seriesId'] != widget.categoryId).toList();
    } else if (widget.categoryType == 'genre') {
      _categoryBooks = await _db.getBooksByGenreNew(widget.categoryId!);
      final allBooks = await _db.getAllBooks();
      final currentBookIds = _categoryBooks.map((b) => b['id']).toSet();
      _availableBooks = allBooks.where((b) => !currentBookIds.contains(b['id'])).toList();
    } else {
      final allBooks = await _db.getAllBooks();
      _categoryBooks = allBooks.where((b) => b['author'] == widget.categoryName).toList();
      _availableBooks = allBooks.where((b) => b['author'] != widget.categoryName).toList();
    }
    
    setState(() {});
  }

  Future<void> _pickCoverImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Copy to permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'cover_${widget.categoryType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _coverImagePath = savedImage.path;
      });
    }
  }

  Future<void> _saveCoverImage() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (widget.categoryType == 'series') {
      await _db.updateBookSeries(widget.categoryId!, {
        'name': newName,
        'coverImagePath': _coverImagePath,
      });
    } else if (widget.categoryType == 'genre') {
      await _db.updateGenre(widget.categoryId!, {
        'name': newName,
        'coverImagePath': _coverImagePath,
      });
    } else {
      // For authors, save to authors table
      final authors = await _db.getAuthors();
      final existingAuthor = authors.firstWhere(
        (a) => a['name'] == widget.categoryName,
        orElse: () => <String, dynamic>{},
      );
      
      if (existingAuthor.isNotEmpty) {
        await _db.updateAuthor(existingAuthor['id'], {
          'name': newName,
          'coverImagePath': _coverImagePath,
        });
      } else {
        await _db.insertAuthor({
          'name': newName,
          'coverImagePath': _coverImagePath,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      
      // Update book author names
      if (newName != widget.categoryName) {
        for (var book in _categoryBooks) {
          await _db.updateBook(book['id'], {
            ...book,
            'author': newName,
          });
        }
      }
    }
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Changes saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Go back after saving
    Navigator.pop(context);
  }

  Future<void> _removeBookFromCategory(Map<String, dynamic> book) async {
    if (widget.categoryType == 'series') {
      await _db.updateBook(book['id'], {
        ...book,
        'seriesId': null,
        'seriesNumber': null,
      });
    } else if (widget.categoryType == 'genre') {
      await _db.removeGenreFromBook(book['id'], widget.categoryId!);
    } else {
      // For authors, we can't remove without deleting - show message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot remove author. Edit the book to change author.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    await _loadBooks();
  }

  Future<void> _addBookToCategory() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text('Add Book', style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableBooks.length,
            itemBuilder: (context, index) {
              final book = _availableBooks[index];
              return ListTile(
                title: Text(book['title'], style: TextStyle(color: Colors.white)),
                subtitle: Text(book['author'] ?? 'Unknown', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.pop(context, book),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      if (widget.categoryType == 'series') {
        // Find the highest series number and add 1
        int maxNumber = 0;
        for (var book in _categoryBooks) {
          final num = book['seriesNumber'] as int? ?? 0;
          if (num > maxNumber) maxNumber = num;
        }
        
        await _db.updateBook(selected['id'], {
          ...selected,
          'seriesId': widget.categoryId,
          'seriesNumber': maxNumber + 1,
        });
      } else if (widget.categoryType == 'genre') {
        await _db.addGenreToBook(selected['id'], widget.categoryId!);
      } else {
        await _db.updateBook(selected['id'], {
          ...selected,
          'author': widget.categoryName,
        });
      }
      await _loadBooks();
    }
  }

  Future<void> _editSeriesNumber(Map<String, dynamic> book) async {
    final controller = TextEditingController(text: (book['seriesNumber'] ?? '').toString());
    
    final newNumber = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text('Edit Series Number', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Series Number',
            labelStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final num = int.tryParse(controller.text);
              Navigator.pop(context, num);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );

    if (newNumber != null) {
      await _db.updateBook(book['id'], {
        ...book,
        'seriesNumber': newNumber,
      });
      await _loadBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.categoryType == 'series' ? Colors.cyanAccent : 
                  widget.categoryType == 'genre' ? Colors.purpleAccent : Colors.tealAccent;
    final typeLabel = widget.categoryType == 'series' ? 'Series' :
                     widget.categoryType == 'genre' ? 'Genre' : 'Author';
    
    return Scaffold(
      backgroundColor: Color(0xFF0F0E17),
      appBar: AppBar(
        title: Text('Edit $typeLabel'),
        backgroundColor: Color(0xFF1A1A2E),
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: _pickCoverImage,
            tooltip: 'Add Cover Image',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addBookToCategory,
            tooltip: 'Add Book',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveCoverImage,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: Column(
        children: [
          // Name edit field
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: '$typeLabel Name',
                labelStyle: TextStyle(color: color),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
          ),
          if (_coverImagePath != null)
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(File(_coverImagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 24,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _coverImagePath = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cover photo removed. Click Save to confirm.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    tooltip: 'Remove Cover Photo',
                  ),
                ),
              ],
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.book, color: color),
                SizedBox(width: 8),
                Text(
                  '${_categoryBooks.length} books',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _categoryBooks.length,
              itemBuilder: (context, index) {
                final book = _categoryBooks[index];
                return Card(
                  color: Color(0xFF1A1A2E),
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: book['imagePath'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(book['imagePath']),
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(Icons.book, color: color),
                    title: Text(book['title'], style: TextStyle(color: Colors.white)),
                    subtitle: widget.categoryType == 'series'
                        ? Text('Book #${book['seriesNumber'] ?? '?'}', 
                               style: TextStyle(color: Colors.white70))
                        : Text(book['author'] ?? 'Unknown', 
                               style: TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.categoryType == 'series')
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.cyanAccent, size: 20),
                            onPressed: () => _editSeriesNumber(book),
                          ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _removeBookFromCategory(book),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveCoverImage,
        backgroundColor: color,
        foregroundColor: Colors.black,
        icon: Icon(Icons.save),
        label: Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
