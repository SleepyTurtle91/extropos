part of 'customers_management_screen.dart';

extension CustomersManagementSections on _CustomersManagementScreenState {
  Widget buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: _StatCard(
                    icon: Icons.people,
                    label: 'Total Customers',
                    value: customers.length.toString(),
                    color: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: _StatCard(
                    icon: Icons.trending_up,
                    label: 'Active (30d)',
                    value: activeCustomersCount.toString(),
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: _StatCard(
                    icon: Icons.star,
                    label: 'VIP Customers',
                    value: vipCustomersCount.toString(),
                    color: Colors.amber,
                  ),
                ),
                SizedBox(
                  width: (constraints.maxWidth - 12) / 2,
                  child: _StatCard(
                    icon: Icons.card_giftcard,
                    label: 'Total Points',
                    value: totalLoyaltyPoints.toString(),
                    color: Colors.purple,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people,
                  label: 'Total Customers',
                  value: customers.length.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Active (30d)',
                  value: activeCustomersCount.toString(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.star,
                  label: 'VIP Customers',
                  value: vipCustomersCount.toString(),
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.card_giftcard,
                  label: 'Total Points',
                  value: totalLoyaltyPoints.toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    filterCustomers('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: filterCustomers,
      ),
    );
  }

  Widget buildCustomersGrid() {
    if (filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No customers found'
                  : 'No customers yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try a different search term'
                  : 'Add your first customer to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: AppTokens.tableCardMinWidth + 40,
            crossAxisSpacing: AppSpacing.m,
            mainAxisSpacing: AppSpacing.m,
            childAspectRatio: 1.2,
          ),
          itemCount: filteredCustomers.length,
          itemBuilder: (context, index) {
            final customer = filteredCustomers[index];
            return _CustomerCard(
              customer: customer,
              onEdit: () => editCustomer(customer),
              onDelete: () => deleteCustomer(customer),
            );
          },
        );
      },
    );
  }
}
