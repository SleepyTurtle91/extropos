part of 'advanced_reports_screen.dart';

extension AdvancedReportsMediumWidgetsPart3 on _AdvancedReportsScreenState {
  Widget _buildCustomerAnalysisContent() {
    if (_customerReport == null) return const SizedBox.shrink();

    final report = _customerReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Customers',
              report.topCustomers
                  .where(_matchesCustomerFilter)
                  .length
                  .toString(),
              Icons.people,
            ),
            _buildMetricCard(
              'Avg Lifetime Value',
              'RM${(report.topCustomers.where(_matchesCustomerFilter).fold<double>(0.0, (s, c) => s + c.totalSpent) / (report.topCustomers.where(_matchesCustomerFilter).isEmpty ? 1 : report.topCustomers.where(_matchesCustomerFilter).length)).toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            _buildMetricCard(
              'Top Customers',
              report.topCustomers
                  .where(_matchesCustomerFilter)
                  .length
                  .toString(),
              Icons.star,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Top Customers',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: report.topCustomers
                  .where((customer) {
                    final f = _currentFilter;
                    if (f == null) return true;
                    var ok = true;
                    if (f.searchText != null && f.searchText!.isNotEmpty) {
                      ok = customer.customerName.toLowerCase().contains(
                        f.searchText!.toLowerCase(),
                      );
                    }
                    if (f.minAmount != null) {
                      ok = ok && customer.totalSpent >= f.minAmount!;
                    }
                    if (f.maxAmount != null) {
                      ok = ok && customer.totalSpent <= f.maxAmount!;
                    }
                    return ok;
                  })
                  .take(10)
                  .map((customer) {
                    return ListTile(
                      title: Text(customer.customerName),
                      subtitle: Text(
                        '${customer.visitCount} visits � Avg: RM${customer.averageOrderValue.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        'RM${customer.totalSpent.toStringAsFixed(2)}',
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasketAnalysisContent() {
    if (_basketAnalysisReport == null) return const SizedBox.shrink();

    final report = _basketAnalysisReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Frequently Bought Together',
              report.frequentlyBoughtTogether.length.toString(),
              Icons.shopping_basket,
            ),
            _buildMetricCard(
              'Product Affinities',
              report.productAffinityScores.length.toString(),
              Icons.link,
            ),
            _buildMetricCard(
              'Recommended Bundles',
              report.recommendedBundles.length.toString(),
              Icons.card_giftcard,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Basket Analysis Insights',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Frequently Bought Together'),
                  subtitle: Text(
                    '${report.frequentlyBoughtTogether.length} item combinations identified',
                  ),
                ),
                ListTile(
                  title: const Text('Product Affinities'),
                  subtitle: Text(
                    '${report.productAffinityScores.length} affinity scores calculated',
                  ),
                ),
                ListTile(
                  title: const Text('Recommended Bundles'),
                  subtitle: Text(
                    '${report.recommendedBundles.length} bundle recommendations available',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyProgramContent() {
    if (_loyaltyProgramReport == null) return const SizedBox.shrink();

    final report = _loyaltyProgramReport!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Members',
              report.totalMembers.toString(),
              Icons.people,
            ),
            _buildMetricCard(
              'Active Members',
              report.activeMembers.toString(),
              Icons.check_circle,
            ),
            _buildMetricCard(
              'Points Issued',
              report.totalPointsIssued.toStringAsFixed(0),
              Icons.add_circle,
            ),
            _buildMetricCard(
              'Points Redeemed',
              report.totalPointsRedeemed.toStringAsFixed(0),
              Icons.remove_circle,
            ),
            _buildMetricCard(
              'Redemption Rate',
              '${report.redemptionRate.toStringAsFixed(1)}%',
              Icons.percent,
            ),
          ],
        ),

        const SizedBox(height: 32),

        const Text(
          'Loyalty Program Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Revenue from Loyalty Members'),
                  trailing: Text(
                    'RM${report.revenueFromLoyaltyMembers.toStringAsFixed(2)}',
                  ),
                ),
                ListTile(
                  title: const Text('Points by Tier'),
                  subtitle: Text('${report.pointsByTier.length} tiers tracked'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
