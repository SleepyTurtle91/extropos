import 'package:extropos/models/loyalty_member.dart';
import 'package:extropos/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'member_management_screen_ui.dart';
part 'member_management_screen_dialogs.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  late List<LoyaltyMember> allMembers = [];
  late List<LoyaltyMember> filteredMembers = [];
  TextEditingController searchController = TextEditingController();
  String selectedSort = 'name';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() async {
    try {
      final members = await LoyaltyService.instance.getAllMembers();
      setState(() {
        allMembers = members;
        _filterAndSort();
      });
    } catch (e) {
      print('❌ Error loading members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading members: $e')),
      );
    }
  }

  void _filterAndSort() {
    var filtered = allMembers;

    // Apply search
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();
      filtered = filtered.where((member) {
        return member.name.toLowerCase().contains(query) ||
            member.phone.toLowerCase().contains(query) ||
            member.email.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sort
    switch (selectedSort) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'points':
        filtered.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        break;
      case 'tier':
        filtered.sort((a, b) => b.currentTier.compareTo(a.currentTier));
        break;
      case 'joined':
        filtered.sort((a, b) => b.joinDate.compareTo(a.joinDate));
        break;
    }

    setState(() => filteredMembers = filtered);
  }

  Future<void> addMember(String name, String phone, String email) async {
    try {
      final newMember = LoyaltyMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        email: email,
        joinDate: DateTime.now(),
        currentTier: 'Silver',
        totalPoints: 0,
        redeemedPoints: 0,
        lastPurchaseDate: DateTime.now(),
        totalSpent: 0.0,
      );

      await LoyaltyService.instance.addMember(newMember);

      if (mounted) {
        setState(() => _loadMembers());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member "$name" added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding member: $e')),
      );
    }
  }

  Future<void> updateMember(LoyaltyMember member, String name, String phone,
      String email) async {
    try {
      final updatedMember = member.copyWith(
        name: name,
        phone: phone,
        email: email,
      );

      await LoyaltyService.instance.updateMember(updatedMember);

      if (mounted) {
        setState(() => _loadMembers());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating member: $e')),
      );
    }
  }

  Future<void> deleteMember(LoyaltyMember member) async {
    try {
      await LoyaltyService.instance.deleteMember(member.id);

      if (mounted) {
        setState(() => _loadMembers());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting member: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('See member_management_screen_ui.dart');
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
