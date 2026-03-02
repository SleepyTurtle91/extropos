part of 'refund_service_screen.dart';

/// Extension containing authorization panel UI for PIN entry
extension RefundServiceAuthPanel on _RefundServiceScreenState {
  /// Build manager PIN authorization panel
  Widget buildAuthPanel() {
    return Center(
      key: const ValueKey('auth'),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(48), border: Border.all(color: AppColors.slate100)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.rose600, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.lock, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Security Verification', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slate900)),
            const SizedBox(height: 8),
            Text(isWholeBill ? 'CRITICAL: Full transaction void.' : 'Required for partial return.', style: const TextStyle(fontSize: 14, color: AppColors.slate400)),
            const SizedBox(height: 8),
            Text('RM ${refundTotal.toStringAsFixed(2)} via $_refundMethod', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.rose600)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool active = _managerPin.length > index;
                return Container(
                  width: 56, height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.rose50 : AppColors.slate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? AppColors.rose600 : AppColors.slate100, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: active ? const Text('•', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.rose600)) : null,
                );
              }),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 300,
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: ['1','2','3','4','5','6','7','8','9','C','0','DEL'].map((key) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (key == 'C') {
                          _managerPin = '';
                        } else if (key == 'DEL') {
                          if (_managerPin.isNotEmpty) _managerPin = _managerPin.substring(0, _managerPin.length - 1);
                        } else {
                          if (_managerPin.length < 4) {
                            _managerPin += key;
                            if (_managerPin.length == 4) {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                setState(() => _currentView = RefundView.success);
                              });
                            }
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.transparent),
                      child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => setState(() {
                _currentView = RefundView.details;
                _managerPin = '';
              }),
              child: const Text('GO BACK', style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold, letterSpacing: 1)),
            )
          ],
        ),
      ),
    );
  }
}
