part of 'employee_performance_screen.dart';

extension _EmployeePerformanceOverviewUIBuilders
    on _EmployeePerformanceScreenState {
  Widget buildDateRangeDisplay() {
    final formatter = DateFormat('MMM dd, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${formatter.format(_dateRange.start)} - ${formatter.format(_dateRange.end)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            '${_dateRange.duration.inDays + 1} days',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget buildOverviewTab() {
    if (_performances.isEmpty) {
      return const Center(
        child: Text('No employee performance data available for this period'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSummaryCards(),
          const SizedBox(height: 24),
          buildPerformanceTable(),
          const SizedBox(height: 24),
          buildCommissionBreakdown(),
        ],
      ),
    );
  }

  Widget buildSummaryCards() {
    final totalSales = _performances.fold(0.0, (sum, p) => sum + p.totalSales);
    final totalOrders = _performances.fold(0, (sum, p) => sum + p.orderCount);
    final totalCommission = _performances.fold(
      0.0,
      (sum, p) => sum + p.commission,
    );

    final avgOrderValue = totalOrders > 0 ? totalSales / totalOrders : 0.0;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        buildSummaryCard(
          'Total Sales',
          '${BusinessInfo.instance.currencySymbol}${totalSales.toStringAsFixed(2)}',
          Icons.attach_money,
          const Color(0xFF10B981),
        ),
        buildSummaryCard(
          'Total Orders',
          totalOrders.toString(),
          Icons.shopping_cart,
          const Color(0xFF2563EB),
        ),
        buildSummaryCard(
          'Commission Paid',
          '${BusinessInfo.instance.currencySymbol}${totalCommission.toStringAsFixed(2)}',
          Icons.payments,
          const Color(0xFFF59E0B),
        ),
        buildSummaryCard(
          'Avg Order Value',
          '${BusinessInfo.instance.currencySymbol}${avgOrderValue.toStringAsFixed(2)}',
          Icons.trending_up,
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPerformanceTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Performance Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Employee')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Orders')),
                  DataColumn(label: Text('Total Sales')),
                  DataColumn(label: Text('Avg Order')),
                  DataColumn(label: Text('Commission')),
                  DataColumn(label: Text('Tier')),
                ],
                rows: _performances.map((performance) {
                  final tier =
                      CommissionTier.getTierForSales(performance.totalSales);
                  return DataRow(cells: [
                    DataCell(Text(performance.userName)),
                    DataCell(Text(performance.userRole)),
                    DataCell(Text(performance.orderCount.toString())),
                    DataCell(Text(
                      '${BusinessInfo.instance.currencySymbol}${performance.totalSales.toStringAsFixed(2)}',
                    )),
                    DataCell(Text(
                      '${BusinessInfo.instance.currencySymbol}${performance.averageOrderValue.toStringAsFixed(2)}',
                    )),
                    DataCell(Text(
                      '${BusinessInfo.instance.currencySymbol}${performance.commission.toStringAsFixed(2)}',
                    )),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getTierColor(tier?.tierName ?? 'Bronze'),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tier?.tierName ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCommissionBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Tiers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...CommissionTier.defaultTiers.map((tier) {
              final employeesInTier = _performances.where((p) {
                final t = CommissionTier.getTierForSales(p.totalSales);
                return t?.tierName == tier.tierName;
              }).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getTierColor(tier.tierName),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tier.tierName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${BusinessInfo.instance.currencySymbol}${tier.minSales.toStringAsFixed(0)} - ${tier.maxSales == double.infinity ? '∞' : BusinessInfo.instance.currencySymbol + tier.maxSales.toStringAsFixed(0)} • ${(tier.rate * 100).toStringAsFixed(0)}% commission',
                      ),
                    ),
                    Text(
                      '$employeesInTier ${employeesInTier == 1 ? 'employee' : 'employees'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildLeaderboardTab() {
    if (_rankings.isEmpty) {
      return const Center(
        child: Text('No leaderboard data available for this period'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final ranking = _rankings[index];
        return buildLeaderboardCard(ranking);
      },
    );
  }

  Widget buildLeaderboardCard(EmployeeRanking ranking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: ranking.rank <= 3 ? 4 : 2,
      child: ListTile(
        leading: buildRankBadge(ranking.rank),
        title: Text(
          ranking.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ranking.userRole),
            const SizedBox(height: 4),
            Text(
              '${ranking.orderCount} orders • ${BusinessInfo.instance.currencySymbol}${ranking.commission.toStringAsFixed(2)} commission',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${BusinessInfo.instance.currencySymbol}${ranking.totalSales.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Sales',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget buildRankBadge(int rank) {
    Color color;
    IconData icon;

    if (rank == 1) {
      color = Colors.amber;
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      color = Colors.grey;
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      color = Colors.brown;
      icon = Icons.emoji_events;
    } else {
      color = Colors.blue;
      icon = Icons.person;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: rank <= 3
            ? Icon(icon, color: Colors.white, size: 28)
            : Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Color getTierColor(String tierName) {
    switch (tierName) {
      case 'Bronze':
        return Colors.brown;
      case 'Silver':
        return Colors.grey;
      case 'Gold':
        return Colors.amber;
      case 'Platinum':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
