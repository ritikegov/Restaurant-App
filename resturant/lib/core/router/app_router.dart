import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/tables/presentation/pages/table_list_page.dart';
import '../../features/tables/presentation/pages/home_page.dart';
import '../../features/menu/presentation/pages/menu_page.dart';
import '../../features/orders/presentation/pages/order_history_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        // Login Route
        AutoRoute(
          page: LoginRoute.page,
          path: '/login',
          initial: true,
        ),

        // Signup Route
        AutoRoute(
          page: SignupRoute.page,
          path: '/signup',
        ),

        // Home Route
        AutoRoute(
          page: HomeRoute.page,
          path: '/home',
        ),

        // Tables Route
        AutoRoute(
          page: TableListRoute.page,
          path: '/tables',
        ),

        // Menu Route
        AutoRoute(
          page: MenuRoute.page,
          path: '/menu',
        ),

        // Order History Route
        AutoRoute(
          page: OrderHistoryRoute.page,
          path: '/orders',
        ),
      ];
}

@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPageView();
  }
}

@RoutePage()
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignupPageView();
  }
}

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePageView();
  }
}

@RoutePage()
class TableListPage extends StatelessWidget {
  const TableListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TableListPageView();
  }
}

@RoutePage()
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MenuPageView();
  }
}

@RoutePage()
class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrderHistoryPageView();
  }
}
