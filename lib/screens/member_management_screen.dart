import 'package:extropos/models/loyalty_member.dart';
import 'package:extropos/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  void showAddMemberDialog() {
    String name = '';
    String phone = '';
    String email = '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Member'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Member Name *',
                    hintText: 'Enter full name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => name = value,
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'e.g., 0123456789',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => phone = value,
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'e.g., member@email.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => email = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: name.isNotEmpty && phone.isNotEmpty
                ? () {
                    addMember(name, phone, email);
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Add Member'),
          ),
        ],
      ),
    );
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

  void showEditMemberDialog(LoyaltyMember member) {
    String name = member.name;
    String phone = member.phone;
    String email = member.email;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Member'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Member Name',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: name),
                  onChanged: (value) => name = value,
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  controller: TextEditingController(text: phone),
                  onChanged: (value) => phone = value,
                ),
                SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  controller: TextEditingController(text: email),
                  onChanged: (value) => email = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              updateMember(member, name, phone, email);
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
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

  void showDeleteConfirmDialog(LoyaltyMember member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete "${member.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              deleteMember(member);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Management'),
        backgroundColor: Color(0xFF2563EB),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildSortSection(),
          Expanded(child: _buildMembersList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddMemberDialog,
        backgroundColor: Color(0xFF2563EB),
        child: Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or email...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => _filterAndSort(),
      ),
    );
  }

  Widget _buildSortSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('By Name'),
            selected: selectedSort == 'name',
            onSelected: (selected) {
              setState(() => selectedSort = 'name');
              _filterAndSort();
            },
          ),
          FilterChip(
            label: const Text('By Points'),
            selected: selectedSort == 'points',
            onSelected: (selected) {
              setState(() => selectedSort = 'points');
              _filterAndSort();
            },
          ),
          FilterChip(
            label: const Text('By Tier'),
            selected: selectedSort == 'tier',
            onSelected: (selected) {
              setState(() => selectedSort == 'tier');
              _filterAndSort();
            },
          ),
          FilterChip(
            label: const Text('By Joined'),
            selected: selectedSort == 'joined',
            onSelected: (selected) {
              setState(() => selectedSort = 'joined');
              _filterAndSort();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No members found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 600) columns = 2;
        if (constraints.maxWidth >= 900) columns = 3;

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredMembers.length,
          itemBuilder: (context, index) {
            final member = filteredMembers[index];
            return _buildMemberCard(member);
          },
        );
      },
    );
  }

  Widget _buildMemberCard(LoyaltyMember member) {
    final tierColor = _getTierColor(member.currentTier);
    final joinedDate = DateFormat('MMM d, y').format(member.joinDate);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    member.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      showEditMemberDialog(member);
                    } else if (value == 'delete') {
                      showDeleteConfirmDialog(member);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                member.currentTier,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tierColor,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              member.phone,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (member.email.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                member.email,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      '${member.totalPoints}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      'RM ${member.totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Joined: $joinedDate',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
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

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
