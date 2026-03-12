import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_volt/razorpay_charging_slot.dart'; // CHARGING PAYMENT
import 'package:secure_volt/razorpay_maintainace.dart'; // MAINTENANCE PAYMENT
import 'package:secure_volt/service%20feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserRequestStatusPage extends StatefulWidget {
  const UserRequestStatusPage({super.key});

  @override
  State<UserRequestStatusPage> createState() => _UserRequestStatusPageState();
}

class _UserRequestStatusPageState extends State<UserRequestStatusPage> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  String lid = "";
  bool isLoading = true;
  List charging = [];
  List maintenance = [];
  String selectedTab = "charging";

  @override
  void initState() {
    super.initState();
    loadPrefAndFetch();
  }

  Future<void> loadPrefAndFetch() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      baseUrl = sp.getString("url") ?? "";
      lid = sp.getString("lid") ?? "";
    });
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/StationSlotStatusAndMaintainanceRequestStatus/"),
        body: {"lid": lid},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() {
          charging = jsonData["charging"] ?? [];
          maintenance = jsonData["maintenance"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Status Fetch Error: $e");
    }
    setState(() => isLoading = false);
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
        title: Text("Request Status",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayBrown), onPressed: fetchStatus),
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
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildTabSelector(),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: bressayBrown))
                  : (selectedTab == "charging" ? _buildChargingList() : _buildMaintenanceList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _tabItem("Charging", "charging"),
          _tabItem("Maintenance", "maintenance"),
        ],
      ),
    );
  }

  Widget _tabItem(String label, String value) {
    bool isSelected = selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? bressayDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isSelected ? Colors.white : bressayDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildChargingList() {
    if (charging.isEmpty) return _emptyState("No charging slots found");
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: charging.length,
      itemBuilder: (context, index) => _statusCard(charging[index], isCharging: true),
    );
  }

  Widget _buildMaintenanceList() {
    if (maintenance.isEmpty) return _emptyState("No maintenance records");
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: maintenance.length,
      itemBuilder: (context, index) => _statusCard(maintenance[index], isCharging: false),
    );
  }

  Widget _statusCard(Map data, {required bool isCharging}) {
    final status = data["status"].toString().toLowerCase();
    final String title = isCharging ? (data["station"] ?? "Station") : (data["service_name"] ?? "Service");
    final String price = isCharging ? data["amount"].toString() : data["service_price"].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 16)),
              Text("₹$price", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          if (isCharging) ...[
            _infoRow(Icons.bolt, "Slot: ${data["SLOT"]}"),
            _infoRow(Icons.calendar_today, "Date: ${data["booked_for_date"]}"),
          ] else ...[
            _infoRow(Icons.ev_station, "At: ${data["station"]}"),
            _infoRow(Icons.calendar_month, "Requested: ${data["date"]}"),
          ],
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF1F1F1))),

          _statusBadge(status),

          // --- PROCEED TO PAY BUTTON (approved) ---
          if (status == "approved") ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: bressayBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => isCharging
                      ? PaymentScreenChargingSlot(amount: price, rid: data["id"].toString())
                      : MaintainacePaymentScreen(amount: price, rid: data["id"].toString())
                  ));
                },
                child: const Text("PROCEED TO PAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          // --- FEEDBACK BUTTON (paid + maintenance only) ---
          if (status == "paid" && !isCharging) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: bressayBrown, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.star_rate_rounded, color: bressayBrown, size: 20),
                label: Text(
                  "GIVE FEEDBACK",
                  style: TextStyle(color: bressayBrown, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString("feedback_sid", data["sid"].toString());
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ServiceFeedback()),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor(status).withOpacity(.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(color: statusColor(status), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 12, color: bressayBrown),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ]),
    );
  }

  Widget _emptyState(String msg) => Center(child: Text(msg, style: TextStyle(color: bressayBrown)));
}