import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:roapp/features/dispatch/repositories/dispatch_repository.dart';
import 'package:roapp/features/operations/models/amc_contract.dart';
import 'package:roapp/features/operations/repositories/operations_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.dbName = 'roapp_test_amc_contract.db';
  });

  group('AMC contract behaviour', () {
    final customerRepo = CustomerRepository();
    final dispatchRepo = DispatchRepository();
    final operationsRepo = OperationsRepository();
    final uuid = const Uuid();

    late Database db;
    late Customer customer;

    Future<AmcContract> insertContract({
      required String status,
      DateTime? endDate,
      int visitsIncluded = 4,
      int visitsUsed = 0,
    }) async {
      final end = endDate ?? DateTime.now().add(const Duration(days: 180));
      final contract = AmcContract(
        id: uuid.v4(),
        customerId: customer.id,
        contractName: 'Test AMC',
        startDate: DateTime.now()
            .subtract(const Duration(days: 30))
            .toIso8601String(),
        endDate: end.toIso8601String(),
        visitsIncluded: visitsIncluded,
        visitsUsed: visitsUsed,
        amount: 2999,
        status: status,
        renewalReminderDate: end
            .subtract(const Duration(days: 30))
            .toIso8601String(),
      );
      await operationsRepo.upsertContract(contract);
      return contract;
    }

    Future<int> visitsUsedOf(String contractId) async {
      final rows = await db.query(
        'amc_contracts',
        where: 'id = ?',
        whereArgs: [contractId],
      );
      return rows.first['visitsUsed'] as int;
    }

    setUp(() async {
      db = await DatabaseHelper.instance.database;
      await db.delete('service_requests');
      await db.delete('service_history');
      await db.delete('amc_contracts');
      await db.delete('customers');

      customer = Customer(
        id: uuid.v4(),
        name: 'AMC Test Customer',
        phone: '+91 9999999999',
        model: 'Kent Grand+',
        status: 'AMC Plan',
        lastService: 'Never',
        area: 'Rohini',
      );
      await customerRepo.addCustomer(customer);
    });

    test('completing a service deducts exactly one AMC visit', () async {
      final contract = await insertContract(status: 'active');

      final request = ServiceRequest(
        id: uuid.v4(),
        customerId: customer.id,
        customerName: customer.name,
        address: 'Test Address',
        type: 'AMC Service',
        model: customer.model,
        time: '10:00 AM',
        status: 'new',
      );
      await dispatchRepo.addServiceRequest(request);
      await dispatchRepo.updateServiceRequest(
        request.copyWith(status: 'completed'),
      );

      expect(await visitsUsedOf(contract.id), 1);
    });

    test('re-reading requests does not deduct visits again', () async {
      final contract = await insertContract(status: 'active');

      final request = ServiceRequest(
        id: uuid.v4(),
        customerId: customer.id,
        customerName: customer.name,
        address: 'Test Address',
        type: 'AMC Service',
        model: customer.model,
        time: '10:00 AM',
        status: 'completed',
      );
      await dispatchRepo.addServiceRequest(request);
      expect(await visitsUsedOf(contract.id), 1);

      // Every read used to re-run the completion sync and inflate visitsUsed.
      await dispatchRepo.getServiceRequests();
      await dispatchRepo.getServiceRequests();
      await dispatchRepo.getServiceRequestsByCustomer(customerId: customer.id);

      expect(await visitsUsedOf(contract.id), 1);
    });

    test('non-AMC service types do not consume visits', () async {
      final contract = await insertContract(status: 'active');

      final request = ServiceRequest(
        id: uuid.v4(),
        customerId: customer.id,
        customerName: customer.name,
        address: 'Test Address',
        type: 'Repair',
        model: customer.model,
        time: '10:00 AM',
        status: 'completed',
      );
      await dispatchRepo.addServiceRequest(request);

      expect(await visitsUsedOf(contract.id), 0);
    });

    test('date-expired contract does not consume visits', () async {
      final contract = await insertContract(
        status: 'active',
        endDate: DateTime.now().subtract(const Duration(days: 10)),
      );

      final request = ServiceRequest(
        id: uuid.v4(),
        customerId: customer.id,
        customerName: customer.name,
        address: 'Test Address',
        type: 'AMC Service',
        model: customer.model,
        time: '10:00 AM',
        status: 'completed',
      );
      await dispatchRepo.addServiceRequest(request);

      expect(await visitsUsedOf(contract.id), 0);
    });

    test('getActiveAmcCustomerIds ignores expired and date-expired contracts',
        () async {
      await insertContract(status: 'active');
      final ids = await customerRepo.getActiveAmcCustomerIds();
      expect(ids, contains(customer.id));

      await db.delete('amc_contracts');
      await insertContract(
        status: 'active',
        endDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(await customerRepo.getActiveAmcCustomerIds(), isEmpty);

      await db.delete('amc_contracts');
      await insertContract(status: 'expired');
      expect(await customerRepo.getActiveAmcCustomerIds(), isEmpty);
    });

    test('getContracts lazily expires active contracts past their end date',
        () async {
      final stale = await insertContract(
        status: 'active',
        endDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      final current = await insertContract(status: 'active');

      final contracts = await operationsRepo.getContracts(
        customerId: customer.id,
      );
      final byId = {for (final c in contracts) c.id: c};

      expect(byId[stale.id]!.status, 'expired');
      expect(byId[current.id]!.status, 'active');
    });

    test('visits never exceed visitsIncluded', () async {
      final contract = await insertContract(
        status: 'active',
        visitsIncluded: 1,
        visitsUsed: 1,
      );

      final request = ServiceRequest(
        id: uuid.v4(),
        customerId: customer.id,
        customerName: customer.name,
        address: 'Test Address',
        type: 'AMC Service',
        model: customer.model,
        time: '10:00 AM',
        status: 'completed',
      );
      await dispatchRepo.addServiceRequest(request);

      expect(await visitsUsedOf(contract.id), 1);
    });
  });
}
