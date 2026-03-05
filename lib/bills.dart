import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserFullBillPage extends StatefulWidget {
  const UserFullBillPage({super.key});

  @override
  State<UserFullBillPage> createState() => _UserFullBillPageState();
}

class _UserFullBillPageState extends State<UserFullBillPage> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  String lid = "";
  bool isLoading = true;

  List charging = [];
  List parking = [];
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
    fetchBills();
  }

  Future<void> fetchBills() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/UserViewFullBillDetails/"),
        body: {"lid": lid},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() {
          charging = jsonData["charging"] ?? [];
          parking = jsonData["parking"] ?? [];
          maintenance = jsonData["maintenance"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
    setState(() => isLoading = false);
  }

  Color statusColor(String status) {
    status = status.toLowerCase();
    if (status == "paid") return Colors.green;
    if (status == "pending") return Colors.orange;
    if (status == "approved") return Colors.blue;
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
        title: Text("Transaction History",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skyBlueBg, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: bressayBrown))
            : Column(
          children: [
            const SizedBox(height: 100),
            // --- CUSTOM TAB FILTER ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  _tabButton("Charging", "charging"),
                  _tabButton("Parking", "parking"),
                  _tabButton("Maintenance", "maintenance"),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, String value) {
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
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildList() {
    List data;
    if (selectedTab == "charging") data = charging;
    else if (selectedTab == "parking") data = parking;
    else data = maintenance;

    if (data.isEmpty) {
      return Center(
          child: Text("No transactions found",
              style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w600)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: data.length,
      itemBuilder: (_, i) {
        final b = data[i];
        final String status = b["status"].toString().toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(b["station"] ?? "Service Provider",
                        style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  Text("₹${b["amount"]}",
                      style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: bressayBrown),
                  const SizedBox(width: 5),
                  Text("${b["date"] ?? b["from_date"]}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF1F1F1)),
              ),
              if (b.containsKey("slot_time")) _receiptRow("Slot Time", b["slot_time"]),
              if (b.containsKey("service_name")) _receiptRow("Service", b["service_name"]),
              if (b.containsKey("details")) _receiptRow("Details", b["details"]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor(status).withOpacity(.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(status,
                        style: TextStyle(color: statusColor(status), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                  ),
                  Text("SECURE VOLT ID: #EV${b.hashCode.toString().substring(0,4).toUpperCase()}",
                      style: TextStyle(color: Colors.grey[300], fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          Text(value, style: TextStyle(color: bressayDark, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}