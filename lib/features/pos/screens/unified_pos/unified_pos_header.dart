part of 'unified_pos_screen.dart';

extension _UnifiedPOSHeader on _UnifiedPOSScreenState {
  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200, width: 1),
            ),
            child: IconButton(
              onPressed: () => _updateState(() => isSidebarCollapsed = !isSidebarCollapsed),
              icon: Icon(
                Icons.menu,
                color: Colors.blue.shade700,
                size: 20,
              ),
              tooltip: 'Toggle sidebar',
            ),
          ),
          const SizedBox(width: 16),
          if (activeMode == POSMode.restaurant && selectedTableId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100],
                  ),
                  border: Border.all(color: Colors.green.shade300, width: 1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.table_restaurant, color: Colors.green.shade700, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      selectedTableId ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _updateState(() => selectedTableId = null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.green.shade800, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => _updateState(() => searchQuery = v),
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    hintText: 'Search products...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return ListenableBuilder(
      listenable: UserSessionService(),
      builder: (context, _) {
        final currentUser = UserSessionService().currentActiveUser;
        
        if (currentUser == null) {
          // No user signed in - show placeholder
          return Tooltip(
            message: 'No cashier signed in',
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          );
        }

        // Get user initials (first letter of first and last name)
        final nameParts = currentUser.fullName.trim().split(' ');
        final initials = nameParts.length > 1
            ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
            : currentUser.fullName.isNotEmpty
                ? currentUser.fullName[0].toUpperCase()
                : '?';

        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          tooltip: 'User Profile',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currentUser.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    currentUser.roleDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
            ],
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (currentUser.phoneNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      currentUser.phoneNumber!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'sign_out',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 12),
                  Text('Sign Out'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'sign_out') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => const SignOutDialogSimple(),
              );
              
              if (confirmed == true && context.mounted) {
                // User confirmed sign out
                // The dialog already handles the sign out logic
                ToastHelper.showToast(
                  context,
                  'Signed out successfully',
                );
              }
            }
          },
        );
      },
    );
  }
}
