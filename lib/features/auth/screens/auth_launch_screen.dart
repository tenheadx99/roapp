import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roapp/features/auth/bloc/auth_bloc.dart';
import 'package:roapp/features/auth/screens/login_screen.dart';
import 'package:roapp/features/home/screens/home_shell.dart';

class AuthLaunchScreen extends StatelessWidget {
  const AuthLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const HomeShell();
        }

        if (state is AuthUnauthenticated || state is AuthError) {
          return const LoginScreen();
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007FFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFF007FFF),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state is AuthLoading
                      ? 'Restoring your workspace...'
                      : 'Preparing RO Manager...',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
