import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

/// Este Widget é o "invólucro" que contém a BottomNavigationBar.
/// Ele recebe o `child` do GoRouter (o ecrã atual).
class MainWrapperScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapperScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends ConsumerState<MainWrapperScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isSupporter = user?.isSupporter ?? false;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: _buildDestinations(isSupporter),
      ),
    );
  }

  List<Widget> _buildDestinations(bool isSupporter) {
    // Menu Base (Comum a todos)
    final destinations = <Widget>[
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
    ];

    // Se for supporter, podemos adicionar menus extra ou alterar a ordem
    if (isSupporter) {
      // Exemplo: Supporters poderiam ter um menu "Clientes"
      // destinations.add(...)
    }

    // Perfil (Sempre no fim)
    destinations.add(
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    );

    return destinations;
  }
}