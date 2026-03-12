import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_volt/view_service_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserViewMaintenanceServices extends StatefulWidget {
  const UserViewMaintenanceServices({super.key});

  @override
  State<UserViewMaintenanceServices> createState() =>
      _UserViewMaintenanceServicesState();
}

class _UserViewMaintenanceServicesState
    extends State<UserViewMaintenanceServices> {
  // --- SECURE VOLT THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  bool isLoading = true;
  List services = [];

  @override
  void initState() {
    super.initState();
    loadPrefAndFetch();
  }

  Future<void> loadPrefAndFetch() async {
    final sp = await SharedPreferences.getInstance();
    baseUrl = sp.getString("url") ?? "";
    fetchServices();
  }

  // ================= FETCH SERVICES =================
  Future<void> fetchServices() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final sid = sp.getString("sid");

      final res = await http.post(
        Uri.parse("$baseUrl/UserViewmaintainanceServices/"),
        body: {"sid": sid},
      );

      final jsonData = json.decode(res.body);

      if (jsonData["status"] == "ok") {
        setState(() {
          services = jsonData["data"];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnack("Connection error: $e", isError: true);
    }
  }

  // ================= REQUEST SERVICE =================
  Future<void> requestService(String serviceId) async {
    // Show a quick loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final sp = await SharedPreferences.getInstance();
      final lid = sp.getString("lid");

      final res = await http.post(
        Uri.parse("$baseUrl/UserRequestServices/"),
        body: {
          "service_id": serviceId,
          "lid": lid,
        },
      );

      Navigator.pop(context); // Remove loading dialog

      final data = json.decode(res.body);
      if (data["status"] == "ok") {
        _showSnack("✓ Request sent! Track status in My Requests.");
      } else {
        _showSnack("Could not complete request", isError: true);
      }
    } catch (e) {
      Navigator.pop(context);
      _showSnack("Error: $e", isError: true);
    }
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

  // ================= UI =================
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
        title: Text(
          "Service Catalog",
          style: TextStyle(
            color: bressayDark,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
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
            : services.isEmpty
            ? _buildEmptyState()
            : _buildServiceList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_outlined, size: 80, color: bressayBrown.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No maintenance services currently\navailable at this station.",
            textAlign: TextAlign.center,
            style: TextStyle(color: bressayDark.withOpacity(0.6), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: bressayDark.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top accent bar
                Container(height: 6, width: double.infinity, color: bressayBrown),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s["name"],
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: bressayDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: skyBlueBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "₹${s["price"]}",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: bressayDark,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 14, color: bressayBrown),
                          const SizedBox(width: 6),
                          Text(
                            s["type"].toString().toUpperCase(),
                            style: TextStyle(
                              color: bressayBrown,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFFEEEEEE)),
                      ),
                      Text(
                        "Description",
                        style: TextStyle(
                          color: bressayDark.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s["details"],
                        style: TextStyle(
                          color: bressayDark.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: bressayBrown),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ViewServiceFeedback(),
                                ),
                              ),
                              icon: Icon(Icons.star_outline, color: bressayBrown, size: 18),
                              label: Text(
                                "REVIEWS",
                                style: TextStyle(
                                  color: bressayBrown,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bressayDark,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => requestService(s["id"].toString()),
                              child: const Text(
                                "BOOK NOW",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
