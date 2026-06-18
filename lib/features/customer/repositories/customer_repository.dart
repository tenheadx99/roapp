import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/models/service_history.dart';
import 'package:uuid/uuid.dart';

class CustomerRepository {
  final dbHelper = DatabaseHelper.instance;
  final uuid = const Uuid();

  Future<List<Customer>> getCustomers() async {
    final db = await dbHelper.database;
    final maps = await db.query('customers');
    return maps.map((e) => Customer.fromMap(e)).toList();
  }

  Future<List<String>> getActiveAmcCustomerIds() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'amc_contracts',
      columns: ['customerId'],
      where: 'status = ?',
      whereArgs: ['active'],
    );
    return maps.map((e) => e['customerId'] as String).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addCustomer(Customer customer) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();
    final updatedCustomer = customer.copyWith(updatedAt: nowStr);
    await db.insert('customers', updatedCustomer.toMap());
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await dbHelper.database;
    final nowStr = DateTime.now().toIso8601String();
    final updatedCustomer = customer.copyWith(updatedAt: nowStr);
    await db.update(
      'customers',
      updatedCustomer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Service History
  Future<List<ServiceHistory>> getServiceHistory(String customerId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'service_history',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
    return maps.map((e) => ServiceHistory.fromMap(e)).toList();
  }

  Future<void> addServiceHistory(ServiceHistory history) async {
    final db = await dbHelper.database;
    await db.insert('service_history', history.toMap());
  }

  Future<List<ServiceHistory>> getAllServiceHistory() async {
    final db = await dbHelper.database;
    final maps = await db.query('service_history');
    return maps.map((e) => ServiceHistory.fromMap(e)).toList();
  }
}
