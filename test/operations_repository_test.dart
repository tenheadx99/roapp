import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:roapp/core/database/database_helper.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/operations/models/amc_contract.dart';
import 'package:roapp/features/operations/models/invoice.dart';
import 'package:roapp/features/operations/models/purchase_order.dart';
import 'package:roapp/features/operations/repositories/operations_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseHelper.dbName = 'roapp_test_operations_repository.db';
  });

  group('OperationsRepository', () {
    final repo = OperationsRepository();
    final customerRepo = CustomerRepository();
    final uuid = const Uuid();

    late Database db;
    late Customer customer;

    setUp(() async {
      db = await DatabaseHelper.instance.database;
      await db.delete('purchase_orders');
      await db.delete('invoices');
      await db.delete('amc_contracts');
      await db.delete('inventory');
      await db.delete('suppliers');
      await db.delete('customers');

      customer = Customer(
        id: uuid.v4(),
        name: 'Ops Test Customer',
        phone: '+91 9999999999',
        model: 'Kent Grand+',
        status: 'Operational',
        lastService: 'Never',
        area: 'Rohini',
      );
      await customerRepo.addCustomer(customer);
    });

    group('markPurchaseOrderReceived', () {
      late String supplierId;
      late String inventoryItemId;

      setUp(() async {
        supplierId = uuid.v4();
        await db.insert('suppliers', {
          'id': supplierId,
          'name': 'Test Supplier',
          'contactPerson': 'Contact',
          'city': 'Delhi',
          'specialties': 'Filters',
          'activePOs': 1,
          'status': 'active',
        });

        inventoryItemId = uuid.v4();
        await db.insert('inventory', {
          'id': inventoryItemId,
          'name': 'Sediment Filter',
          'mrp': 500.0,
          'supplier': 'Test Supplier',
          'price': 400.0,
          'supplierPrice': 250.0,
          'stock': 10,
          'lowStockThreshold': 5,
          'category': 'Filters',
        });
      });

      Future<int> stockOf(String id) async {
        final rows = await db.query(
          'inventory',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [id],
        );
        return rows.first['stock'] as int;
      }

      PurchaseOrder buildOrder({String status = 'ordered'}) {
        return PurchaseOrder(
          id: uuid.v4(),
          supplierId: supplierId,
          poNumber: 'PO-1001',
          createdAt: DateTime.now().toIso8601String(),
          expectedDate: DateTime.now()
              .add(const Duration(days: 7))
              .toIso8601String(),
          receivedDate: null,
          status: status,
          totalAmount: 3000,
          leadDays: 7,
          notes: '',
          items: [
            PurchaseOrderItem(
              inventoryItemId: inventoryItemId,
              name: 'Sediment Filter',
              quantity: 12,
              unitCost: 250,
            ),
          ],
        );
      }

      test('receiving a PO increments stock for its line items', () async {
        final order = buildOrder();
        await repo.upsertPurchaseOrder(order);

        final transitioned = await repo.markPurchaseOrderReceived(order.id);

        expect(transitioned, isTrue);
        expect(await stockOf(inventoryItemId), 22);

        final stored = (await repo.getPurchaseOrders()).single;
        expect(stored.status, 'received');
        expect(stored.receivedDate, isNotNull);
        expect(stored.items.single.quantity, 12);
      });

      test('receiving twice does not double stock', () async {
        final order = buildOrder();
        await repo.upsertPurchaseOrder(order);

        await repo.markPurchaseOrderReceived(order.id);
        final second = await repo.markPurchaseOrderReceived(order.id);

        expect(second, isFalse);
        expect(await stockOf(inventoryItemId), 22);
      });

      test('line items without an inventory link leave stock alone', () async {
        final order = PurchaseOrder(
          id: uuid.v4(),
          supplierId: supplierId,
          poNumber: 'PO-1002',
          createdAt: DateTime.now().toIso8601String(),
          expectedDate: DateTime.now().toIso8601String(),
          receivedDate: null,
          status: 'ordered',
          totalAmount: 500,
          leadDays: 3,
          notes: '',
          items: const [
            PurchaseOrderItem(name: 'Unlinked Part', quantity: 5, unitCost: 100),
          ],
        );
        await repo.upsertPurchaseOrder(order);

        await repo.markPurchaseOrderReceived(order.id);

        expect(await stockOf(inventoryItemId), 10);
      });
    });

    group('recordInvoicePayment', () {
      Invoice buildInvoice({double total = 1000, double paid = 0}) {
        return Invoice(
          id: uuid.v4(),
          customerId: customer.id,
          invoiceNumber: 'INV-1',
          issueDate: DateTime.now().toIso8601String(),
          dueDate: DateTime.now()
              .add(const Duration(days: 15))
              .toIso8601String(),
          totalAmount: total,
          paidAmount: paid,
          supplierPrice: 0,
          status: 'due',
          notes: '',
        );
      }

      test('partial payment keeps invoice due', () async {
        final invoice = buildInvoice();
        await repo.upsertInvoice(invoice);

        final updated = await repo.recordInvoicePayment(invoice.id, 400);

        expect(updated!.paidAmount, 400);
        expect(updated.status, 'due');
      });

      test('full payment marks invoice paid and caps at total', () async {
        final invoice = buildInvoice(paid: 900);
        await repo.upsertInvoice(invoice);

        final updated = await repo.recordInvoicePayment(invoice.id, 500);

        expect(updated!.paidAmount, 1000);
        expect(updated.status, 'paid');
      });

      test('unknown invoice returns null', () async {
        expect(await repo.recordInvoicePayment('missing', 100), isNull);
      });
    });

    group('renewContract', () {
      test('renewal starts where the old contract ended with visits reset',
          () async {
        final start = DateTime.now().subtract(const Duration(days: 330));
        final end = DateTime.now().add(const Duration(days: 35));
        final contract = AmcContract(
          id: uuid.v4(),
          customerId: customer.id,
          contractName: 'Gold AMC',
          startDate: start.toIso8601String(),
          endDate: end.toIso8601String(),
          visitsIncluded: 4,
          visitsUsed: 3,
          amount: 2999,
          status: 'active',
          renewalReminderDate: DateTime.now().toIso8601String(),
        );
        await repo.upsertContract(contract);

        final renewed = await repo.renewContract(contract);

        expect(renewed.customerId, customer.id);
        expect(renewed.visitsUsed, 0);
        expect(renewed.visitsIncluded, 4);
        expect(renewed.amount, 2999);
        expect(renewed.status, 'active');
        expect(DateTime.parse(renewed.startDate), DateTime.parse(contract.endDate));
        expect(
          DateTime.parse(renewed.endDate)
              .difference(DateTime.parse(renewed.startDate))
              .inDays,
          end.difference(start).inDays,
        );

        final all = await repo.getContracts(customerId: customer.id);
        expect(all.length, 2);
      });

      test('renewing an already-expired contract starts today', () async {
        final contract = AmcContract(
          id: uuid.v4(),
          customerId: customer.id,
          contractName: 'Lapsed AMC',
          startDate: DateTime.now()
              .subtract(const Duration(days: 400))
              .toIso8601String(),
          endDate: DateTime.now()
              .subtract(const Duration(days: 35))
              .toIso8601String(),
          visitsIncluded: 4,
          visitsUsed: 4,
          amount: 2499,
          status: 'expired',
          renewalReminderDate: DateTime.now()
              .subtract(const Duration(days: 65))
              .toIso8601String(),
        );
        await repo.upsertContract(contract);

        final renewed = await repo.renewContract(contract);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        expect(DateTime.parse(renewed.startDate), today);
        expect(renewed.status, 'active');
      });
    });
  });
}
