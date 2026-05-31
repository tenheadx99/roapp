import 'dart:convert';
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
    'Rahul',
    'Amit',
    'Priya',
    'Neha',
    'Sandeep',
    'Anjali',
    'Vikram',
    'Rohan',
    'Simran',
    'Karan',
    'Pooja',
    'Sunil',
    'Kavita',
    'Ravi',
    'Sneha',
    'Deepak',
    'Megha',
    'Nitin',
    'Divya',
    'Raj',
    'Shikha',
    'Anand',
    'Nisha',
    'Vijay',
    'Swati',
    'Manish',
    'Ritu',
    'Suresh',
    'Aarti',
    'Gaurav',
    'Kiran',
    'Tarun',
  ];

  static const _lastNames = [
    'Sharma',
    'Verma',
    'Singh',
    'Kumar',
    'Kapoor',
    'Mehra',
    'Gupta',
    'Jain',
    'Bansal',
    'Agarwal',
    'Das',
    'Roy',
    'Chowdhury',
    'Mishra',
    'Pandey',
    'Tiwari',
  ];

  static const _areas = [
    'Rohini',
    'Dwarka',
    'Vasant Kunj',
    'Karol Bagh',
    'Lajpat Nagar',
    'Pitampura',
    'South Ex',
    'Defense Colony',
    'Hauz Khas',
    'Greater Kailash',
    'Janakpuri',
    'Paschim Vihar',
    'Saket',
    'Malviya Nagar',
    'Rajouri Garden',
    'Punjabi Bagh',
  ];

  static const _roModels = [
    'Kent Grand+ RO (12L)',
    'Pureit Copper+ Mineral RO',
    'Aquaguard Aura RO+UV',
    'Eureka Forbes Aquasure',
    'Livpure Glo RO+UV',
    'Blue Star Excella',
    'Havells Max Alkaline',
    'V-Guard Zenora',
    'A.O. Smith Z8',
    'Mi Smart Water Purifier',
  ];

  static const _supplierNames = [
    'AquaPure Solutions',
    'Kent Tech Parts',
    'Livpure Spares',
    'WaterSolutions Inc',
    'Pure Water Spares',
    'Metro RO Components',
    'Delhi Water Tech',
    'Global RO Spares',
    'Bharat Aquatics',
    'Oceanic Filters',
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
        'id':
            'cat-${category.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
        'name': category,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<void> _seedSuppliers(Database db) async {
    for (int i = 0; i < 10; i++) {
      await db.insert('suppliers', {
        'id': 'sup-${_uuid.v4()}',
        'name':
            _supplierNames[i % _supplierNames.length] +
            (i >= _supplierNames.length ? ' $i' : ''),
        'contactPerson':
            '${_randomElement(_firstNames)} ${_randomElement(_lastNames)}',
        'city': 'New Delhi',
        'specialties': 'Membranes, Pumps, Filters',
        'activePOs': _random.nextInt(5),
        'status': _random.nextDouble() > 0.1 ? 'active' : 'inactive',
        'phone': '+91 98${(_random.nextInt(90000000) + 10000000).toString()}',
        'email':
            'sales${i + 1}@${_supplierNames[i % _supplierNames.length].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '')}.com',
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
          name =
              'RO Membrane ${_random.nextInt(3) * 25 + 50} GPD (${_randomElement(['Kent', 'LG', 'CSM', 'Dow'])})';
          price = 40.0 + _random.nextDouble() * 100;
          mrp = price * 1.5;
          break;
        case 'Filters':
          name =
              '${_randomElement(['Sediment', 'Carbon', 'Pre-Carbon', 'Post-Carbon', 'UF'])} Filter (${_randomElement(['10 inch', 'Inline', 'Spun'])})';
          price = 5.0 + _random.nextDouble() * 20;
          mrp = price * 1.8;
          break;
        case 'Pumps':
          name =
              'Booster Pump ${_randomElement(['75 GPD', '100 GPD', '150 GPD'])} (${_randomElement(['Kemflo', 'Grand Forest', 'BNQS'])})';
          price = 35.0 + _random.nextDouble() * 60;
          mrp = price * 1.4;
          break;
        case 'Tubes & Fittings':
          name =
              '${_randomElement(['1/4 inch', '3/8 inch'])} ${_randomElement(['T-Fitting', 'L-Fitting', 'Pipe Roll (100m)', 'Valve'])}';
          price = 1.0 + _random.nextDouble() * 15;
          mrp = price * 2.0;
          break;
        case 'Adapters':
          name =
              'Power Adapter ${_randomElement(['24V 1.5A', '24V 2.5A', '36V 2A'])}';
          price = 10.0 + _random.nextDouble() * 25;
          mrp = price * 1.6;
          break;
        case 'Miscellaneous':
          name = _randomElement([
            'Teflon Tape',
            'Filter Key',
            'Float Valve',
            'Flow Restrictor',
            'Solenoid Valve (SV)',
          ]);
          price = 0.5 + _random.nextDouble() * 10;
          mrp = price * 2.5;
          break;
      }

      // Add a variant identifier to ensure unique names in our mind (though not strictly enforced by SQLite)
      name += ' - Var${_random.nextInt(1000)}';

      final supplierPrice = price * 0.7;

      await db.insert('inventory', {
        'id': 'inv-${_uuid.v4()}',
        'name': name,
        'mrp': num.parse(mrp.toStringAsFixed(2)),
        'supplier': _randomElement(_supplierNames),
        'price': num.parse(price.toStringAsFixed(2)),
        'supplierPrice': num.parse(supplierPrice.toStringAsFixed(2)),
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
        'region': _randomElement([
          'South Delhi',
          'North Delhi',
          'East Delhi',
          'West Delhi',
          'Central Delhi',
        ]),
        'hubs':
            'Hub-${String.fromCharCode(65 + _random.nextInt(5))}, Hub-${String.fromCharCode(65 + _random.nextInt(5))}',
        'tasksToday': _random.nextInt(8),
        'status': _random.nextDouble() > 0.2
            ? 'online'
            : (_random.nextDouble() > 0.5 ? 'offline' : 'on-leave'),
      });
    }
  }

  static Future<void> _seedCustomers(Database db) async {
    final technicianMaps = await db.query('technicians');
    final technicians = technicianMaps
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    for (int i = 0; i < 36; i++) {
      final customerId = 'cust-${_uuid.v4()}';
      final isInstalled = _random.nextDouble() > 0.12;
      final installationDate = isInstalled ? _randomDateInPast(730) : null;
      final area = _randomElement(_areas);
      final model = _randomElement(_roModels);
      final cName =
          '${_randomElement(_firstNames)} ${_randomElement(_lastNames)}';

      final completedServiceDates = <DateTime>[];
      if (isInstalled) {
        final visitCount = 1 + _random.nextInt(3);
        for (int visit = 0; visit < visitCount; visit++) {
          completedServiceDates.add(
            DateTime.now().subtract(
              Duration(days: 40 + (visit * 75) + _random.nextInt(35)),
            ),
          );
        }
        completedServiceDates.sort();
      }

      final lastCompletedService = completedServiceDates.isEmpty
          ? null
          : completedServiceDates.last;
      final status = _deriveCustomerStatus(isInstalled, lastCompletedService);
      final upcomingServiceDate = _deriveUpcomingServiceDate(
        status,
        lastCompletedService,
      );

      await db.insert('customers', {
        'id': customerId,
        'name': cName,
        'phone': '+91 9${_random.nextInt(899999999) + 100000000}',
        'model': model,
        'status': status,
        'lastService': lastCompletedService == null
            ? 'Never'
            : _formatDate(lastCompletedService),
        'area': area,
        'installationDate': installationDate != null
            ? _formatDate(installationDate)
            : null,
        'upcomingServiceDate': upcomingServiceDate == null
            ? null
            : _formatDate(upcomingServiceDate),
      });

      for (final visitDate in completedServiceDates) {
        final serviceType = _randomElement([
          'Filter Replacement',
          'General Service',
          'Motor Repair',
          'Leakage Fix',
          'TDS Adjustment',
        ]);
        final partsReplaced = _randomElement([
          'None',
          'Sediment Filter',
          'Carbon Filter',
          'RO Membrane',
          'Solenoid Valve',
          'Sediment Filter, Carbon Filter',
        ]);
        final note = _randomElement([
          'Routine maintenance completed and water pressure tested.',
          'Changed filters, flushed the unit, and verified TDS output.',
          'Leakage fixed, pipe joints tightened, and purifier sanitized.',
          'Motor performance inspected and customer advised for next visit.',
        ]);
        final requestId = 'req-${_uuid.v4()}';
        final technician = technicians.isEmpty
            ? null
            : technicians[_random.nextInt(technicians.length)];
        final serviceAmount = (350 + _random.nextInt(1650)).toDouble();

        await db.insert('service_requests', {
          'id': requestId,
          'customerId': customerId,
          'customerName': cName,
          'address': area,
          'type': serviceType,
          'model': model,
          'time': _formatDateAndTime(visitDate),
          'status': 'completed',
          'scheduledFor': visitDate
              .subtract(Duration(days: _random.nextInt(2) + 1))
              .toIso8601String(),
          'completedAt': visitDate.toIso8601String(),
          'technicianId': technician?['id'] as String?,
          'technicianName': technician?['name'] as String?,
          'notes': note,
          'inventoryItems': jsonEncode(const []),
          'totalAmount': serviceAmount,
        });

        await db.insert('service_history', {
          'id': 'sh-${_uuid.v4()}',
          'customerId': customerId,
          'serviceRequestId': requestId,
          'date': _formatDateAndTime(visitDate),
          'type': serviceType,
          'technicianName':
              (technician?['name'] as String?) ??
              '${_randomElement(_firstNames)} ${_randomElement(_lastNames)}',
          'notes': note,
          'cost': serviceAmount,
          'partsReplaced': partsReplaced,
        });
      }

      final openRequestCount = _shouldAddUpcomingRequest(status)
          ? 1 + _random.nextInt(status == 'Service Due' ? 2 : 1)
          : 0;
      for (
        int requestIndex = 0;
        requestIndex < openRequestCount;
        requestIndex++
      ) {
        final scheduledFor = status == 'Service Due'
            ? DateTime.now().add(Duration(days: _random.nextInt(5)))
            : _randomDateInFuture(21);
        final requestStatus = _deriveOpenRequestStatus(status);
        final technician = requestStatus == 'new' || technicians.isEmpty
            ? null
            : technicians[_random.nextInt(technicians.length)];
        final requestType = status == 'Pending Install'
            ? 'New Installation'
            : _randomElement([
                'Routine Service',
                'Filter Replacement',
                'Water Leakage Check',
                'AMC Visit',
              ]);

        await db.insert('service_requests', {
          'id': 'req-${_uuid.v4()}',
          'customerId': customerId,
          'customerName': cName,
          'address': area,
          'type': requestType,
          'model': model,
          'time': _formatDateAndTime(scheduledFor),
          'status': requestStatus,
          'scheduledFor': scheduledFor.toIso8601String(),
          'completedAt': null,
          'technicianId': technician?['id'] as String?,
          'technicianName': technician?['name'] as String?,
          'notes': status == 'Pending Install'
              ? 'Customer requested installation confirmation in advance.'
              : 'Carry standard service kit and TDS meter.',
          'inventoryItems': jsonEncode(const []),
          'totalAmount': requestType == 'New Installation' ? 1499.0 : 599.0,
        });
      }
    }
  }

  static String _deriveCustomerStatus(
    bool isInstalled,
    DateTime? lastCompletedService,
  ) {
    if (!isInstalled) return 'Pending Install';
    if (lastCompletedService == null) return 'Service Due';

    final daysSinceLastService = DateTime.now()
        .difference(lastCompletedService)
        .inDays;
    if (daysSinceLastService >= 160) return 'Service Due';
    if (_random.nextDouble() > 0.65) return 'AMC Plan';
    return 'Operational';
  }

  static DateTime? _deriveUpcomingServiceDate(
    String status,
    DateTime? lastCompletedService,
  ) {
    if (status == 'Pending Install') {
      return DateTime.now().add(Duration(days: 1 + _random.nextInt(10)));
    }
    if (lastCompletedService == null) return null;

    if (status == 'Service Due') {
      return lastCompletedService.add(Duration(days: 90 + _random.nextInt(35)));
    }

    return lastCompletedService.add(Duration(days: 70 + _random.nextInt(35)));
  }

  static bool _shouldAddUpcomingRequest(String status) {
    if (status == 'Pending Install' || status == 'Service Due') {
      return true;
    }
    return _random.nextDouble() > 0.7;
  }

  static String _deriveOpenRequestStatus(String status) {
    if (status == 'Pending Install') return _randomElement(['new', 'assigned']);
    if (status == 'Service Due') {
      return _randomElement(['new', 'assigned', 'in_progress']);
    }
    return _randomElement(['assigned', 'in_progress']);
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatDateAndTime(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
