import 'package:extropos/models/loyalty_member.dart';
import 'package:extropos/models/loyalty_transaction.dart';
import 'package:extropos/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'loyalty_dashboard_screen_ui.dart';

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
    throw UnimplementedError('See loyalty_dashboard_screen_ui.dart');
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
