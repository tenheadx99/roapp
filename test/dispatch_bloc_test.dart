import 'package:flutter_test/flutter_test.dart';
import 'package:roapp/features/dispatch/bloc/dispatch_bloc.dart';
import 'package:roapp/features/dispatch/models/service_request.dart';
import 'package:roapp/features/dispatch/repositories/dispatch_repository.dart';

void main() {
  group('DispatchBloc', () {
    test('clears selected date when All Dates is chosen', () async {
      final bloc = DispatchBloc(repository: _FakeDispatchRepository());

      bloc.add(LoadDispatchRequests());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final selectedDate = DateTime(2026, 5, 2);
      bloc.add(SelectDispatchDate(selectedDate));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((bloc.state as DispatchLoaded).selectedDate, selectedDate);

      bloc.add(const SelectDispatchDate(null));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((bloc.state as DispatchLoaded).selectedDate, isNull);

      await bloc.close();
    });
  });
}

class _FakeDispatchRepository extends DispatchRepository {
  @override
  Future<List<ServiceRequest>> getServiceRequests() async {
    return [
      const ServiceRequest(
        id: '1',
        customerName: 'Asha',
        address: 'Rohini',
        type: 'Service',
        model: 'RO Prime',
        time: '10:00 AM',
        status: 'new',
        scheduledFor: '2026-05-02T10:00:00.000',
        technicianName: 'Raj',
        notes: 'Check pressure',
      ),
    ];
  }
}
