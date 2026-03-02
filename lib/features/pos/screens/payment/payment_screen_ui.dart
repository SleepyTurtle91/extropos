part of 'payment_screen.dart';

/// UI builder methods for PaymentScreen
extension PaymentScreenUI on _PaymentScreenState {
  /// Build the customer information section
  Widget buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Information Header
        const Text(
          'Customer Information (Optional)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Phone number field with customer search
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone),
            suffixIcon: _selectedCustomer != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearCustomer,
                    tooltip: 'Clear customer',
                  )
                : (_isSearchingCustomer
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : null),
            border: const OutlineInputBorder(),
            helperText: 'Search existing customer by phone',
          ),
          onChanged: _searchCustomerByPhone,
          enabled: _selectedCustomer == null,
        ),

        // Customer suggestions dropdown
        if (_customerSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _customerSuggestions.length,
              itemBuilder: (context, index) {
                final customer = _customerSuggestions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(
                    '${customer.phone ?? 'No phone'} • ${customer.customerTier} • ${customer.visitCount} visits',
                  ),
                  trailing: Text(
                    '${customer.loyaltyPoints} pts',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => _selectCustomer(customer),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Customer name field
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Customer Name',
            prefixIcon: const Icon(Icons.person),
            border: const OutlineInputBorder(),
            helperText: _selectedCustomer != null
                ? '${_selectedCustomer!.customerTier} customer • ${_selectedCustomer!.visitCount} visits'
                : 'Enter customer name',
          ),
          enabled: _selectedCustomer == null,
        ),

        const SizedBox(height: 12),

        // Email field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email (Optional)',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          enabled: _selectedCustomer == null,
        ),
      ],
    );
  }

  /// Build the payment method section
  Widget buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (widget.availablePaymentMethods.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No active payment methods available. Please add payment methods in settings.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          PaymentMethodSelectorWidget(
            availablePaymentMethods: widget.availablePaymentMethods,
            selectedPaymentMethod: _selectedPaymentMethod,
            onPaymentMethodChanged: (method) {
              _updateState(() => _selectedPaymentMethod = method);
            },
          ),
      ],
    );
  }

  /// Build the amount input section
  Widget buildAmountSection() {
    final currencySymbol = BusinessInfo.instance.currencySymbol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountInputWidget(
          amountController: _amountController,
          currencySymbol: currencySymbol,
          label: 'Payment Amount',
          hintText: 'Enter the amount received from customer',
          onChanged: (value) => _updateState(() {}),
        ),
        const SizedBox(height: 16),

        // Quick Cash Buttons (only show for cash payments)
        if (_selectedPaymentMethod != null &&
            _selectedPaymentMethod!.name.toLowerCase().contains('cash')) ...[
          const Text(
            'Quick Cash',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getCashSuggestions().take(4).map((amount) {
              final isExact = amount == widget.totalAmount;
              return OutlinedButton(
                onPressed: () => _selectCashAmount(amount),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: isExact
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade400,
                    width: isExact ? 2 : 1,
                  ),
                  backgroundColor: _enteredAmount == amount
                      ? const Color(0xFF2563EB).withOpacity(0.1)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$currencySymbol ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _enteredAmount == amount
                            ? const Color(0xFF2563EB)
                            : Colors.black87,
                      ),
                    ),
                    if (isExact)
                      const Text(
                        'Exact',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    else if (amount - widget.totalAmount > 0)
                      Text(
                        'Change: $currencySymbol${(amount - widget.totalAmount).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// Build the change display
  Widget buildChangeDisplay() {
    final currencySymbol = BusinessInfo.instance.currencySymbol;
    if (_enteredAmount <= widget.totalAmount) return const SizedBox.shrink();

    return Card(
      color: Color.fromRGBO(76, 175, 80, 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Change',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$currencySymbol ${_change.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the action buttons
  Widget buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackButtons = constraints.maxWidth < 520;
        final processButton = ElevatedButton(
          onPressed:
              _isProcessing || !_isValidPayment ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Text(
                  'Process Payment',
                  style: TextStyle(fontSize: 16),
                ),
        );

        final cancelButton = OutlinedButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Cancel'),
        );

        if (stackButtons) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              processButton,
              const SizedBox(height: 12),
              cancelButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: processButton),
            const SizedBox(width: 12),
            Expanded(child: cancelButton),
          ],
        );
      },
    );
  }
}
