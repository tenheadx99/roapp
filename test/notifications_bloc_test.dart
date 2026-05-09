import 'package:flutter_test/flutter_test.dart';
import 'package:roapp/features/customer/models/customer.dart';
import 'package:roapp/features/customer/repositories/customer_repository.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:roapp/features/dispatch/repositories/dispatch_repository.dart';
import 'package:roapp/features/inventory/models/inventory_item.dart';
import 'package:roapp/features/inventory/repositories/inventory_repository.dart';
import 'package:roapp/features/notifications/bloc/notifications_bloc.dart';
import 'package:roapp/features/settings/models/app_settings.dart';
import 'package:roapp/features/settings/repositories/settings_repository.dart';

void main() {
  group('NotificationsBloc', () {
    test('adds 3-month and 6-month customer service reminders', () async {
      final bloc = NotificationsBloc(
        inventoryRepository: _FakeInventoryRepository(),
        dispatchRepository: _FakeDispatchRepository(),
        customerRepository: _FakeCustomerRepository([
          const Customer(
            id: 'customer-3',
            name: 'Asha',
            phone: '9999999999',
            model: 'Kent Grand+',
            status: 'Operational',
            lastService: '2026-02-04',
            area: 'Rohini',
          ),
          const Customer(
            id: 'customer-6',
            name: 'Mohan',
            phone: '8888888888',
            model: 'Aquaguard Blaze',
            status: 'Operational',
            lastService: '2025-11-06',
            area: 'Pitampura',
          ),
          const Customer(
            id: 'customer-due',
            name: 'Rekha',
            phone: '7777777777',
            model: 'Livpure Bolt',
            status: 'Service Due',
            lastService: '2026-02-04',
            area: 'Dwarka',
          ),
        ]),
        settingsRepository: _FakeSettingsRepository(),
        nowProvider: () => DateTime(2026, 5, 5),
      );

      final expected = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<NotificationsLoading>(),
          predicate<NotificationsState>((state) {
            if (state is! NotificationsLoaded) {
              return false;
            }

            final titles = state.allNotifications
                .map((notification) => notification['title'] as String)
                .toList();
            final reminderForDueCustomer = state.allNotifications.where(
              (notification) => notification['id'] == 'customer-customer-due',
            );

            return titles.contains('3-Month Service Reminder') &&
                titles.contains('6-Month Service Reminder') &&
                reminderForDueCustomer.isEmpty;
          }),
        ]),
      );

      bloc.add(LoadNotifications());

      await expected;
      await bloc.close();
    });
  });
}

class _FakeInventoryRepository extends InventoryRepository {
  @override
  Future<List<InventoryItem>> getInventory() async => const [];
}

class _FakeDispatchRepository extends DispatchRepository {
  @override
  Future<List<ServiceRequest>> getServiceRequests() async => const [];
}

class _FakeCustomerRepository extends CustomerRepository {
  final List<Customer> customers;

  _FakeCustomerRepository(this.customers);

  @override
  Future<List<Customer>> getCustomers() async => customers;
}

class _FakeSettingsRepository extends SettingsRepository {
  @override
  Future<AppSettings> loadSettings() async =>
      const AppSettings(notificationsEnabled: true, isInitialized: true);
}
