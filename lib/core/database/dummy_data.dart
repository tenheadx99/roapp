import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DummyData {
  static final _uuid = const Uuid();
  static final _random = Random();
  static const inventoryCategories = [
    'Membranes',
    'Filters',
    'Pumps',
    'Tubes & Fittings',
    'Adapters',
    'Miscellaneous',
  ];

  static const _firstNames = [
    'Rahul', 'Amit', 'Priya', 'Neha', 'Sandeep', 'Anjali', 'Vikram', 'Rohan',
    'Simran', 'Karan', 'Pooja', 'Sunil', 'Kavita', 'Ravi', 'Sneha', 'Deepak',
    'Megha', 'Nitin', 'Divya', 'Raj', 'Shikha', 'Anand', 'Nisha', 'Vijay',
    'Swati', 'Manish', 'Ritu', 'Suresh', 'Aarti', 'Gaurav', 'Kiran', 'Tarun'
  ];

  static const _lastNames = [
    'Sharma', 'Verma', 'Singh', 'Kumar', 'Kapoor', 'Mehra', 'Gupta', 'Jain',
    'Bansal', 'Agarwal', 'Das', 'Roy', 'Chowdhury', 'Mishra', 'Pandey', 'Tiwari'
  ];

  static const _areas = [
    'Rohini', 'Dwarka', 'Vasant Kunj', 'Karol Bagh', 'Lajpat Nagar', 'Pitampura',
    'South Ex', 'Defense Colony', 'Hauz Khas', 'Greater Kailash', 'Janakpuri',
    'Paschim Vihar', 'Saket', 'Malviya Nagar', 'Rajouri Garden', 'Punjabi Bagh'
  ];

  static const _roModels = [
    'Kent Grand+ RO (12L)', 'Pureit Copper+ Mineral RO', 'Aquaguard Aura RO+UV',
    'Eureka Forbes Aquasure', 'Livpure Glo RO+UV', 'Blue Star Excella',
    'Havells Max Alkaline', 'V-Guard Zenora', 'A.O. Smith Z8', 'Mi Smart Water Purifier'
  ];

  static const _supplierNames = [
    'AquaPure Solutions', 'Kent Tech Parts', 'Livpure Spares',
    'WaterSolutions Inc', 'Pure Water Spares', 'Metro RO Components',
    'Delhi Water Tech', 'Global RO Spares', 'Bharat Aquatics', 'Oceanic Filters'
  ];

  static Future<void> seed(Database db) async {
    final countSqflite = await db.rawQuery('SELECT COUNT(*) FROM customers');
    final count = Sqflite.firstIntValue(countSqflite);
    if (count != null && count > 0) return; // Already seeded

    await _seedSuppliers(db);
    await _seedProductCategories(db);
    await _seedInventory(db);
    await _seedTechnicians(db);
    await _seedCustomers(db);
  }

  static Future<void> _seedProductCategories(Database db) async {
    const productCategories = [
      'Filters',
      'Membranes',
      'Pumps',
      'UV Lamps',
      'Other',
      'Tubes & Fittings',
      'Adapters',
      'Miscellaneous',
    ];

    for (final category in productCategories) {
      await db.insert('product_categories', {
        'id': 'cat-${category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
        'name': category,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> _seedSuppliers(Database db) async {
    for (int i = 0; i < 10; i++) {
      await db.insert('suppliers', {
        'id': 'sup-${_uuid.v4()}',
        'name': _supplierNames[i % _supplierNames.length] + (i >= _supplierNames.length ? ' $i' : ''),
        'contactPerson': '${_randomElement(_firstNames)} ${_randomElement(_lastNames)}',
        'city': 'New Delhi',
        'specialties': 'Membranes, Pumps, Filters',
        'activePOs': _random.nextInt(5),
        'status': _random.nextDouble() > 0.1 ? 'active' : 'inactive',
        'phone': '+91 98${(_random.nextInt(90000000) + 10000000).toString()}',
        'email': 'sales${i + 1}@${_supplierNames[i % _supplierNames.length].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '')}.com',
      });
    }
  }

  static Future<void> _seedInventory(Database db) async {
    // Generate at least 100 items
    int itemCount = 0;
    while (itemCount < 105) {
      final category = _randomElement(inventoryCategories);
      String name = '';
      double mrp = 0;
      double price = 0;
      
      switch (category) {
        case 'Membranes':
          name = 'RO Membrane ${_random.nextInt(3) * 25 + 50} GPD (${_randomElement(['Kent', 'LG', 'CSM', 'Dow'])})';
          price = 40.0 + _random.nextDouble() * 100;
          mrp = price * 1.5;
          break;
        case 'Filters':
          name = '${_randomElement(['Sediment', 'Carbon', 'Pre-Carbon', 'Post-Carbon', 'UF'])} Filter (${_randomElement(['10 inch', 'Inline', 'Spun'])})';
          price = 5.0 + _random.nextDouble() * 20;
          mrp = price * 1.8;
          break;
        case 'Pumps':
          name = 'Booster Pump ${_randomElement(['75 GPD', '100 GPD', '150 GPD'])} (${_randomElement(['Kemflo', 'Grand Forest', 'BNQS'])})';
          price = 35.0 + _random.nextDouble() * 60;
          mrp = price * 1.4;
          break;
        case 'Tubes & Fittings':
          name = '${_randomElement(['1/4 inch', '3/8 inch'])} ${_randomElement(['T-Fitting', 'L-Fitting', 'Pipe Roll (100m)', 'Valve'])}';
          price = 1.0 + _random.nextDouble() * 15;
          mrp = price * 2.0;
          break;
        case 'Adapters':
          name = 'Power Adapter ${_randomElement(['24V 1.5A', '24V 2.5A', '36V 2A'])}';
          price = 10.0 + _random.nextDouble() * 25;
          mrp = price * 1.6;
          break;
        case 'Miscellaneous':
          name = '${_randomElement(['Teflon Tape', 'Filter Key', 'Float Valve', 'Flow Restrictor', 'Solenoid Valve (SV)'])}';
          price = 0.5 + _random.nextDouble() * 10;
          mrp = price * 2.5;
          break;
      }

      // Add a variant identifier to ensure unique names in our mind (though not strictly enforced by SQLite)
      name += ' - Var${_random.nextInt(1000)}';

      await db.insert('inventory', {
        'id': 'inv-${_uuid.v4()}',
        'name': name,
        'mrp': num.parse(mrp.toStringAsFixed(2)),
        'supplier': _randomElement(_supplierNames),
        'price': num.parse(price.toStringAsFixed(2)),
        'stock': _random.nextInt(100) + 10,
        'lowStockThreshold': 15,
        'category': category,
      });

      itemCount++;
    }
  }

  static Future<void> _seedTechnicians(Database db) async {
    for (int i = 0; i < 10; i++) {
      await db.insert('technicians', {
        'id': 'tech-${_uuid.v4()}',
        'name': '${_randomElement(_firstNames)} ${_randomElement(_lastNames)}',
        'phone': '+91 9${_random.nextInt(899999999) + 100000000}',
        'region': _randomElement(['South Delhi', 'North Delhi', 'East Delhi', 'West Delhi', 'Central Delhi']),
        'hubs': 'Hub-${String.fromCharCode(65 + _random.nextInt(5))}, Hub-${String.fromCharCode(65 + _random.nextInt(5))}',
        'tasksToday': _random.nextInt(8),
        'status': _random.nextDouble() > 0.2 ? 'online' : (_random.nextDouble() > 0.5 ? 'offline' : 'on-leave'),
      });
    }
  }

  static Future<void> _seedCustomers(Database db) async {
    final statuses = ['Service Due', 'Operational', 'AMC Plan', 'Pending Install'];
    
    // We already have 2 customers maybe? In `database_helper.dart` we might wipe and just use this instead.
    for (int i = 0; i < 50; i++) {
      final customerId = 'cust-${_uuid.v4()}';
      final isInstalled = _random.nextDouble() > 0.1; // 90% are installed
      final installationDate = isInstalled ? _randomDateInPast(730) : null;
      final status = statuses[_random.nextInt(statuses.length)];
      
      final cName = '${_randomElement(_firstNames)} ${_randomElement(_lastNames)}';

      await db.insert('customers', {
        'id': customerId,
        'name': cName,
        'phone': '+91 9${_random.nextInt(899999999) + 100000000}',
        'model': _randomElement(_roModels),
        'status': status,
        'lastService': isInstalled ? _formatDate(_randomDateInPast(180)) : 'Never',
        'area': _randomElement(_areas),
        'installationDate': installationDate != null ? _formatDate(installationDate) : null,
        'upcomingServiceDate': isInstalled ? _formatDate(_randomDateInFuture(90)) : null,
      });

      // Add Service requests/history if installed
      if (isInstalled && _random.nextBool()) {
        await db.insert('service_history', {
          'id': 'sh-${_uuid.v4()}',
          'customerId': customerId,
          'date': _formatDateAndTime(_randomDateInPast(180)),
          'type': _randomElement(['Filter Replacement', 'General Service', 'Motor Repair', 'Leakage Fix']),
          'technicianName': '${_randomElement(_firstNames)} ${_randomElement(_lastNames)}',
          'notes': 'Routine maintenance check completed.',
          'cost': (50 + _random.nextInt(200)).toDouble(),
          'partsReplaced': _randomElement(['None', 'Sediment Filter', 'Carbon Filter', 'RO Membrane', 'Solenoid Valve']),
        });
      }
      
      // Some pending service requests
      if (status == 'Service Due' || status == 'Pending Install') {
         final scheduledFor = _randomDateInFuture(14);
         await db.insert('service_requests', {
          'id': 'req-${_uuid.v4()}',
          'customerName': cName,
          'address': _randomElement(_areas),
          'type': status == 'Pending Install' ? 'Installation' : 'Regular Service',
          'model': _randomElement(_roModels),
          'time': _formatDateAndTime(scheduledFor),
          'status': 'new',
          'scheduledFor': scheduledFor.toIso8601String(),
          'technicianName': null,
          'notes': status == 'Pending Install'
              ? 'Customer requested installation confirmation in advance.'
              : 'Carry standard service kit and TDS meter.',
        });
      }
    }
  }

  static String _randomElement(List<String> list) {
    return list[_random.nextInt(list.length)];
  }

  static DateTime _randomDateInPast(int maxDaysAgo) {
    final daysAgo = _random.nextInt(maxDaysAgo);
    return DateTime.now().subtract(Duration(days: daysAgo));
  }

  static DateTime _randomDateInFuture(int maxDaysAhead) {
    final daysAhead = _random.nextInt(maxDaysAhead);
    return DateTime.now().add(Duration(days: daysAhead));
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
  
  static String _formatDateAndTime(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    int hour = date.hour;
    String period = 'AM';
    if (hour >= 12) {
      period = 'PM';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;
    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
