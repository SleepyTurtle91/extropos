import 'package:extropos/models/loyalty_member.dart';
import 'package:extropos/models/loyalty_transaction.dart';
import 'package:extropos/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RewardsHistoryScreen extends StatefulWidget {
  const RewardsHistoryScreen({super.key});

  @override
  State<RewardsHistoryScreen> createState() => _RewardsHistoryScreenState();
}

class _RewardsHistoryScreenState extends State<RewardsHistoryScreen> {
  LoyaltyMember? currentMember;
  late List<LoyaltyTransaction> allTransactions = [];
  late List<LoyaltyTransaction> filteredTransactions = [];
  TextEditingController memberSearchController = TextEditingController();
  String selectedFilter = 'all';
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    try {
      final members = await LoyaltyService.instance.getAllMembers();
      if (members.isNotEmpty) {
        setState(() => currentMember = members.first);
        await _loadMemberHistory();
      }
    } catch (e) {
      print('❌ Error initializing: $e');
    }
  }

  Future<void> _loadMemberHistory() async {
    if (currentMember == null) return;

    try {
      final transactions =
          await LoyaltyService.instance.getMemberTransactions(currentMember!.id);
      setState(() {
        allTransactions = transactions;
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading history: $e')),
      );
    }
  }

  void _applyFilters() {
    var filtered = allTransactions;

    // Apply type filter
    switch (selectedFilter) {
      case 'earned':
        filtered = filtered.where((t) => t.pointsEarned > 0).toList();
        break;
      case 'redeemed':
        filtered = filtered.where((t) => t.pointsRedeemed > 0).toList();
        break;
      case 'purchase':
        filtered =
            filtered.where((t) => t.transactionType == 'Purchase').toList();
        break;
      case 'reward':
        filtered = filtered.where((t) => t.transactionType == 'Reward').toList();
        break;
    }

    // Apply date range filter
    if (selectedDateRange != null) {
      filtered = filtered.where((t) {
        return t.transactionDate.isAfter(selectedDateRange!.start) &&
            t.transactionDate.isBefore(selectedDateRange!.end.add(Duration(days: 1)));
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    setState(() => filteredTransactions = filtered);
  }

  void searchMember() async {
    if (memberSearchController.text.isEmpty) return;

    try {
      final members = await LoyaltyService.instance.getAllMembers();
      final query = memberSearchController.text.toLowerCase();
      final found = members.firstWhere(
        (m) =>
            m.name.toLowerCase().contains(query) ||
            m.phone.toLowerCase().contains(query),
        orElse: () => LoyaltyMember(
          id: '',
          name: '',
          phone: '',
          email: '',
          joinDate: DateTime.now(),
          currentTier: '',
          totalPoints: 0,
          redeemedPoints: 0,
          lastPurchaseDate: DateTime.now(),
          totalSpent: 0.0,
        ),
      );

      if (found.id.isNotEmpty) {
        setState(() => currentMember = found);
        await _loadMemberHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards History'),
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          if (currentMember != null && currentMember!.id.isNotEmpty) ...[
            _buildMemberHeaderCard(),
            _buildFilterSection(),
            Expanded(child: _buildTransactionsList()),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Search for a member to view history',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: memberSearchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: searchMember,
            icon: Icon(Icons.search),
            label: const Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberHeaderCard() {
    final member = currentMember!;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF2563EB),
            child: Text(
              member.name.isNotEmpty ? member.name[0] : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  member.phone,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTierColor(member.currentTier),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    member.currentTier,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.totalPoints - member.redeemedPoints}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Available Points',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: selectedFilter == 'all',
                onSelected: (selected) {
                  setState(() => selectedFilter = 'all');
                  _applyFilters();
                },
              ),
              FilterChip(
                label: const Text('Points Earned'),
                selected: selectedFilter == 'earned',
                onSelected: (selected) {
                  setState(() => selectedFilter = 'earned');
                  _applyFilters();
                },
              ),
              FilterChip(
                label: const Text('Points Redeemed'),
                selected: selectedFilter == 'redeemed',
                onSelected: (selected) {
                  setState(() => selectedFilter = 'redeemed');
                  _applyFilters();
                },
              ),
              FilterChip(
                label: const Text('Purchases'),
                selected: selectedFilter == 'purchase',
                onSelected: (selected) {
                  setState(() => selectedFilter = 'purchase');
                  _applyFilters();
                },
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.calendar_today, size: 16),
                label: const Text('Date Range'),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    initialDateRange: selectedDateRange,
                  );
                  if (range != null) {
                    setState(() => selectedDateRange = range);
                    _applyFilters();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final tx = filteredTransactions[index];
        return _buildTransactionCard(tx, index);
      },
    );
  }

  Widget _buildTransactionCard(LoyaltyTransaction tx, int index) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isEarned = tx.pointsEarned > 0;
    final pointsChange = isEarned ? tx.pointsEarned : -tx.pointsRedeemed;
    final pointColor = isEarned ? Colors.green : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: pointColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  isEarned ? Icons.add_circle : Icons.remove_circle,
                  color: pointColor,
                  size: 28,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.transactionType,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${dateFormat.format(tx.transactionDate)} at ${timeFormat.format(tx.transactionDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Amount: RM ${tx.amount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isEarned ? '+$pointsChange' : '$pointsChange',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pointColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'points',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Platinum':
        return Colors.purple;
      case 'Gold':
        return Colors.amber;
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    memberSearchController.dispose();
    super.dispose();
  }
}
