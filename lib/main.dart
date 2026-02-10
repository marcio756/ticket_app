import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    // ProviderScope is required for Riverpod to work
    const ProviderScope(
      child: AppInitWrapper(child: App()),
    ),
  );
}

/// A wrapper to handle initial async operations (like checking auth status).
class AppInitWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppInitWrapper({super.key, required this.child});

  @override
  ConsumerState<AppInitWrapper> createState() => _AppInitWrapperState();
}

class _AppInitWrapperState extends ConsumerState<AppInitWrapper> {
  @override
  void initState() {
    super.initState();
    // Check if user is already logged in when app starts
    // Using simple addPostFrameCallback to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}