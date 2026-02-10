import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class MainWrapperScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapperScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final canManageUsers = authState.user?.isSupporter ?? false;

    // Definimos as abas possíveis
    // A ordem AQUI deve corresponder exatamente à ordem no router.dart
    final tabs = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.confirmation_number_outlined),
        selectedIcon: Icon(Icons.confirmation_number),
        label: 'Tickets',
      ),
      if (canManageUsers)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Utilizadores',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    return Scaffold(
      // O GoRouter já gere o IndexedStack internamente através do navigationShell
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: tabs,
        onDestinationSelected: (index) {
          // Muda para a branch correspondente
          navigationShell.goBranch(
            index,
            // A flag initialLocation: true garante que ao clicar na tab
            // voltamos à raiz dessa tab (ex: sair de um detalhe de ticket)
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}