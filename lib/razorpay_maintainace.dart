import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_status.dart'; // Ensure this matches your file name for UserRequestStatusPage

class MaintainacePaymentScreen extends StatefulWidget {
  final String amount;
  final String rid; // Maintenance Request ID

  const MaintainacePaymentScreen({
    Key? key,
    required this.amount,
    required this.rid,
  }) : super(key: key);

  @override
  State<MaintainacePaymentScreen> createState() => _MaintainacePaymentScreenState();
}

class _MaintainacePaymentScreenState extends State<MaintainacePaymentScreen> with SingleTickerProviderStateMixin {
  late Razorpay _razorpay;
  bool _loading = false;

  // --- SECURE VOLT THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _createOrder() async {
    setState(() => _loading = true);
    try {
      final sh = await SharedPreferences.getInstance();
      final ip = sh.getString('url') ?? "";
      final uri = Uri.parse('$ip/raz_pay_maintenance/');

      final response = await http.post(uri, body: {
        'amount': widget.amount,
        'sid': widget.rid,
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'ok') return json;
      }
      _showSnack('Failed to initiate order', isError: true);
    } catch (e) {
      _showSnack('Network error: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
    return null;
  }

  Future<void> _openCheckout() async {
    final order = await _createOrder();
    if (order == null) return;

    var options = {
      'key': order['razorpay_api_key'],
      'amount': order['amount'],
      'currency': order['currency'],
      'name': 'Secure Volt',
      'description': 'Maintenance Service Payment',
      'order_id': order['order_id'],
      'prefill': {'contact': '9876543210', 'email': 'user@securevolt.com'},
      'theme': {'color': '#433422'}, // Bressay Dark
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      _showSnack('Checkout error: $e', isError: true);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final sh = await SharedPreferences.getInstance();
    final ip = sh.getString('url') ?? "";
    final uri = Uri.parse('$ip/payment_success_maintenance/'); // Ensure correct endpoint

    try {
      await http.post(uri, body: {
        'rid': widget.rid,
        'payment_id': response.paymentId,
      });
      _showSnack('✓ Payment Confirmed!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserRequestStatusPage()),
      );
    } catch (e) {
      _showSnack('Status update failed', isError: true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnack('❌ Failed: ${response.message}', isError: true);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showSnack('External Wallet: ${response.walletName}');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[800] : bressayDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: skyBlueBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: bressayDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Checkout",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Branding Icon
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Icon(Icons.build_circle, size: 70, color: bressayBrown),
            ),

            const SizedBox(height: 30),
            Text("Service Maintenance",
                style: TextStyle(color: bressayDark, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("Request ID: #${widget.rid}",
                style: TextStyle(color: bressayDark.withOpacity(0.5), fontWeight: FontWeight.w700)),

            const SizedBox(height: 40),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: bressayDark,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  _summaryRow("Base Service Fee", "₹${widget.amount}"),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Divider(color: Colors.white12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Payable",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text("₹${widget.amount}",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Payment Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bressayBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _openCheckout,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PROCEED TO PAY",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),

            const SizedBox(height: 30),

            // Trust Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 16, color: bressayDark.withOpacity(0.4)),
                const SizedBox(width: 8),
                Text("SECURE ENCRYPTED TRANSACTION",
                    style: TextStyle(color: bressayDark.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}