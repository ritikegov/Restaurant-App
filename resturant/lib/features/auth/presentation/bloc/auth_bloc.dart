import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../shared/services/shared_preferences_service.dart';
import '../../../../core/constants/app_constants.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginEvent extends AuthEvent {
  final String username;
  final String password;

  const LoginEvent({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

class SignupEvent extends AuthEvent {
  final String username;
  final String password;

  const SignupEvent({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

class LogoutEvent extends AuthEvent {}

class CheckLoginStatusEvent extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final Map<String, dynamic> user;

  const AuthSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthLoggedOut extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DatabaseHelper _databaseHelper;

  AuthBloc({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<SignupEvent>(_onSignup);
    on<LogoutEvent>(_onLogout);
    on<CheckLoginStatusEvent>(_onCheckLoginStatus);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());

      // Validate input
      final validationError = _validateInput(event.username, event.password);
      if (validationError != null) {
        emit(AuthFailure(message: validationError));
        return;
      }

      // Check credentials
      final user =
          await _databaseHelper.getUser(event.username, event.password);

      if (user != null) {
        await SharedPreferencesService.setLoggedInUser(user);
        emit(AuthSuccess(user: user));
      } else {
        emit(const AuthFailure(message: AppConstants.invalidCredentials));
      }
    } catch (e) {
      emit(AuthFailure(message: 'Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onSignup(SignupEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());

      // Validate input
      final validationError = _validateInput(event.username, event.password);
      if (validationError != null) {
        emit(AuthFailure(message: validationError));
        return;
      }

      // Check if user already exists
      final userExists = await _databaseHelper.userExists(event.username);
      if (userExists) {
        emit(const AuthFailure(message: AppConstants.userAlreadyExists));
        return;
      }

      // Create new user
      final newUser = {
        'username': event.username,
        'password': event.password,
        'created_at': DateTime.now().toIso8601String(),
      };

      final userId = await _databaseHelper.insertUser(newUser);

      if (userId > 0) {
        final user = {
          'id': userId,
          'username': event.username,
          'password': event.password,
          'created_at': newUser['created_at'],
        };

        await SharedPreferencesService.setLoggedInUser(user);
        emit(AuthSuccess(user: user));
      } else {
        emit(const AuthFailure(message: 'Registration failed'));
      }
    } catch (e) {
      emit(AuthFailure(message: 'Signup failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await SharedPreferencesService.logout();
      emit(AuthLoggedOut());
    } catch (e) {
      emit(AuthFailure(message: 'Logout failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckLoginStatus(
      CheckLoginStatusEvent event, Emitter<AuthState> emit) async {
    try {
      final isLoggedIn = await SharedPreferencesService.isUserLoggedIn();

      if (isLoggedIn) {
        final userId = await SharedPreferencesService.getLoggedInUserId();
        final username = await SharedPreferencesService.getLoggedInUsername();

        if (userId != null && username != null) {
          final user = {
            'id': userId,
            'username': username,
          };
          emit(AuthSuccess(user: user));
        } else {
          emit(AuthLoggedOut());
        }
      } else {
        emit(AuthLoggedOut());
      }
    } catch (e) {
      emit(AuthLoggedOut());
    }
  }

  String? _validateInput(String username, String password) {
    if (username.isEmpty) {
      return AppConstants.emptyUsernameError;
    }
    if (password.isEmpty) {
      return AppConstants.emptyPasswordError;
    }
    if (username.length < 3) {
      return AppConstants.usernameMinLengthError;
    }
    if (password.length < 6) {
      return AppConstants.passwordMinLengthError;
    }
    return null;
  }
}
