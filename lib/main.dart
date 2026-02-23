import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<AuthBloc>(create: (_) => AuthBloc())],
      child: MaterialApp(
        title: 'RO Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Use modern sans-serif default font
          fontFamily: 'Inter',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007FFF)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
