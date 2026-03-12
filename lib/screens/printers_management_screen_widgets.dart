part of 'printers_management_screen.dart';

// Widget builder methods extracted from _PrintersManagementScreenState
extension _PrintersManagementWidgets on _PrintersManagementScreenState {
  Widget _buildJobToggle({
    required String title,
    required String description,
    required IconData icon,
    required bool isActive,
    required VoidCallback onToggle,
    Widget? expandedContent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFEEF2FF).withOpacity(0.5) : Colors.white,
        border: Border.all(
          color: isActive ? const Color(0xFF4F46E5) : Colors.grey.shade100,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE0E7FF)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isActive
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 56,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isActive ? const Color(0xFF4F46E5) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment:
                          isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expandedContent != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: expandedContent,
            )
        ],
      ),
    );
  }

}