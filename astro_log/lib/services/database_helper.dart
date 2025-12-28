import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('astro_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new tables
      await db.execute('''
        CREATE TABLE genres (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE classifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE research_papers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT,
          imagePath TEXT NOT NULL,
          status TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      // Add genre column to books table
      await db.execute('ALTER TABLE books ADD COLUMN genreId INTEGER');

      // Add classification column to celestial_objects table
      await db.execute('ALTER TABLE celestial_objects ADD COLUMN classificationId INTEGER');
    }
    
    if (oldVersion < 3) {
      // Delete all existing genres and classifications
      await db.delete('genres');
      await db.delete('classifications');
    }
    
    if (oldVersion < 4) {
      // Check if columns exist, if not add them
      try {
        await db.execute('ALTER TABLE books ADD COLUMN genreId INTEGER');
      } catch (e) {
        // Column already exists
      }
      
      try {
        await db.execute('ALTER TABLE celestial_objects ADD COLUMN classificationId INTEGER');
      } catch (e) {
        // Column already exists
      }
      
      // Ensure tables exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS genres (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS classifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS research_papers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT,
          imagePath TEXT NOT NULL,
          status TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    
    if (oldVersion < 5) {
      // Create gallery albums table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS gallery_albums (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        )
      ''');
      
      // Migrate existing gallery_images to use albumId
      // First, create a default album
      await db.insert('gallery_albums', {
        'name': 'My Gallery',
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Check if telescope column exists and migrate
      try {
        final existingImages = await db.query('gallery_images');
        if (existingImages.isNotEmpty) {
          // Drop old table and recreate
          await db.execute('DROP TABLE IF EXISTS gallery_images_old');
          await db.execute('ALTER TABLE gallery_images RENAME TO gallery_images_old');
          
          await db.execute('''
            CREATE TABLE gallery_images (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              albumId INTEGER NOT NULL,
              imagePath TEXT NOT NULL,
              title TEXT,
              description TEXT,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (albumId) REFERENCES gallery_albums (id) ON DELETE CASCADE
            )
          ''');
          
          // Copy data to new table with default albumId = 1
          await db.execute('''
            INSERT INTO gallery_images (albumId, imagePath, title, description, createdAt)
            SELECT 1, imagePath, title, description, createdAt FROM gallery_images_old
          ''');
          
          await db.execute('DROP TABLE gallery_images_old');
        }
      } catch (e) {
        // Table doesn't exist yet or error migrating, skip
      }
    }
    
    if (oldVersion < 6) {
      // Create book_series table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS book_series (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
      
      // Create book_genres junction table for many-to-many relationship
      await db.execute('''
        CREATE TABLE IF NOT EXISTS book_genres (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bookId INTEGER NOT NULL,
          genreId INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE,
          FOREIGN KEY (genreId) REFERENCES genres (id) ON DELETE CASCADE,
          UNIQUE(bookId, genreId)
        )
      ''');
      
      // Migrate existing genreId data to junction table
      final existingBooks = await db.query('books');
      for (var book in existingBooks) {
        if (book['genreId'] != null) {
          await db.insert('book_genres', {
            'bookId': book['id'],
            'genreId': book['genreId'],
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
      
      // Add series columns to books
      await db.execute('ALTER TABLE books ADD COLUMN seriesId INTEGER');
      await db.execute('ALTER TABLE books ADD COLUMN seriesNumber INTEGER');
      
      // Change isRead to readingStatus
      await db.execute('ALTER TABLE books ADD COLUMN readingStatus TEXT DEFAULT ''not_read''');
      
      // Migrate isRead values to readingStatus
      await db.execute('UPDATE books SET readingStatus = ''read'' WHERE isRead = 1');
      await db.execute('UPDATE books SET readingStatus = ''not_read'' WHERE isRead = 0 OR isRead IS NULL');
      
      // Note: Cannot drop genreId and isRead columns in SQLite, but we won't use them anymore
    }
    
    if (oldVersion < 7) {
      // Add page tracking columns
      await db.execute('ALTER TABLE books ADD COLUMN totalPages INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE books ADD COLUMN currentPage INTEGER DEFAULT 0');
    }

    if (oldVersion < 8) {
      // Create authors table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS authors (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          createdAt TEXT NOT NULL
        )
      ''');
      
      // Migrate existing author data to authors table
      final existingBooks = await db.query('books');
      for (var book in existingBooks) {
        if (book['author'] != null && (book['author'] as String).isNotEmpty) {
          try {
            await db.insert('authors', {
              'name': book['author'],
              'createdAt': DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          } catch (e) {
            // Skip if author already exists
          }
        }
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Books table
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        imagePath TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        genreId INTEGER,
        createdAt TEXT NOT NULL
      )
    ''');

    // Celestial Objects table
    await db.execute('''
      CREATE TABLE celestial_objects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        magnitude TEXT,
        imagePath TEXT NOT NULL,
        isObserved INTEGER NOT NULL DEFAULT 0,
        classificationId INTEGER,
        createdAt TEXT NOT NULL
      )
    ''');

    // Genres table
    await db.execute('''
      CREATE TABLE genres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');

    // Classifications table
    await db.execute('''
      CREATE TABLE classifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');

    // Projects table
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Research Papers table
    await db.execute('''
      CREATE TABLE research_papers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        imagePath TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Constellations table
    await db.execute('''
      CREATE TABLE constellations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hemisphere TEXT,
        season TEXT,
        imagePath TEXT NOT NULL,
        isIdentified INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Observatories table
    await db.execute('''
      CREATE TABLE observatories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        isVisited INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // Observatory Images table (for visited observatories)
    await db.execute('''
      CREATE TABLE observatory_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        observatoryId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        caption TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (observatoryId) REFERENCES observatories (id) ON DELETE CASCADE
      )
    ''');

    // Gallery Albums table
    await db.execute('''
      CREATE TABLE gallery_albums (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');

    // Gallery Images table
    await db.execute('''
      CREATE TABLE gallery_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        albumId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        title TEXT,
        description TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (albumId) REFERENCES gallery_albums (id) ON DELETE CASCADE
      )
    ''');
  }

  // Copy image to app's local directory
  Future<String> saveImage(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');
    return savedImage.path;
  }

  // Books CRUD
  Future<int> insertBook(Map<String, dynamic> book) async {
    final db = await database;
    return await db.insert('books', book);
  }

  Future<List<Map<String, dynamic>>> getBooks({bool? isRead}) async {
    final db = await database;
    if (isRead == null) {
      return await db.query('books', orderBy: 'createdAt DESC');
    }
    return await db.query(
      'books',
      where: 'isRead = ?',
      whereArgs: [isRead ? 1 : 0],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateBook(int id, Map<String, dynamic> book) async {
    final db = await database;
    return await db.update('books', book, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // Celestial Objects CRUD
  Future<int> insertCelestialObject(Map<String, dynamic> object) async {
    final db = await database;
    return await db.insert('celestial_objects', object);
  }

  Future<List<Map<String, dynamic>>> getCelestialObjects({bool? isObserved}) async {
    final db = await database;
    if (isObserved == null) {
      return await db.query('celestial_objects', orderBy: 'createdAt DESC');
    }
    return await db.query(
      'celestial_objects',
      where: 'isObserved = ?',
      whereArgs: [isObserved ? 1 : 0],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateCelestialObject(int id, Map<String, dynamic> object) async {
    final db = await database;
    return await db.update('celestial_objects', object, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCelestialObject(int id) async {
    final db = await database;
    return await db.delete('celestial_objects', where: 'id = ?', whereArgs: [id]);
  }

  // Constellations CRUD
  Future<int> insertConstellation(Map<String, dynamic> constellation) async {
    final db = await database;
    return await db.insert('constellations', constellation);
  }

  Future<List<Map<String, dynamic>>> getConstellations({bool? isIdentified}) async {
    final db = await database;
    if (isIdentified == null) {
      return await db.query('constellations', orderBy: 'createdAt DESC');
    }
    return await db.query(
      'constellations',
      where: 'isIdentified = ?',
      whereArgs: [isIdentified ? 1 : 0],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateConstellation(int id, Map<String, dynamic> constellation) async {
    final db = await database;
    return await db.update('constellations', constellation, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteConstellation(int id) async {
    final db = await database;
    return await db.delete('constellations', where: 'id = ?', whereArgs: [id]);
  }

  // Observatories CRUD
  Future<int> insertObservatory(Map<String, dynamic> observatory) async {
    final db = await database;
    return await db.insert('observatories', observatory);
  }

  Future<List<Map<String, dynamic>>> getObservatories({bool? isVisited}) async {
    final db = await database;
    if (isVisited == null) {
      return await db.query('observatories', orderBy: 'createdAt DESC');
    }
    return await db.query(
      'observatories',
      where: 'isVisited = ?',
      whereArgs: [isVisited ? 1 : 0],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateObservatory(int id, Map<String, dynamic> observatory) async {
    final db = await database;
    return await db.update('observatories', observatory, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteObservatory(int id) async {
    final db = await database;
    return await db.delete('observatories', where: 'id = ?', whereArgs: [id]);
  }

  // Observatory Images CRUD
  Future<int> insertObservatoryImage(Map<String, dynamic> image) async {
    final db = await database;
    return await db.insert('observatory_images', image);
  }

  Future<List<Map<String, dynamic>>> getObservatoryImages(int observatoryId) async {
    final db = await database;
    return await db.query(
      'observatory_images',
      where: 'observatoryId = ?',
      whereArgs: [observatoryId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> deleteObservatoryImage(int id) async {
    final db = await database;
    return await db.delete('observatory_images', where: 'id = ?', whereArgs: [id]);
  }

  // Gallery Images CRUD
  Future<int> insertGalleryImage(Map<String, dynamic> image) async {
    final db = await database;
    return await db.insert('gallery_images', image);
  }

  Future<List<Map<String, dynamic>>> getGalleryImages({String? telescope}) async {
    final db = await database;
    if (telescope == null) {
      return await db.query('gallery_images', orderBy: 'createdAt DESC');
    }
    return await db.query(
      'gallery_images',
      where: 'telescope = ?',
      whereArgs: [telescope],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> deleteGalleryImage(int id) async {
    final db = await database;
    return await db.delete('gallery_images', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Genres CRUD
  Future<int> insertGenre(Map<String, dynamic> genre) async {
    final db = await database;
    return await db.insert('genres', genre);
  }

  Future<List<Map<String, dynamic>>> getGenres() async {
    final db = await database;
    return await db.query('genres', orderBy: 'name ASC');
  }

  Future<int> updateGenre(int id, Map<String, dynamic> genre) async {
    final db = await database;
    return await db.update('genres', genre, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGenre(int id) async {
    final db = await database;
    return await db.delete('genres', where: 'id = ?', whereArgs: [id]);
  }

  // Classifications CRUD
  Future<int> insertClassification(Map<String, dynamic> classification) async {
    final db = await database;
    return await db.insert('classifications', classification);
  }

  Future<List<Map<String, dynamic>>> getClassifications() async {
    final db = await database;
    return await db.query('classifications', orderBy: 'name ASC');
  }

  Future<int> updateClassification(int id, Map<String, dynamic> classification) async {
    final db = await database;
    return await db.update('classifications', classification, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteClassification(int id) async {
    final db = await database;
    return await db.delete('classifications', where: 'id = ?', whereArgs: [id]);
  }

  // Projects CRUD
  Future<int> insertProject(Map<String, dynamic> project) async {
    final db = await database;
    return await db.insert('projects', project);
  }

  Future<List<Map<String, dynamic>>> getProjects({String? status}) async {
    final db = await database;
    if (status == null) {
      return await db.query('projects', orderBy: 'createdAt DESC');
    }
    return await db.query(
      'projects',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateProject(int id, Map<String, dynamic> project) async {
    final db = await database;
    return await db.update('projects', project, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // Research Papers CRUD
  Future<int> insertResearchPaper(Map<String, dynamic> paper) async {
    final db = await database;
    return await db.insert('research_papers', paper);
  }

  Future<List<Map<String, dynamic>>> getResearchPapers({String? status}) async {
    final db = await database;
    if (status == null) {
      return await db.query('research_papers', orderBy: 'createdAt DESC');
    }
    return await db.query(
      'research_papers',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateResearchPaper(int id, Map<String, dynamic> paper) async {
    final db = await database;
    return await db.update('research_papers', paper, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteResearchPaper(int id) async {
    final db = await database;
    return await db.delete('research_papers', where: 'id = ?', whereArgs: [id]);
  }

  // Get books by genre
  Future<List<Map<String, dynamic>>> getBooksByGenre(int? genreId, {bool? isRead}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (genreId != null && isRead != null) {
      where = 'genreId = ? AND isRead = ?';
      whereArgs = [genreId, isRead ? 1 : 0];
    } else if (genreId != null) {
      where = 'genreId = ?';
      whereArgs = [genreId];
    } else if (isRead != null) {
      where = 'isRead = ?';
      whereArgs = [isRead ? 1 : 0];
    }
    
    if (where.isEmpty) {
      return await db.query('books', orderBy: 'createdAt DESC');
    }
    return await db.query('books', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC');
  }

  // Get celestial objects by classification
  Future<List<Map<String, dynamic>>> getCelestialObjectsByClassification(int? classificationId, {bool? isObserved}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (classificationId != null && isObserved != null) {
      where = 'classificationId = ? AND isObserved = ?';
      whereArgs = [classificationId, isObserved ? 1 : 0];
    } else if (classificationId != null) {
      where = 'classificationId = ?';
      whereArgs = [classificationId];
    } else if (isObserved != null) {
      where = 'isObserved = ?';
      whereArgs = [isObserved ? 1 : 0];
    }
    
    if (where.isEmpty) {
      return await db.query('celestial_objects', orderBy: 'createdAt DESC');
    }
    return await db.query('celestial_objects', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC');
  }

  // Gallery Albums CRUD
  Future<int> insertGalleryAlbum(Map<String, dynamic> album) async {
    final db = await database;
    return await db.insert('gallery_albums', album);
  }

  Future<List<Map<String, dynamic>>> getGalleryAlbums() async {
    final db = await database;
    return await db.query('gallery_albums', orderBy: 'createdAt DESC');
  }

  Future<int> updateGalleryAlbum(int id, Map<String, dynamic> album) async {
    final db = await database;
    return await db.update('gallery_albums', album, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGalleryAlbum(int id) async {
    final db = await database;
    return await db.delete('gallery_albums', where: 'id = ?', whereArgs: [id]);
  }

  // Gallery Images by Album
  Future<List<Map<String, dynamic>>> getGalleryImagesByAlbum(int albumId) async {
    final db = await database;
    return await db.query(
      'gallery_images',
      where: 'albumId = ?',
      whereArgs: [albumId],
      orderBy: 'createdAt DESC',
    );
  }
  
  // ==================== BOOK SERIES METHODS ====================
  
  Future<int> insertBookSeries(Map<String, dynamic> series) async {
    final db = await database;
    return await db.insert('book_series', series);
  }
  
  Future<List<Map<String, dynamic>>> getBookSeries() async {
    final db = await database;
    return await db.query('book_series', orderBy: 'name ASC');
  }
  
  Future<int> updateBookSeries(int id, Map<String, dynamic> series) async {
    final db = await database;
    return await db.update('book_series', series, where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> deleteBookSeries(int id) async {
    final db = await database;
    return await db.delete('book_series', where: 'id = ?', whereArgs: [id]);
  }
  
  // Get books by series (ordered by seriesNumber)
  Future<List<Map<String, dynamic>>> getBooksBySeries(int? seriesId, {String? readingStatus}) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];
    
    if (seriesId != null) {
      where = 'seriesId = ?';
      whereArgs = [seriesId];
      if (readingStatus != null) {
        where += ' AND readingStatus = ?';
        whereArgs.add(readingStatus);
      }
    } else if (readingStatus != null) {
      where = 'readingStatus = ?';
      whereArgs = [readingStatus];
    }
    
    if (where.isEmpty) {
      return await db.query('books', orderBy: 'seriesNumber ASC, createdAt DESC');
    }
    return await db.query('books', where: where, whereArgs: whereArgs, orderBy: 'seriesNumber ASC, createdAt DESC');
  }
  
  // ==================== AUTHORS METHODS ====================
  
  Future<int> insertAuthor(Map<String, dynamic> author) async {
    final db = await database;
    return await db.insert('authors', author, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  
  Future<List<Map<String, dynamic>>> getAuthors() async {
    final db = await database;
    return await db.query('authors', orderBy: 'name ASC');
  }
  
  Future<int> updateAuthor(int id, Map<String, dynamic> author) async {
    final db = await database;
    return await db.update('authors', author, where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> deleteAuthor(int id) async {
    final db = await database;
    return await db.delete('authors', where: 'id = ?', whereArgs: [id]);
  }
  
  // Get books by author
  Future<List<Map<String, dynamic>>> getBooksByAuthor(String author, {String? readingStatus}) async {
    final db = await database;
    String where = 'author = ?';
    List<dynamic> whereArgs = [author];
    
    if (readingStatus != null) {
      where += ' AND readingStatus = ?';
      whereArgs.add(readingStatus);
    }
    
    return await db.query('books', where: where, whereArgs: whereArgs, orderBy: 'createdAt DESC');
  }
  
  // ==================== BOOK GENRES (MANY-TO-MANY) METHODS ====================
  
  // Add genre to book
  Future<int> addGenreToBook(int bookId, int genreId) async {
    final db = await database;
    return await db.insert('book_genres', {
      'bookId': bookId,
      'genreId': genreId,
      'createdAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
  
  // Remove genre from book
  Future<int> removeGenreFromBook(int bookId, int genreId) async {
    final db = await database;
    return await db.delete(
      'book_genres',
      where: 'bookId = ? AND genreId = ?',
      whereArgs: [bookId, genreId],
    );
  }
  
  // Get all genres for a specific book
  Future<List<Map<String, dynamic>>> getBookGenres(int bookId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT g.* FROM genres g
      INNER JOIN book_genres bg ON g.id = bg.genreId
      WHERE bg.bookId = ?
      ORDER BY g.name ASC
    ''', [bookId]);
  }
  
  // Get all books for a specific genre with optional status filter
  Future<List<Map<String, dynamic>>> getBooksByGenreNew(int genreId, {String? readingStatus}) async {
    final db = await database;
    String whereClause = readingStatus != null ? 'AND b.readingStatus = ?' : '';
    List<dynamic> args = readingStatus != null ? [genreId, readingStatus] : [genreId];
    
    return await db.rawQuery('''
      SELECT DISTINCT b.* FROM books b
      INNER JOIN book_genres bg ON b.id = bg.bookId
      WHERE bg.genreId = ? $whereClause
      ORDER BY b.createdAt DESC
    ''', args);
  }
  
  // Get all books with optional status filter (replacement for old method)
  Future<List<Map<String, dynamic>>> getAllBooks({String? readingStatus}) async {
    final db = await database;
    if (readingStatus != null) {
      return await db.query(
        'books',
        where: 'readingStatus = ?',
        whereArgs: [readingStatus],
        orderBy: 'createdAt DESC',
      );
    }
    return await db.query('books', orderBy: 'createdAt DESC');
  }
  
  // Get count of books by reading status
  Future<Map<String, int>> getBookStatusCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        readingStatus,
        COUNT(*) as count
      FROM books
      GROUP BY readingStatus
    ''');
    
    Map<String, int> counts = {
      'read': 0,
      'reading': 0,
      'not_read': 0,
    };
    
    for (var row in result) {
      counts[row['readingStatus'] as String] = row['count'] as int;
    }
    
    return counts;
  }
  
  // Get reading statistics for dashboard
  Future<Map<String, dynamic>> getReadingStatistics() async {
    final db = await database;
    
    // Get status counts
    final statusCounts = await getBookStatusCounts();
    
    // Get page statistics
    final pageStats = await db.rawQuery('''
      SELECT 
        SUM(totalPages) as totalPages,
        SUM(CASE WHEN readingStatus = 'read' THEN totalPages ELSE 0 END) as pagesRead,
        SUM(CASE WHEN readingStatus = 'reading' THEN currentPage ELSE 0 END) as currentlyReadingPages,
        SUM(CASE WHEN readingStatus = 'reading' THEN totalPages ELSE 0 END) as currentlyReadingTotalPages
      FROM books
      WHERE totalPages > 0
    ''');
    
    final stats = pageStats.first;
    final totalPages = (stats['totalPages'] as int?) ?? 0;
    final pagesRead = (stats['pagesRead'] as int?) ?? 0;
    final currentlyReadingPages = (stats['currentlyReadingPages'] as int?) ?? 0;
    final currentlyReadingTotalPages = (stats['currentlyReadingTotalPages'] as int?) ?? 0;
    
    final totalPagesCompleted = pagesRead + currentlyReadingPages;
    final overallProgress = totalPages > 0 ? (totalPagesCompleted / totalPages * 100) : 0.0;
    final pagesRemaining = totalPages - totalPagesCompleted;
    
    return {
      'booksRead': statusCounts['read'] ?? 0,
      'booksReading': statusCounts['reading'] ?? 0,
      'booksNotRead': statusCounts['not_read'] ?? 0,
      'totalBooks': (statusCounts['read'] ?? 0) + (statusCounts['reading'] ?? 0) + (statusCounts['not_read'] ?? 0),
      'totalPages': totalPages,
      'pagesRead': pagesRead,
      'currentlyReadingPages': currentlyReadingPages,
      'currentlyReadingTotalPages': currentlyReadingTotalPages,
      'totalPagesCompleted': totalPagesCompleted,
      'pagesRemaining': pagesRemaining,
      'overallProgress': overallProgress,
      'readPercentage': statusCounts['read'] != null && (statusCounts['read']! + statusCounts['reading']! + statusCounts['not_read']!) > 0
          ? (statusCounts['read']! / (statusCounts['read']! + statusCounts['reading']! + statusCounts['not_read']!) * 100)
          : 0.0,
      'readingPercentage': statusCounts['reading'] != null && (statusCounts['read']! + statusCounts['reading']! + statusCounts['not_read']!) > 0
          ? (statusCounts['reading']! / (statusCounts['read']! + statusCounts['reading']! + statusCounts['not_read']!) * 100)
          : 0.0,
    };
  }
}

