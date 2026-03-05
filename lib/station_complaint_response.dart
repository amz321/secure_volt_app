import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserStationComplaintStatusPage extends StatefulWidget {
  const UserStationComplaintStatusPage({super.key});

  @override
  State<UserStationComplaintStatusPage> createState() =>
      _UserStationComplaintStatusPageState();
}

class _UserStationComplaintStatusPageState
    extends State<UserStationComplaintStatusPage> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  String lid = "";
  bool isLoading = true;
  List complaints = [];

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
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/ViewStationComplaintResponse/"),
        body: {"lid": lid},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() {
          complaints = jsonData["charging"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
    setState(() => isLoading = false);
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
        title: Text("Station Responses",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.refresh_rounded, color: bressayBrown), onPressed: fetchComplaints),
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
            : complaints.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.only(top: 110, left: 20, right: 20, bottom: 20),
          itemCount: complaints.length,
          itemBuilder: (context, index) => _buildComplaintCard(complaints[index]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 60, color: bressayBrown.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("No station complaints found", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map c) {
    final String reply = c["reply"].toString();
    final bool isPending = reply.toLowerCase().contains("pending");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.ev_station_rounded, size: 18, color: bressayBrown),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(c["station"],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ],
                ),
              ),
              Text(c["date"].toString(), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.white),
          ),
          Text("YOUR COMPLAINT",
              style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(c["complaint"], style: TextStyle(color: bressayDark, fontSize: 14, height: 1.4)),
          const SizedBox(height: 15),

          // --- REPLY BUBBLE ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPending ? bressayBrown.withOpacity(0.05) : Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isPending ? bressayBrown.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("STATION REPLY",
                    style: TextStyle(color: isPending ? bressayBrown : Colors.green[700], fontWeight: FontWeight.w900, fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  isPending ? "Our team is looking into this." : reply,
                  style: TextStyle(
                    color: isPending ? bressayDark.withOpacity(0.6) : bressayDark,
                    fontSize: 13,
                    fontStyle: isPending ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}