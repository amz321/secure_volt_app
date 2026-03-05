import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secure_volt/profile.dart';
import 'package:secure_volt/view_charging_stations.dart';
import 'package:secure_volt/view_parking.dart';
import 'package:secure_volt/login.dart';
import 'package:secure_volt/parking_booking_status.dart';
import 'package:secure_volt/station_complaint_response.dart';
import 'package:secure_volt/app_complaints.dart';
import 'package:secure_volt/app_feedback.dart';
import 'package:secure_volt/bills.dart';
import 'package:secure_volt/booking_status.dart';
import 'package:secure_volt/change_password.dart';
import 'package:secure_volt/manage_my_ev.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String name = "User";
  String email = "";
  String photo = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ip = prefs.getString('url') ?? "";
    String lid = prefs.getString('lid') ?? "";
    try {
      final response = await http.post(Uri.parse("$ip/view_profile_flutter/"), body: {"lid": lid});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          name = data['name'] ?? "User";
          email = data['email'] ?? "";
          photo = data['photo'] ?? "";
          isLoading = false;
        });
      }
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [skyBlueBg, Colors.white]
            )
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: bressayBrown))
            : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildHighlights(), // Charging & Parking
                const SizedBox(height: 35),
                Text("SERVICES & MANAGEMENT",
                    style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
                const SizedBox(height: 15),

                // --- ALL FUNCTIONS IN WHITE CARDS ---
                _buildWhiteCardTile("My Profile", Icons.person_outline, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewProfile()))),
                _buildWhiteCardTile("Manage My EV", Icons.ev_station_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ManageVehiclePage()))),
                _buildWhiteCardTile("Booking & Maintenance", Icons.analytics_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserRequestStatusPage()))),
                _buildWhiteCardTile("Parking Status", Icons.garage_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParkingBookingStatusPage()))),
                _buildWhiteCardTile("Station Responses", Icons.feedback_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserStationComplaintStatusPage()))),
                _buildWhiteCardTile("Billing History", Icons.paid_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => UserFullBillPage()))),
                _buildWhiteCardTile("Report App Issues", Icons.bug_report_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintPage()))),
                _buildWhiteCardTile("App Feedback", Icons.star_outline, () => Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackPage()))),
                _buildWhiteCardTile("Change Password", Icons.lock_reset_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePassword()))),
                _buildWhiteCardTile("Logout", Icons.logout_rounded, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => login())), isLogout: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(radius: 28, backgroundColor: bressayBrown, backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null, child: photo.isEmpty ? Icon(Icons.person, color: Colors.white) : null),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Hello, $name", style: TextStyle(color: bressayDark, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ]),
      ],
    );
  }

  Widget _buildHighlights() {
    return Row(children: [
      Expanded(child: _highlightCard("Charging\nStations", Icons.ev_station, bressayDark, () => Navigator.push(context, MaterialPageRoute(builder: (context) => NearestStationsPage())))),
      const SizedBox(width: 15),
      Expanded(child: _highlightCard("Parking\nAreas", Icons.local_parking_outlined, bressayBrown, () => Navigator.push(context, MaterialPageRoute(builder: (context) => ParkingNearMePage())))),
    ]);
  }

  Widget _highlightCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20), height: 150,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: Colors.white, size: 35),
          Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
      ),
    );
  }

  Widget _buildWhiteCardTile(String title, IconData icon, VoidCallback onTap, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, // Solid white background
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: bressayDark.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isLogout ? Colors.red.withOpacity(0.1) : bressayBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: isLogout ? Colors.redAccent : bressayBrown, size: 22),
        ),
        title: Text(title,
            style: TextStyle(
                color: isLogout ? Colors.redAccent : bressayDark,
                fontWeight: FontWeight.w700,
                fontSize: 14
            )
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      ),
    );
  }
}