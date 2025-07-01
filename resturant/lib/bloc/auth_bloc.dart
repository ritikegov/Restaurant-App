import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  AuthLoginRequested({required this.username, required this.password});
}

class AuthSignupRequested extends AuthEvent {
  final String username;
  final String password;

  AuthSignupRequested({required this.username, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckLoginStatus extends AuthEvent {}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});
}

class AuthSignupSuccess extends AuthState {
  final String message;

  AuthSignupSuccess({required this.message});
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserRepository _userRepository = UserRepository();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignupRequested>(_onSignupRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckLoginStatus>(_onCheckLoginStatus);
  }

  Future<void> _onLoginRequested(
      AuthLoginRequested event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());

      final usernameError = AppUtils.validateUsername(event.username);
      if (usernameError != null) {
        emit(AuthError(message: usernameError));
        return;
      }

      final passwordError = AppUtils.validatePassword(event.password);
      if (passwordError != null) {
        emit(AuthError(message: passwordError));
        return;
      }

      final user = await _userRepository.authenticateUser(
          event.username, event.password);

      if (user != null) {
        _currentUser = user;
        await _saveUserSession(user);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: AppConstants.errorInvalidCredentials));
      }
    } catch (e) {
      emit(AuthError(message: '${AppConstants.loginFailed} ${e.toString()}'));
    }
  }

  Future<void> _onSignupRequested(
      AuthSignupRequested event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());

      final usernameError = AppUtils.validateUsername(event.username);
      if (usernameError != null) {
        emit(AuthError(message: usernameError));
        return;
      }

      final passwordError = AppUtils.validatePassword(event.password);
      if (passwordError != null) {
        emit(AuthError(message: passwordError));
        return;
      }

      final user =
          await _userRepository.createUser(event.username, event.password);

      if (user != null) {
        emit(AuthSignupSuccess(message: AppConstants.successUserCreated));
      } else {
        emit(AuthError(message: AppConstants.errorCreateUserFailed));
      }
    } catch (e) {
      if (e.toString().contains(AppConstants.errorUserExists)) {
        emit(AuthError(message: AppConstants.errorUserExists));
      } else {
        emit(
            AuthError(message: '${AppConstants.signUpFailed} ${e.toString()}'));
      }
    }
  }

  Future<void> _onLogoutRequested(
      AuthLogoutRequested event, Emitter<AuthState> emit) async {
    try {
      _currentUser = null;
      await _clearUserSession();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: '${AppConstants.logoutFailed} ${e.toString()}'));
    }
  }

  Future<void> _onCheckLoginStatus(
      AuthCheckLoginStatus event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());

      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(AppConstants.prefKeyIsLoggedIn) ?? false;
      final userId = prefs.getInt(AppConstants.prefKeyUserId);

      if (isLoggedIn && userId != null) {
        final user = await _userRepository.getUserById(userId);
        if (user != null) {
          _currentUser = user;
          emit(AuthAuthenticated(user: user));
          return;
        }
      }

      await _clearUserSession();
      emit(AuthUnauthenticated());
    } catch (e) {
      await _clearUserSession();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _saveUserSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefKeyIsLoggedIn, true);
      await prefs.setInt(AppConstants.prefKeyUserId, user.id!);
      await prefs.setString(AppConstants.prefKeyUsername, user.username);
    } catch (e) {
      throw Exception('${AppConstants.failedToSaveSession} $e');
    }
  }

  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefKeyIsLoggedIn);
      await prefs.remove(AppConstants.prefKeyUserId);
      await prefs.remove(AppConstants.prefKeyUsername);
    } catch (e) {
      throw Exception('${AppConstants.failedToClearSession} $e');
    }
  }

  Future<int?> getCurrentUserId() async {
    try {
      if (_currentUser?.id != null) {
        return _currentUser!.id;
      }

      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(AppConstants.prefKeyUserId);
    } catch (e) {
      return null;
    }
  }

  Future<String?> getCurrentUsername() async {
    try {
      if (_currentUser?.username.isNotEmpty == true) {
        return _currentUser!.username;
      }

      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.prefKeyUsername);
    } catch (e) {
      return null;
    }
  }
}
