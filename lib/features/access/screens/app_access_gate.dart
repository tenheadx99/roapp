import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roapp/features/auth/screens/auth_launch_screen.dart';
import 'package:roapp/features/settings/bloc/settings_cubit.dart';
import 'package:roapp/features/settings/models/app_settings.dart';

class AppAccessGate extends StatelessWidget {
  const AppAccessGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, AppSettings>(
      builder: (context, settings) {
        if (!settings.isInitialized) {
          return const _AccessLoadingScreen();
        }

        if (settings.isTrialExpired && !settings.trialOverrideUnlocked) {
          return const TrialLockScreen();
        }

        return const AuthLaunchScreen();
      },
    );
  }
}

class TrialLockScreen extends StatefulWidget {
  const TrialLockScreen({super.key});

  static const String unlockCode = '9808';

  @override
  State<TrialLockScreen> createState() => _TrialLockScreenState();
}

class _TrialLockScreenState extends State<TrialLockScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_codeController.text.trim() != TrialLockScreen.unlockCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect unlock pass key.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await context.read<SettingsCubit>().setTrialOverrideUnlocked(true);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App unlocked successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final trialEnd = settings.trialEndsOn;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007FFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_clock_outlined,
                    size: 44,
                    color: Color(0xFF007FFF),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '30-Day Trial Expired',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  trialEnd == null
                      ? 'This app is currently locked. Enter the override pass key to continue.'
                      : 'Your trial ended on ${trialEnd.day}/${trialEnd.month}/${trialEnd.year}. Enter the override pass key to unlock all features.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Override Pass Key',
                    hintText: 'Enter pass key',
                    prefixIcon: Icon(Icons.password_outlined),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _unlock,
                    child: Text(_isSubmitting ? 'Unlocking...' : 'Unlock App'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessLoadingScreen extends StatelessWidget {
  const _AccessLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking app access...'),
          ],
        ),
      ),
    );
  }
}
