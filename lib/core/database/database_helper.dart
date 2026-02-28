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
  area $textType,
  installationDate $textNullType,
  upcomingServiceDate $textNullType
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

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Customers
    await db.insert('customers', {
      'id': '1',
      'name': 'Arjun Sharma',
      'phone': '+91 98765 43210',
      'model': 'Kent Grand+ RO (12L)',
      'status': 'Service Due',
      'lastService': '15 Oct 2023',
      'area': 'West Delhi',
      'installationDate': '12 Mar 2022',
      'upcomingServiceDate': '15 Apr 2024',
    });
    await db.insert('customers', {
      'id': '2',
      'name': 'Priya Mehra',
      'phone': '+91 88223 11445',
      'model': 'Pureit Copper+ Mineral',
      'status': 'Operational',
      'lastService': '02 Jan 2024',
      'area': 'Rohini',
      'installationDate': '05 Jun 2023',
      'upcomingServiceDate': '02 Jul 2024',
    });

    // Service History for Customer 1
    await db.insert('service_history', {
      'id': 'sh1',
      'customerId': '1',
      'date': 'Oct 24, 2023 • 11:30 AM',
      'type': 'Filter Replacement',
      'technicianName': 'Ravi Kumar',
      'notes': 'Replaced basic filters',
      'cost': 120.00,
      'partsReplaced': 'Sediment Filter, Activated Carbon',
    });

    // Inventory
    await db.insert('inventory', {
      'id': 'r-i-1',
      'name': 'RO Membrane 75 GPD',
      'sku': 'RO-MEM-75',
      'supplier': 'AquaPure Solutions',
      'price': 45.50,
      'stock': 12,
      'lowStockThreshold': 15,
      'category': 'Membranes',
    });

    // Technicians
    await db.insert('technicians', {
      'id': 'tech-1',
      'name': 'Rahul Verma',
      'phone': '+91 98765 43210',
      'region': 'South Delhi',
      'hubs': 'Hub A, Hub B',
      'tasksToday': 4,
      'status': 'online',
    });

    // Supplier
    await db.insert('suppliers', {
      'id': 'sup-1',
      'name': 'AquaPure Solutions',
      'contactPerson': 'Sunil Sharma',
      'city': 'New Delhi',
      'specialties': 'Membranes, Pumps',
      'activePOs': 2,
      'status': 'active',
    });

    // Service Request
    await db.insert('service_requests', {
      'id': 'req-1',
      'customerName': 'Ravi Kumar',
      'address': 'Greater Kailash, Delhi',
      'type': 'Filter Replacement',
      'model': 'Kent Grand+',
      'time': '10:00 AM - 12:00 PM',
      'status': 'new',
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
