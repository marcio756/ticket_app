import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dashboard_controller.dart';
import '../../data/models/dashboard_stats_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (data) {
          if (data == null) return const Center(child: Text('Sem dados'));
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardControllerProvider.notifier).loadDashboard(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visão Geral (${data.role})',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _buildStatsGrid(data.stats),
                  if (data.topCustomers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Top Clientes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildTopCustomersList(data.topCustomers),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(StatsData stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Tickets',
          value: stats.total.toString(),
          color: Colors.blue.shade100,
          textColor: Colors.blue.shade900,
        ),
        _StatCard(
          title: 'Abertos',
          value: stats.open.toString(),
          color: Colors.orange.shade100,
          textColor: Colors.orange.shade900,
        ),
        _StatCard(
          title: 'Resolvidos',
          value: stats.resolved.toString(),
          color: Colors.green.shade100,
          textColor: Colors.green.shade900,
        ),
        if (stats.avgResolutionTime != null)
          _StatCard(
            title: 'Tempo Médio',
            value: stats.avgResolutionTime!,
            color: Colors.purple.shade100,
            textColor: Colors.purple.shade900,
          ),
      ],
    );
  }

  Widget _buildTopCustomersList(List<TopCustomer> customers) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return ListTile(
            leading: CircleAvatar(child: Text(customer.name[0])),
            title: Text(customer.name),
            subtitle: Text(customer.email),
            trailing: Badge(
              label: Text('${customer.count}'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color textColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}