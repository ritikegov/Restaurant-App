import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../shared/services/shared_preferences_service.dart';
import '../../../../core/constants/app_constants.dart';

// Events
abstract class TableEvent extends Equatable {
  const TableEvent();

  @override
  List<Object> get props => [];
}

class LoadTablesEvent extends TableEvent {}

class BookTableEvent extends TableEvent {
  final int tableId;

  const BookTableEvent({required this.tableId});

  @override
  List<Object> get props => [tableId];
}

class CheckUserBookingEvent extends TableEvent {}

// States
abstract class TableState extends Equatable {
  const TableState();

  @override
  List<Object> get props => [];
}

class TableInitial extends TableState {}

class TableLoading extends TableState {}

class TablesLoaded extends TableState {
  final List<Map<String, dynamic>> tables;
  final bool userHasBooking;
  final int? userBookedTableId;

  const TablesLoaded({
    required this.tables,
    required this.userHasBooking,
    this.userBookedTableId,
  });

  @override
  List<Object> get props => [tables, userHasBooking];
}

class TableBookingSuccess extends TableState {
  final String message;
  final int tableId;

  const TableBookingSuccess({required this.message, required this.tableId});

  @override
  List<Object> get props => [message, tableId];
}

class TableFailure extends TableState {
  final String message;

  const TableFailure({required this.message});

  @override
  List<Object> get props => [message];
}

// BLoC
class TableBloc extends Bloc<TableEvent, TableState> {
  final DatabaseHelper _databaseHelper;

  TableBloc({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        super(TableInitial()) {
    on<LoadTablesEvent>(_onLoadTables);
    on<BookTableEvent>(_onBookTable);
    on<CheckUserBookingEvent>(_onCheckUserBooking);
  }

  Future<void> _onLoadTables(
      LoadTablesEvent event, Emitter<TableState> emit) async {
    try {
      emit(TableLoading());

      final tables = await _databaseHelper.getAllTables();
      final userHasBooking =
          await SharedPreferencesService.hasUserBookedTable();
      final userBookedTableId =
          await SharedPreferencesService.getUserBookedTable();

      // Process tables to determine colors based on availability
      final processedTables = tables.map((table) {
        final availableSeats = table['available_seats'] as int;
        final capacity = table['capacity'] as int;

        String color;
        if (availableSeats == capacity) {
          color = 'green'; // All seats available
        } else if (availableSeats == capacity - 1) {
          color = 'gray'; // One seat taken
        } else if (availableSeats > 0) {
          color = 'yellow'; // Partially occupied
        } else {
          color = 'red'; // Fully occupied
        }

        return {
          ...table,
          'color': color,
        };
      }).toList();

      emit(TablesLoaded(
        tables: processedTables,
        userHasBooking: userHasBooking,
        userBookedTableId: userBookedTableId,
      ));
    } catch (e) {
      emit(TableFailure(message: 'Failed to load tables: ${e.toString()}'));
    }
  }

  Future<void> _onBookTable(
      BookTableEvent event, Emitter<TableState> emit) async {
    try {
      emit(TableLoading());

      // Check if user is logged in
      final userId = await SharedPreferencesService.getLoggedInUserId();
      if (userId == null) {
        emit(const TableFailure(message: 'Please login first'));
        return;
      }

      // Check if user already has a table booked
      final userHasBooking =
          await SharedPreferencesService.hasUserBookedTable();
      if (userHasBooking) {
        emit(const TableFailure(message: AppConstants.userAlreadyHasTable));
        return;
      }

      // Get table details
      final tables = await _databaseHelper.getAllTables();
      final table = tables.firstWhere(
        (t) => t['id'] == event.tableId,
        orElse: () => {},
      );

      if (table.isEmpty) {
        emit(const TableFailure(message: 'Table not found'));
        return;
      }

      // Check if table is available
      final availableSeats = table['available_seats'] as int;
      if (availableSeats <= 0) {
        emit(const TableFailure(message: AppConstants.tableAlreadyBooked));
        return;
      }

      // Book the table
      final result = await _databaseHelper.bookTable(event.tableId, userId);

      if (result > 0) {
        await SharedPreferencesService.setUserBookedTable(event.tableId);
        emit(TableBookingSuccess(
          message: AppConstants.tableBookedSuccessfully,
          tableId: event.tableId,
        ));

        // Reload tables to show updated status
        add(LoadTablesEvent());
      } else {
        emit(const TableFailure(message: 'Failed to book table'));
      }
    } catch (e) {
      emit(TableFailure(message: 'Booking failed: ${e.toString()}'));
    }
  }

  Future<void> _onCheckUserBooking(
      CheckUserBookingEvent event, Emitter<TableState> emit) async {
    try {
      final userId = await SharedPreferencesService.getLoggedInUserId();
      if (userId == null) {
        return;
      }

      final bookedTable = await _databaseHelper.getUserBookedTable(userId);
      if (bookedTable != null) {
        await SharedPreferencesService.setUserBookedTable(bookedTable['id']);
      }
    } catch (e) {
      // Silent fail for checking booking status
    }
  }
}
