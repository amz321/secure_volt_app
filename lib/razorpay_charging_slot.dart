import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Assuming your status page is named this, adjust if different
import 'booking_status.dart';

class PaymentScreenChargingSlot extends StatefulWidget {
  final String amount;
  final String rid; // Charging slot request ID

  const PaymentScreenChargingSlot({
    Key? key,
    required this.amount,
    required this.rid,
  }) : super(key: key);

  @override
  State<PaymentScreenChargingSlot> createState() => _PaymentScreenChargingSlotState();
}

class _PaymentScreenChargingSlotState extends State<PaymentScreenChargingSlot> with SingleTickerProviderStateMixin {
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
      final uri = Uri.parse('$ip/raz_pay_charging_slot/');

      final response = await http.post(uri, body: {'amount': widget.amount, 'sid': widget.rid});

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
      'description': 'EV Charging Slot Payment',
      'order_id': order['order_id'],
      'prefill': {'contact': '9876543210', 'email': 'user@securevolt.com'},
      'theme': {'color': '#433422'}, // Bressay Dark
    };
    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final sh = await SharedPreferences.getInstance();
    final ip = sh.getString('url') ?? "";
    final uri = Uri.parse('$ip/payment_success/'); // Updated path

    try {
      await http.post(uri, body: {'rid': widget.rid, 'payment_id': response.paymentId});
      _showSnack('Payment Confirmed! ⚡');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserRequestStatusPage()));
    } catch (e) {
      _showSnack('Sync failed, contact support', isError: true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) => _showSnack('Payment Cancelled', isError: true);
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
                        const SizedBox(height: 40),
                        _buildAnimatedIcon(),
                        const SizedBox(height: 24),
                        Text("Secure Volt Pay", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: bressayDark)),
                        Text("Verified Checkout", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w600)),
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

  Widget _buildAnimatedIcon() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: bressayBrown.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Icon(Icons.bolt_rounded, size: 60, color: bressayBrown),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: bressayDark,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          _summaryRow("Request ID", "#${widget.rid}"),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Payable", style: TextStyle(color: Colors.white70, fontSize: 16)),
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
            : Text("PAY ₹${widget.amount} NOW", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildTrustFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text("PCI-DSS Certified Secure Payment", style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: 0.5,
          child: Image.network("https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Razorpay_logo.svg/1200px-Razorpay_logo.svg.png", height: 15),
        ),
      ],
    );
  }
}