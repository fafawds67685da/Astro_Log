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
      version: 5,
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
}
