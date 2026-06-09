import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final String customerName;
  final String serviceName;
  final int totalAmount;

  const PaymentPage({
    super.key,
    required this.customerName,
    required this.serviceName,
    required this.totalAmount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? selectedMethod;

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
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xff4A90E2)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xff4A90E2)),
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
      ),
      child: Center(
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 4),
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
                colors: [Color(0xff4A90E2), Color(0xff6BB6FF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(Icons.payments, color: Colors.white, size: 42),
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
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Detail',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Customer: ${widget.customerName}'),
                Text('Service: ${widget.serviceName}'),
                const SizedBox(height: 10),
                Text(
                  'Total: Rp ${widget.totalAmount}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff4A90E2),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Select Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: Colors.grey),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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