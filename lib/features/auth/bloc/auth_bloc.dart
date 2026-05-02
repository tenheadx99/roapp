import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

// --- Events ---
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}

// --- States ---
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {}

// --- Bloc ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({AuthRepository? repository})
    : repository = repository ?? AuthRepository(),
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await repository.ensureDefaultUser();

      final email = event.email.trim();
      final password = event.password.trim();

      if (email.isEmpty || password.isEmpty) {
        emit(const AuthError('Email and password are required.'));
        return;
      }

      final user = await repository.loginWithPasskey(email, password);
      if (user == null) {
        emit(
          const AuthError(
            'Invalid credentials. Use your saved passkey or reset the default admin account.',
          ),
        );
        return;
      }

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }
}
