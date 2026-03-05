import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:secure_volt/parking_booking_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentScreen extends StatefulWidget {
  final String amount;
  final String rid; // Parking Booking ID

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.rid,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  late Razorpay _razorpay;
  bool _loading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _animController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _createOrder() async {
    setState(() => _loading = true);
    try {
      final sh = await SharedPreferences.getInstance();
      final ip = sh.getString('url') ?? "";
      final uri = Uri.parse('$ip/raz_pay_parking/');

      final response = await http.post(uri, body: {
        'amount': widget.amount,
        'sid': widget.rid,
      });

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'ok') return json;
      }
    } catch (e) {
      debugPrint("Order Error: $e");
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
      'description': 'Parking Slot Payment',
      'order_id': order['order_id'],
      'prefill': {'contact': '9876543210', 'email': 'user@securevolt.com'},
      'theme': {'color': '#433422'},
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final sh = await SharedPreferences.getInstance();
    final ip = sh.getString('url') ?? "";
    final uri = Uri.parse('$ip/payment_success_parking/'); // Targeted parking endpoint

    try {
      await http.post(uri, body: {
        'rid': widget.rid,
        'payment_id': response.paymentId,
      });
      _showSnack('✓ Parking Secured! 🚗');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParkingBookingStatusPage()),
      );
    } catch (e) {
      _showSnack('Sync error, contact support', isError: true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) => _showSnack('Transaction Cancelled', isError: true);
  void _handleExternalWallet(ExternalWalletResponse response) => _showSnack('Wallet: ${response.walletName}');

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[800] : bressayDark,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skyBlueBg, Colors.white],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildParkingIcon(),
                        const SizedBox(height: 20),
                        Text("Secure Volt Pay", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: bressayDark)),
                        Text("Instant Parking Confirmation", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 40),
                        _buildSummaryCard(),
                        const SizedBox(height: 40),
                        _buildPayButton(),
                        const SizedBox(height: 30),
                        _buildTrustFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: bressayDark, size: 20),
          ),
          const SizedBox(width: 10),
          Text("Checkout", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: bressayDark)),
        ],
      ),
    );
  }

  Widget _buildParkingIcon() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Icon(Icons.local_parking_rounded, size: 60, color: bressayBrown),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: bressayDark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          _summaryRow("Booking Ref", "#${widget.rid}"),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Parking Fee", style: TextStyle(color: Colors.white70, fontSize: 16)),
              Text("₹${widget.amount}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _loading ? null : _openCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: bressayBrown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("PROCEED TO SECURE PAYMENT", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildTrustFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text("Encrypted by Razorpay", style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}