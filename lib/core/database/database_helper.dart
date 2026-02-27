import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('roapp_private.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    // Users (Passkey support)
    await db.execute('''
CREATE TABLE users (
  id $idType,
  email $textType,
  passkey $textType
)
''');

    await db.execute('''
CREATE TABLE customers (
  id $idType,
  name $textType,
  phone $textType,
  model $textType,
  status $textType,
  lastService $textType,
  area $textType
)
''');

    await db.execute('''
CREATE TABLE inventory (
  id $idType,
  name $textType,
  sku $textType,
  supplier $textType,
  price $doubleType,
  stock $intType,
  lowStockThreshold $intType,
  category $textType
)
''');

    await db.execute('''
CREATE TABLE service_requests (
  id $idType,
  customerName $textType,
  address $textType,
  type $textType,
  model $textType,
  time $textType,
  status $textType
)
''');

    await db.execute('''
CREATE TABLE suppliers (
  id $idType,
  name $textType,
  contactPerson $textType,
  city $textType,
  specialties $textType,
  activePOs $intType,
  status $textType
)
''');

    await db.execute('''
CREATE TABLE technicians (
  id $idType,
  name $textType,
  phone $textType,
  region $textType,
  hubs $textType,
  tasksToday $intType,
  status $textType,
  avatar $textNullType
)
''');

    await db.execute('''
CREATE TABLE service_history (
  id $idType,
  customerId $textType,
  date $textType,
  type $textType,
  technicianName $textType,
  notes $textType,
  cost $doubleType,
  partsReplaced $textType,
  FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
