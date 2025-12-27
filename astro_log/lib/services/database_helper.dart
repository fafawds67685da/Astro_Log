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
      version: 1,
      onCreate: _createDB,
    );
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

    // Gallery Images table
    await db.execute('''
      CREATE TABLE gallery_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        telescope TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        title TEXT,
        description TEXT,
        createdAt TEXT NOT NULL
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
}
