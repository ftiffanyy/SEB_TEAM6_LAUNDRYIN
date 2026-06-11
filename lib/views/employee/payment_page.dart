import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final String customerName;
  final String serviceName;
  final int weight;
  final int pricePerKg;
  final int totalAmount;

  const PaymentPage({
    super.key,
    required this.customerName,
    required this.serviceName,
    required this.weight,
    required this.pricePerKg,
    required this.totalAmount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedMethod;

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void showPaymentResult(bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(isSuccess ? 'Payment Success' : 'Payment Failed'),
          content: Text(
            isSuccess
                ? 'Payment has been completed successfully.'
                : 'Payment was not successful.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                if (isSuccess && selectedMethod != null) {
                  Navigator.pop(context, selectedMethod);
                } else {
                  Navigator.pop(context, null);
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget paymentMethodCard(String method, IconData icon) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffEAF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xff4A90E2) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xff4A90E2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xff4A90E2),
              ),
          ],
        ),
      ),
    );
  }

  Widget dummyQr() {
    return Container(
      width: 180,
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 4,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.qr_code_2,
              size: 110,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget paymentDetailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xffEAF3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xff4A90E2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Detail',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Review payment summary before confirmation',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          paymentInfoRow(
            icon: Icons.person_outline,
            title: 'Customer',
            value: widget.customerName,
          ),
          paymentInfoRow(
            icon: Icons.local_laundry_service_outlined,
            title: 'Service',
            value: widget.serviceName,
          ),
          paymentInfoRow(
            icon: Icons.scale_outlined,
            title: 'Weight',
            value: '${widget.weight} kg',
          ),
          paymentInfoRow(
            icon: Icons.sell_outlined,
            title: 'Price per Kg',
            value: formatCurrency(widget.pricePerKg),
          ),

          const SizedBox(height: 10),

          Divider(
            color: Colors.grey.shade200,
            thickness: 1,
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffF4F8FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xffD5E6FF),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calculate_outlined,
                    color: Color(0xff4A90E2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calculation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff4A90E2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.weight} kg × ${formatCurrency(widget.pricePerKg)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xff4A90E2),
                  Color(0xff6BB6FF),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  formatCurrency(widget.totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xff4A90E2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showQr = selectedMethod == 'QRIS';

    return Scaffold(
      backgroundColor: const Color(0xffF4F7FB),
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: const Color(0xff4A90E2),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xff4A90E2),
                  Color(0xff6BB6FF),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.payments,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Process',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Complete customer payment',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          paymentDetailCard(),

          const SizedBox(height: 20),

          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          paymentMethodCard('Debit Card', Icons.payment),
          paymentMethodCard('Credit Card', Icons.credit_card),
          paymentMethodCard('QRIS', Icons.qr_code),

          if (showQr)
            Center(
              child: Column(
                children: [
                  dummyQr(),
                  const Text(
                    'Scan this dummy QRIS code',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          if (selectedMethod != null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showPaymentResult(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Payment Success'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showPaymentResult(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Payment Failed'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}