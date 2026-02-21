import 'package:extropos/screens/frontend_home_screen.dart';
import 'package:flutter/material.dart';

enum OrderType { dineIn, takeaway }

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  OrderType? _selectedOrderType;
  String? _tableNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Logo/Brand Section
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 80, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome to FlutterPOS',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your dining option',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Order Type Selection
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Dine In Option
                      _buildOrderTypeCard(
                        title: 'Dine In',
                        subtitle: 'Order at your table',
                        icon: Icons.table_restaurant,
                        orderType: OrderType.dineIn,
                        onTap: () => _selectOrderType(OrderType.dineIn),
                      ),

                      const SizedBox(height: 16),

                      // Takeaway Option
                      _buildOrderTypeCard(
                        title: 'Takeaway',
                        subtitle: 'Order for pickup',
                        icon: Icons.takeout_dining,
                        orderType: OrderType.takeaway,
                        onTap: () => _selectOrderType(OrderType.takeaway),
                      ),

                      // Table Number Input (shown only for Dine In)
                      if (_selectedOrderType == OrderType.dineIn) ...[
                        const SizedBox(height: 24),
                        _buildTableNumberInput(),
                      ],
                    ],
                  ),
                ),

                // Continue Button
                if (_selectedOrderType != null &&
                    (_selectedOrderType != OrderType.dineIn ||
                        _tableNumber != null)) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continueToMenu,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue to Menu'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required OrderType orderType,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedOrderType == orderType;

    return Card(
      elevation: isSelected ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.white : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableNumberInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Table Number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g., 12',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _tableNumber = value.trim();
              });
            },
          ),
        ],
      ),
    );
  }

  void _selectOrderType(OrderType orderType) {
    setState(() {
      _selectedOrderType = orderType;
      if (orderType == OrderType.takeaway) {
        _tableNumber = null; // Clear table number for takeaway
      }
    });
  }

  void _continueToMenu() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FrontendHomeScreen(
          orderType: _selectedOrderType!,
          tableNumber: _tableNumber,
        ),
      ),
    );
  }
}
