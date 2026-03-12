import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:secure_volt/view_maintainance_services.dart';
import 'package:secure_volt/view_service_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class NearestServiceCentersPage extends StatefulWidget {
  const NearestServiceCentersPage({super.key});

  @override
  State<NearestServiceCentersPage> createState() => _NearestServiceCentersPageState();
}

class _NearestServiceCentersPageState extends State<NearestServiceCentersPage> {
  // --- SECURE VOLT THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  bool isLoading = false;
  Position? currentPosition;

  List allCenters = [];
  List filteredCenters = [];
  List<String> centerTypes = ["All"];
  String selectedType = "All";

  @override
  void initState() {
    super.initState();
    loadPrefAndFetch();
  }

  Future<void> loadPrefAndFetch() async {
    final sp = await SharedPreferences.getInstance();
    baseUrl = sp.getString("url") ?? "";
    fetchServiceCenters();
  }

  // ================= FETCH DATA =================
  Future<void> fetchServiceCenters() async {
    setState(() => isLoading = true);

    try {
      // Pointing to your new Django userviewservices function
      final res = await http.get(Uri.parse("$baseUrl/userviewservices/"));
      final jsonData = json.decode(res.body);

      if (jsonData["status"] == "ok") {
        allCenters = jsonData["data"] ?? [];

        // Extract unique types for the dropdown dynamically
        Set<String> types = {"All"};
        for (var center in allCenters) {
          if (center["type"] != null) {
            types.add(center["type"].toString());
          }
        }
        centerTypes = types.toList();

        applyFilterAndSort();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // ================= HELPERS & LOGIC =================
  Future<void> getMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => currentPosition = pos);
    applyFilterAndSort();
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void applyFilterAndSort() {
    List temp = List.from(allCenters);
    if (selectedType != "All") {
      temp = temp.where((s) => s["type"] == selectedType).toList();
    }
    if (currentPosition != null) {
      for (var s in temp) {
        s["distance"] = calculateDistanceKm(
          currentPosition!.latitude,
          currentPosition!.longitude,
          double.tryParse(s["lat"].toString()) ?? 0,   // Updated to use 'lat' from your API
          double.tryParse(s["long"].toString()) ?? 0,  // Updated to use 'long' from your API
        );
      }
      temp.sort((a, b) => (a["distance"] ?? 99999).compareTo(b["distance"] ?? 99999));
    }
    setState(() => filteredCenters = temp);
  }

  Future<void> openGoogleMaps(double lat, double lon) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lon&mode=d");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ================= UI BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Service Centers", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayDark), onPressed: fetchServiceCenters),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [skyBlueBg, Colors.white])),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: bressayBrown))
            : Column(
          children: [
            const SizedBox(height: 100),
            _buildControls(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: filteredCenters.length,
                itemBuilder: (context, index) {
                  final s = filteredCenters[index];
                  return _buildCenterCard(s);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: bressayDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.my_location, size: 18, color: Colors.white),
              label: Text(currentPosition == null ? "Sort by Distance" : "Nearest Active", style: const TextStyle(color: Colors.white, fontSize: 12)),
              onPressed: getMyLocation,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedType,
                style: TextStyle(color: bressayDark, fontWeight: FontWeight.bold),
                items: centerTypes.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase(), style: const TextStyle(fontSize: 11)))).toList(),
                onChanged: (val) {
                  setState(() => selectedType = val!);
                  applyFilterAndSort();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterCard(Map s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Image & Type Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                // Updated to use 'photo' from your API
                child: Image.network(s["photo"], height: 180, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180, width: double.infinity, color: Colors.grey[300], child: const Icon(Icons.image_not_supported),
                    )),
              ),
              Positioned(
                top: 15, left: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: bressayDark, borderRadius: BorderRadius.circular(20)),
                  child: Text(s["type"].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              if (s["distance"] != null)
                Positioned(
                  bottom: 10, right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Text("${s["distance"].toStringAsFixed(1)} km", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s["name"], style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: bressayDark)),
                Text(s["place"], style: TextStyle(color: Colors.grey[600], fontSize: 14)),

                // Displaying the email returned from your API
                if (s["email"] != null && s["email"].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.email, size: 14, color: bressayBrown),
                        const SizedBox(width: 5),
                        Text(s["email"], style: TextStyle(color: bressayBrown, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Request Maintenance Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: bressayDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      final sh = await SharedPreferences.getInstance();
                      // Saving ID if it's returned by Django, otherwise just fallback empty
                      sh.setString('sid', s['id']?.toString() ?? '');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserViewMaintenanceServices()));
                    },
                    child: const Text("REQUEST MAINTENANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Get Directions Text Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final sh = await SharedPreferences.getInstance();
                        sh.setString('sid', s['id']?.toString() ?? '');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewServiceFeedback()));
                      },
                      icon: Icon(Icons.reviews_outlined, color: bressayBrown),
                      label: Text("View Reviews", style: TextStyle(color: bressayBrown)),
                    ),
                    TextButton.icon(
                      // Updated to parse 'lat' and 'long' exactly as they arrive from Django
                      onPressed: () => openGoogleMaps(double.tryParse(s["lat"].toString()) ?? 0, double.tryParse(s["long"].toString()) ?? 0),
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text("Get Directions"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}