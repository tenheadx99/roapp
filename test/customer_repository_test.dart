import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CustomerRepository Tests', () {
    final customerRepo = CustomerRepository();
    final uuid = const Uuid();

    test('Add, Get, Update, and Delete Customer works', () async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('customers'); // Start clean

      // Add customer
      final customer = Customer(
        id: uuid.v4(),
        name: 'Test Customer',
        phone: '+91 9999999999',
        model: 'Kent Grand+',
        status: 'Operational',
        lastService: 'Never',
        area: 'Rohini',
      );

      await customerRepo.addCustomer(customer);

      // Get customers
      final customers = await customerRepo.getCustomers();
      expect(customers.length, 1);
      expect(customers.first.name, 'Test Customer');

      // Get customer by ID
      final fetched = await customerRepo.getCustomerById(customer.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Test Customer');

      // Update customer
      final updatedCustomer = customer.copyWith(name: 'Updated Name');
      await customerRepo.updateCustomer(updatedCustomer);

      final fetchedAfterUpdate = await customerRepo.getCustomerById(
        customer.id,
      );
      expect(fetchedAfterUpdate!.name, 'Updated Name');

      // Delete customer
      await customerRepo.deleteCustomer(customer.id);
      final fetchedAfterDelete = await customerRepo.getCustomerById(
        customer.id,
      );
      expect(fetchedAfterDelete, isNull);
    });

    test('getActiveAmcCustomerIds returns active customer IDs from amc_contracts', () async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('amc_contracts');
      await db.delete('customers');

      final customerId = uuid.v4();
      final customer = Customer(
        id: customerId,
        name: 'AMC Customer',
        phone: '+91 8888888888',
        model: 'Aquaguard Geneus',
        status: 'Operational',
        lastService: 'Never',
        area: 'Dwarka',
      );
      await customerRepo.addCustomer(customer);

      // Insert active contract
      await db.insert('amc_contracts', {
        'id': uuid.v4(),
        'customerId': customerId,
        'contractName': 'Premium AMC Plan',
        'startDate': DateTime.now().toIso8601String(),
        'endDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'visitsIncluded': 4,
        'visitsUsed': 0,
        'amount': 3500.0,
        'status': 'active',
        'renewalReminderDate': DateTime.now().add(const Duration(days: 330)).toIso8601String(),
      });

      // Insert expired/inactive contract
      final inactiveCustomerId = uuid.v4();
      final inactiveCustomer = Customer(
        id: inactiveCustomerId,
        name: 'Expired Customer',
        phone: '+91 7777777777',
        model: 'Kent Grand+',
        status: 'Operational',
        lastService: 'Never',
        area: 'Rohini',
      );
      await customerRepo.addCustomer(inactiveCustomer);

      await db.insert('amc_contracts', {
        'id': uuid.v4(),
        'customerId': inactiveCustomerId,
        'contractName': 'Expired Plan',
        'startDate': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
        'endDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'visitsIncluded': 4,
        'visitsUsed': 4,
        'amount': 3000.0,
        'status': 'expired',
        'renewalReminderDate': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      });

      final activeIds = await customerRepo.getActiveAmcCustomerIds();
      expect(activeIds, contains(customerId));
      expect(activeIds, isNot(contains(inactiveCustomerId)));
    });
  });
}
