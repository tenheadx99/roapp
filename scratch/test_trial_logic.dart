import 'package:roapp/features/settings/models/app_settings.dart';

void main() {
  final now = DateTime.now();

  // Test Case 1: Fresh installation
  final fresh = AppSettings(trialStartedAt: now.toIso8601String());
  print('--- Test Case 1: Fresh installation ---');
  print('Days remaining: ${fresh.daysRemainingInTrial}'); // Expected 30
  print('Is expired: ${fresh.isTrialExpired}'); // Expected false
  assert(fresh.daysRemainingInTrial == 30);
  assert(!fresh.isTrialExpired);

  // Test Case 2: 15 days in
  final halfWay = AppSettings(
    trialStartedAt: now.subtract(const Duration(days: 15)).toIso8601String(),
  );
  print('\n--- Test Case 2: 15 days in ---');
  print('Days remaining: ${halfWay.daysRemainingInTrial}'); // Expected ~15
  print('Is expired: ${halfWay.isTrialExpired}'); // Expected false
  assert(halfWay.daysRemainingInTrial == 15);
  assert(!halfWay.isTrialExpired);

  // Test Case 3: Exactly 30 days ago (expired)
  final expired = AppSettings(
    trialStartedAt: now.subtract(const Duration(days: 31)).toIso8601String(),
  );
  print('\n--- Test Case 3: 31 days in (expired) ---');
  print('Days remaining: ${expired.daysRemainingInTrial}'); // Expected 0
  print('Is expired: ${expired.isTrialExpired}'); // Expected true
  assert(expired.daysRemainingInTrial == 0);
  assert(expired.isTrialExpired);

  // Test Case 4: Overridden
  final overridden = AppSettings(
    trialStartedAt: now.subtract(const Duration(days: 40)).toIso8601String(),
    trialOverrideUnlocked: true,
  );
  print('\n--- Test Case 4: Expired but overridden ---');
  print('Is expired logic true: ${overridden.isTrialExpired}'); 
  print('Days remaining: ${overridden.daysRemainingInTrial}');
  
  print('\nAll logic tests passed!');
}
