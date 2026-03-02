import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetupStep3Panel extends StatefulWidget {
  final TextEditingController ownerNameCtrl;
  final TextEditingController ownerEmailCtrl;
  final TextEditingController ownerPinCtrl;
  final TextEditingController confirmPinCtrl;
  final VoidCallback onChanged;

  static const _amber = Color(0xFFF59E0B);
  static const _rose = Color(0xFFF43F5E);

  const SetupStep3Panel({
    required this.ownerNameCtrl,
    required this.ownerEmailCtrl,
    required this.ownerPinCtrl,
    required this.confirmPinCtrl,
    required this.onChanged,
    super.key,
  });

  @override
  State<SetupStep3Panel> createState() => _SetupStep3PanelState();
}

class _SetupStep3PanelState extends State<SetupStep3Panel> {
  @override
  Widget build(BuildContext context) {
    final pinMismatch = widget.confirmPinCtrl.text.isNotEmpty &&
        widget.ownerPinCtrl.text.trim() != widget.confirmPinCtrl.text.trim();

    return SingleChildScrollView(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            Icons.person,
            SetupStep3Panel._amber,
            Colors.amber.shade50,
            'Owner Setup',
            'Create the primary manager account for the system.',
          ),
          const SizedBox(height: 40),
          _buildInputLabel('MANAGER NAME'),
          TextFormField(
            controller: widget.ownerNameCtrl,
            onChanged: (_) => widget.onChanged(),
            decoration: _inputDecoration('e.g. Alex Johnson'),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 24),
          _buildInputLabel('MANAGER EMAIL (OPTIONAL)'),
          TextFormField(
            controller: widget.ownerEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('e.g. alex@example.com'),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('4-DIGIT PIN'),
                    TextFormField(
                      controller: widget.ownerPinCtrl,
                      onChanged: (_) => widget.onChanged(),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _pinInputDecoration(false),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('CONFIRM PIN'),
                    TextFormField(
                      controller: widget.confirmPinCtrl,
                      onChanged: (_) => widget.onChanged(),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _pinInputDecoration(pinMismatch),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pinMismatch)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'PINs do not match.',
                style: TextStyle(
                  color: SetupStep3Panel._rose,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStepHeader(
    IconData icon,
    Color color,
    Color bgColor,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }

  InputDecoration _pinInputDecoration(bool isError) {
    return InputDecoration(
      hintText: '....',
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 12),
        child: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
      ),
      filled: true,
      fillColor: isError ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isError ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isError ? const Color(0xFFFCA5A5) : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isError ? SetupStep3Panel._rose : SetupStep3Panel._amber,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }
}
