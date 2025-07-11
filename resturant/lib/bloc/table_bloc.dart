import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/core/constants.dart';
import '../models/table_model.dart';
import '../repositories/table_repository.dart';

abstract class TableEvent {}

class TableLoadRequested extends TableEvent {}

class TableRefreshRequested extends TableEvent {}

class TableUpdateAvailability extends TableEvent {
  final int tableId;
  final int availableSeats;

  TableUpdateAvailability(
      {required this.tableId, required this.availableSeats});
}

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
      emit(TableError(
          message: '${AppConstants.failedToLoadTable} ${e.toString()}'));
    }
  }

  Future<void> _onRefreshRequested(
      TableRefreshRequested event, Emitter<TableState> emit) async {
    try {
      final tables = await _tableRepository.getAllTables();
      emit(TableLoaded(tables: tables));
    } catch (e) {
      emit(TableError(
          message: '${AppConstants.failedToRefreshTable} ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvailability(
      TableUpdateAvailability event, Emitter<TableState> emit) async {
    try {
      await _tableRepository.updateTableAvailability(
          event.tableId, event.availableSeats);

      final tables = await _tableRepository.getAllTables();
      emit(TableLoaded(tables: tables));
    } catch (e) {
      emit(TableError(
          message: '${AppConstants.failedToUpdateTable} ${e.toString()}'));
    }
  }

  List<TableModel> getCurrentTables() {
    final currentState = state;
    if (currentState is TableLoaded) {
      return currentState.tables;
    }
    return [];
  }

  TableModel? getTableById(int id) {
    try {
      final tables = getCurrentTables();
      return tables.firstWhere((table) => table.id == id);
    } catch (e) {
      return null;
    }
  }
}
