class DashboardStatsModel {
  final String role;
  final StatsData stats;
  final List<TopCustomer> topCustomers;

  DashboardStatsModel({
    required this.role,
    required this.stats,
    required this.topCustomers,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      role: json['role'] ?? '',
      stats: StatsData.fromJson(json['stats'] ?? {}),
      topCustomers: (json['top_customers'] as List?)
              ?.map((e) => TopCustomer.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class StatsData {
  final int total;
  final int open;
  final int resolved;
  final String? avgResolutionTime;
  final String? totalTimeSpent;

  StatsData({
    required this.total,
    required this.open,
    required this.resolved,
    this.avgResolutionTime,
    this.totalTimeSpent,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    return StatsData(
      total: json['total'] ?? 0,
      open: json['open'] ?? 0,
      resolved: json['resolved'] ?? 0,
      avgResolutionTime: json['avg_resolution_time'],
      totalTimeSpent: json['total_time_spent'],
    );
  }
}

class TopCustomer {
  final int id;
  final String name;
  final String email;
  final int count;

  TopCustomer({
    required this.id,
    required this.name,
    required this.email,
    required this.count,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}