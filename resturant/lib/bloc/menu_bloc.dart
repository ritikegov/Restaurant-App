import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restaurant_app/core/constants.dart';
import '../models/menu_item_model.dart';
import '../repositories/menu_repository.dart';

abstract class MenuEvent {}

class MenuLoadRequested extends MenuEvent {}

class MenuRefreshRequested extends MenuEvent {}

class MenuFilterByCategory extends MenuEvent {
  final String? category;

  MenuFilterByCategory({this.category});
}

abstract class MenuState {}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuItemModel> menuItems;
  final List<String> categories;
  final String? selectedCategory;

  MenuLoaded({
    required this.menuItems,
    required this.categories,
    this.selectedCategory,
  });
}

class MenuError extends MenuState {
  final String message;

  MenuError({required this.message});
}

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuRepository _menuRepository = MenuRepository();
  List<MenuItemModel> _allMenuItems = [];

  MenuBloc() : super(MenuInitial()) {
    on<MenuLoadRequested>(_onLoadRequested);
    on<MenuRefreshRequested>(_onRefreshRequested);
    on<MenuFilterByCategory>(_onFilterByCategory);
  }

  Future<void> _onLoadRequested(
      MenuLoadRequested event, Emitter<MenuState> emit) async {
    try {
      emit(MenuLoading());

      _allMenuItems = await _menuRepository.getAllMenuItems();
      final categories = await _menuRepository.getCategories();

      emit(MenuLoaded(
        menuItems: _allMenuItems,
        categories: categories,
      ));
    } catch (e) {
      emit(MenuError(
          message: '${AppConstants.failedMenuLoadMesage} ${e.toString()}'));
    }
  }

  Future<void> _onRefreshRequested(
      MenuRefreshRequested event, Emitter<MenuState> emit) async {
    try {
      _allMenuItems = await _menuRepository.getAllMenuItems();
      final categories = await _menuRepository.getCategories();

      emit(MenuLoaded(
        menuItems: _allMenuItems,
        categories: categories,
      ));
    } catch (e) {
      emit(MenuError(
          message: '${AppConstants.failedRefreshMenu} ${e.toString()}'));
    }
  }

  Future<void> _onFilterByCategory(
      MenuFilterByCategory event, Emitter<MenuState> emit) async {
    try {
      final categories = await _menuRepository.getCategories();
      List<MenuItemModel> filteredItems;

      if (event.category == null || event.category!.isEmpty) {
        filteredItems = _allMenuItems;
      } else {
        filteredItems = _allMenuItems
            .where((item) => item.category == event.category)
            .toList();
      }

      emit(MenuLoaded(
        menuItems: filteredItems,
        categories: categories,
        selectedCategory: event.category,
      ));
    } catch (e) {
      emit(MenuError(
          message: '${AppConstants.failedToFilterMenu} ${e.toString()}'));
    }
  }

  List<MenuItemModel> getCurrentMenuItems() {
    final currentState = state;
    if (currentState is MenuLoaded) {
      return currentState.menuItems;
    }
    return [];
  }

  MenuItemModel? getMenuItemById(int id) {
    try {
      final menuItems = getCurrentMenuItems();
      return menuItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getAvailableCategories() {
    final currentState = state;
    if (currentState is MenuLoaded) {
      return currentState.categories;
    }
    return [];
  }
}
