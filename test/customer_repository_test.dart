import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
      
      final fetchedAfterUpdate = await customerRepo.getCustomerById(customer.id);
      expect(fetchedAfterUpdate!.name, 'Updated Name');

      // Delete customer
      await customerRepo.deleteCustomer(customer.id);
      final fetchedAfterDelete = await customerRepo.getCustomerById(customer.id);
      expect(fetchedAfterDelete, isNull);
    });
  });
}
