import 'package:extropos/models/loyalty_member.dart';
import 'package:extropos/models/loyalty_transaction.dart';
import 'package:extropos/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen> {
  LoyaltyMember? currentMember;
  late List<LoyaltyTransaction> recentTransactions = [];
  TextEditingController memberSearchController = TextEditingController();
  bool isLoadingMember = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    try {
      // Load some overview data
      final members = await LoyaltyService.instance.getAllMembers();
      if (members.isNotEmpty) {
        setState(() => currentMember = members.first);
        _loadMemberTransactions();
      }
    } catch (e) {
      print('❌ Error loading dashboard: $e');
    }
  }

  Future<void> _loadMemberTransactions() async {
    if (currentMember == null) return;

    try {
      final transactions =
          await LoyaltyService.instance.getMemberTransactions(currentMember!.id);
      setState(() => recentTransactions = transactions.take(5).toList());
    } catch (e) {
      print('❌ Error loading transactions: $e');
    }
  }

  void searchMember() async {
    if (memberSearchController.text.isEmpty) return;

    setState(() => isLoadingMember = true);

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
        await _loadMemberTransactions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member found: ${found.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching member: $e')),
      );
    } finally {
      setState(() => isLoadingMember = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Dashboard'),
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchSection(),
            if (currentMember != null && currentMember!.id.isNotEmpty) ...[
              _buildMemberCard(),
              _buildTierBenefitsSection(),
              _buildPointsBreakdownSection(),
              _buildRecentTransactionsSection(),
            ] else ...[
              SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'Search for a member to view dashboard',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Member',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isLoadingMember ? null : searchMember,
                icon: isLoadingMember
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard() {
    final member = currentMember!;
    final tierColor = _getTierColor(member.currentTier);
    const currency = 'RM';

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1e40af)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      member.phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: tierColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  member.currentTier,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMemberStat(
                'Available Points',
                '${member.totalPoints - member.redeemedPoints}',
                Colors.white,
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white30,
              ),
              _buildMemberStat(
                'Total Spent',
                '$currency ${member.totalSpent.toStringAsFixed(2)}',
                Colors.white,
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white30,
              ),
              _buildMemberStat(
                'Member Since',
                DateFormat('MMM y').format(member.joinDate),
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStat(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTierBenefitsSection() {
    if (currentMember == null) return SizedBox.shrink();

    final benefits = _getTierBenefits(currentMember!.currentTier);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${currentMember!.currentTier} Tier Benefits',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(height: 8),
          ...benefits.map((benefit) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.amber[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPointsBreakdownSection() {
    if (currentMember == null) return SizedBox.shrink();

    final member = currentMember!;
    final availablePoints = member.totalPoints - member.redeemedPoints;
    final earnedPointsPercent = member.totalPoints > 0
        ? (member.totalPoints - member.redeemedPoints) / member.totalPoints
        : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Points Breakdown',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earned',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${member.totalPoints}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Redeemed',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${member.redeemedPoints}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '$availablePoints',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: earnedPointsPercent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    if (recentTransactions.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No transactions yet',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          ...recentTransactions.map((tx) {
            final dateFormat = DateFormat('MMM d, yyyy hh:mm a');
            final isEarned = tx.pointsEarned > 0;

            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.transactionType,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            dateFormat.format(tx.transactionDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'RM ${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          isEarned ? '+${tx.pointsEarned}' : '-${tx.pointsRedeemed}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isEarned ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'Gold':
        return Colors.amber;
      case 'Silver':
        return Colors.grey;
      case 'Bronze':
        return Colors.brown;
      case 'Platinum':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  List<String> _getTierBenefits(String tier) {
    switch (tier) {
      case 'Platinum':
        return [
          '10% discount on all purchases',
          'Double points on weekends',
          'VIP customer support',
          'Exclusive birthday gift',
        ];
      case 'Gold':
        return [
          '7% discount on all purchases',
          '1.5x points on selected items',
          'Priority support',
          'Birthday bonus points',
        ];
      case 'Silver':
        return [
          '3% discount on selected items',
          'Regular points earning',
          'Standard support',
        ];
      case 'Bronze':
        return [
          'Join the loyalty program',
          'Start earning points',
          'Basic member benefits',
        ];
      default:
        return [];
    }
  }

  @override
  void dispose() {
    memberSearchController.dispose();
    super.dispose();
  }
}
