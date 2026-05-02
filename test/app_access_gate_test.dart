import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roapp/features/access/screens/app_access_gate.dart';
import 'package:roapp/features/settings/bloc/settings_cubit.dart';
import 'package:roapp/features/settings/models/app_settings.dart';

void main() {
  testWidgets('shows lock screen when trial is expired and not unlocked', (
    tester,
  ) async {
    final cubit = _TestSettingsCubit()
      ..emitState(
        AppSettings(
          isInitialized: true,
          trialStartedAt: DateTime.now()
              .subtract(const Duration(days: 31))
              .toIso8601String(),
          trialOverrideUnlocked: false,
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<SettingsCubit>.value(
          value: cubit,
          child: const AppAccessGate(),
        ),
      ),
    );

    expect(find.text('30-Day Trial Expired'), findsOneWidget);
    expect(find.text('Unlock App'), findsOneWidget);
  });
}

class _TestSettingsCubit extends SettingsCubit {
  _TestSettingsCubit() : super();

  void emitState(AppSettings settings) {
    emit(settings);
  }
}
