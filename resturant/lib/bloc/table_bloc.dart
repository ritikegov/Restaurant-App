import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/table_model.dart';
import '../repositories/table_repository.dart';

// Events
abstract class TableEvent {}

class TableLoadRequested extends TableEvent {}

class TableRefreshRequested extends TableEvent {}

class TableUpdateAvailability extends TableEvent {
  final int tableId;
  final int availableSeats;

  TableUpdateAvailability(
      {required this.tableId, required this.availableSeats});
}

// States
abstract class TableState {}

class TableInitial extends TableState {}

class TableLoading extends TableState {}

class TableLoaded extends TableState {
  final List<TableModel> tables;

  TableLoaded({required this.tables});
}

class TableError extends TableState {
  final String message;

  TableError({required this.message});
}

// BLoC
class TableBloc extends Bloc<TableEvent, TableState> {
  final TableRepository _tableRepository = TableRepository();

  TableBloc() : super(TableInitial()) {
    on<TableLoadRequested>(_onLoadRequested);
    on<TableRefreshRequested>(_onRefreshRequested);
    on<TableUpdateAvailability>(_onUpdateAvailability);
  }

  Future<void> _onLoadRequested(
      TableLoadRequested event, Emitter<TableState> emit) async {
    try {
      emit(TableLoading());
      final tables = await _tableRepository.getAllTables();
      emit(TableLoaded(tables: tables));
    } catch (e) {
      emit(TableError(message: 'Failed to load tables: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshRequested(
      TableRefreshRequested event, Emitter<TableState> emit) async {
    try {
      final tables = await _tableRepository.getAllTables();
      emit(TableLoaded(tables: tables));
    } catch (e) {
      emit(TableError(message: 'Failed to refresh tables: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvailability(
      TableUpdateAvailability event, Emitter<TableState> emit) async {
    try {
      await _tableRepository.updateTableAvailability(
          event.tableId, event.availableSeats);

      // Refresh tables after update
      final tables = await _tableRepository.getAllTables();
      emit(TableLoaded(tables: tables));
    } catch (e) {
      emit(TableError(
          message: 'Failed to update table availability: ${e.toString()}'));
    }
  }

  // Helper method to get current tables
  List<TableModel> getCurrentTables() {
    final currentState = state;
    if (currentState is TableLoaded) {
      return currentState.tables;
    }
    return [];
  }

  // Helper method to get table by ID
  TableModel? getTableById(int id) {
    try {
      final tables = getCurrentTables();
      return tables.firstWhere((table) => table.id == id);
    } catch (e) {
      return null;
    }
  }
}
