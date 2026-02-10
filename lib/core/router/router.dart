import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/controllers/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../shared/layout/main_wrapper_screen.dart';
import '../../features/tickets/presentation/screens/ticket_list_screen.dart';
import '../../features/tickets/presentation/screens/ticket_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/users/presentation/screens/user_list_screen.dart';
import '../../features/tickets/presentation/screens/create_ticket_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final canManageUsers = authState.user?.isSupporter ?? false;

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Passamos o navigationShell para o Wrapper
          return MainWrapperScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Tickets
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tickets',
                builder: (context, state) => const TicketListScreen(),
                routes: [
                  // A rota 'create' deve ser definida explicitamente
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const CreateTicketScreen(),
                  ),
                  // A rota dinâmica fica depois
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return TicketDetailScreen(ticketId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2 (Condicional): Utilizadores (Apenas Admin)
          if (canManageUsers)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/users',
                  builder: (context, state) => const UserListScreen(),
                ),
              ],
            ),
          // Branch 3 (ou 2 se não for admin): Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});