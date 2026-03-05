import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_volt/razorpay.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParkingBookingStatusPage extends StatefulWidget {
  const ParkingBookingStatusPage({super.key});

  @override
  State<ParkingBookingStatusPage> createState() =>
      _ParkingBookingStatusPageState();
}

class _ParkingBookingStatusPageState extends State<ParkingBookingStatusPage> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  String lid = "";
  bool isLoading = false;
  List bookings = [];

  @override
  void initState() {
    super.initState();
    loadPref();
  }

  Future<void> loadPref() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      baseUrl = sp.getString("url") ?? "";
      lid = sp.getString("lid") ?? "";
    });
    fetchBookingStatus();
  }

  Future<void> fetchBookingStatus() async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/ViewParkingBookingStatus/"),
        body: {"lid": lid},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() => bookings = jsonData["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => isLoading = false);
  }

  void payNow(Map booking) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PaymentScreen(
              amount: booking["amount"].toString(),
              rid: booking["id"].toString(),
            )
        )
    );
  }

  Color statusColor(String status) {
    status = status.toLowerCase();
    if (status == "pending") return Colors.orange;
    if (status == "approved") return Colors.blue;
    if (status == "rejected") return Colors.red;
    if (status == "paid") return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: bressayDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Parking Status",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
            onPressed: fetchBookingStatus,
            icon: Icon(Icons.refresh_rounded, color: bressayBrown),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skyBlueBg, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: bressayBrown))
            : bookings.isEmpty
            ? Center(child: Text("No bookings found", style: TextStyle(color: bressayBrown)))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 110, left: 20, right: 20, bottom: 20),
          itemCount: bookings.length,
          itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map b) {
    final status = (b["status"] ?? "").toString().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(b["parking_name"] ?? "Parking Area",
                  style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 16)),
              Icon(Icons.local_parking_rounded, color: bressayBrown, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.access_time, "Time: ${b["parking_fromtime"]} - ${b["parking_totime"]}"),
          _infoRow(Icons.calendar_month_outlined, "Booked: ${b["booking_date"]} to ${b["booking_to"]}"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F1F1)),
          ),

          // --- STATUS SECTION ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor(status).withOpacity(.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: statusColor(status), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusMsg(status),
                    style: TextStyle(color: statusColor(status), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          if (status == "approved") ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bressayDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ),
                onPressed: () => payNow(b),
                child: const Text("PROCEED TO PAY",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],

          if (status == "paid") ...[
            const SizedBox(height: 12),
            Center(
              child: Text("Booking Confirmed ✅",
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }

  String _getStatusMsg(String status) {
    if (status == "pending") return "Verification Pending";
    if (status == "approved") return "Approved! Please pay to confirm";
    if (status == "rejected") return "Booking Rejected";
    if (status == "paid") return "Slot Secured Successfully";
    return status.toUpperCase();
  }
}