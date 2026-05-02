import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/screens/auth_launch_screen.dart';
import 'features/settings/bloc/settings_cubit.dart';
import 'features/settings/models/app_settings.dart';
import 'features/settings/repositories/settings_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(repository: AuthRepository())..add(AuthStarted()),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) =>
              SettingsCubit(repository: SettingsRepository())..loadSettings(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'RO Manager',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const AuthLaunchScreen(),
          );
        },
      ),
    );
  }
}

ThemeData _buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF007FFF),
    brightness: Brightness.light,
  );
  return ThemeData(
    fontFamily: 'Inter',
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5F7F8),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

ThemeData _buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF38BDF8),
    brightness: Brightness.dark,
  );
  return ThemeData(
    fontFamily: 'Inter',
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF020617),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFF111827),
    dividerColor: const Color(0xFF1F2937),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111827),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
