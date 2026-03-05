import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart'; // Add to pubspec.yaml: intl: ^0.18.1
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:secure_volt/station_slots.dart';
import 'package:secure_volt/view_maintainance_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class NearestStationsPage extends StatefulWidget {
  const NearestStationsPage({super.key});

  @override
  State<NearestStationsPage> createState() => _NearestStationsPageState();
}

class _NearestStationsPageState extends State<NearestStationsPage> {
  // --- SECURE VOLT THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  bool isLoading = false;
  Position? currentPosition;

  List allStations = [];
  List filteredStations = [];
  List allServices = [];
  List allNotifications = [];

  String selectedType = "All";

  @override
  void initState() {
    super.initState();
    loadPrefAndFetch();
  }

  Future<void> loadPrefAndFetch() async {
    final sp = await SharedPreferences.getInstance();
    baseUrl = sp.getString("url") ?? "";
    fetchStations();
  }

  // ================= FETCH DATA =================
  Future<void> fetchStations() async {
    setState(() => isLoading = true);

    try {
      // Fetch Stations and Services
      final res = await http.get(Uri.parse("$baseUrl/UserViewChargingStations/"));
      final jsonData = json.decode(res.body);

      // Fetch Notifications
      final notifyRes = await http.get(Uri.parse("$baseUrl/ViewNotification/"));
      final notifyData = json.decode(notifyRes.body);

      if (jsonData["status"] == "ok") {
        allStations = jsonData["data"] ?? [];
        allServices = jsonData["services"] ?? [];

        if (notifyData["status"] == "ok") {
          allNotifications = notifyData["data"] ?? [];
        }
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

  String? getTodayNotification(int stationId) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (var n in allNotifications) {
      if (n["station"].toString() == stationId.toString() && n["date"] == today) {
        return n["notification"];
      }
    }
    return null;
  }

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
    List temp = List.from(allStations);
    if (selectedType != "All") {
      temp = temp.where((s) => s["type"] == selectedType).toList();
    }
    if (currentPosition != null) {
      for (var s in temp) {
        s["distance"] = calculateDistanceKm(
          currentPosition!.latitude,
          currentPosition!.longitude,
          double.tryParse(s["latitude"].toString()) ?? 0,
          double.tryParse(s["longitude"].toString()) ?? 0,
        );
      }
      temp.sort((a, b) => (a["distance"] ?? 99999).compareTo(b["distance"] ?? 99999));
    }
    setState(() => filteredStations = temp);
  }

  Future<void> openGoogleMaps(double lat, double lon) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lon&mode=d");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void showComplaintSheet(int stationId) {
    final TextEditingController c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Report an Issue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: bressayDark)),
            const SizedBox(height: 15),
            TextField(
              controller: c,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                hintText: "Tell us what's wrong at this station...",
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: bressayDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  final sp = await SharedPreferences.getInstance();
                  final lid = sp.getString("lid");
                  await http.post(Uri.parse("$baseUrl/SendComplaintToStation/"), body: {"lid": lid, "sid": stationId.toString(), "complaint": c.text});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complaint submitted successfully")));
                },
                child: const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ================= UI BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Nearest Charging", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayDark), onPressed: fetchStations),
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
                itemCount: filteredStations.length,
                itemBuilder: (context, index) {
                  final s = filteredStations[index];
                  return _buildStationCard(s);
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
                items: ["All", "station", "relay station"].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase(), style: const TextStyle(fontSize: 11)))).toList(),
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

  Widget _buildStationCard(Map s) {
    final services = allServices.where((sv) => sv["STATION_id"] == s["id"]).toList();
    final String? notification = getTodayNotification(s["id"]);
    final bool isRelay = s["type"] == "relay station";

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
                child: Image.network(s["proof"], height: 180, width: double.infinity, fit: BoxFit.cover),
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

                // ================= NOTIFICATION BANNER =================
                if (notification != null)
                  Container(
                    margin: const EdgeInsets.only(top: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.red[200]!)),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign, color: Colors.red, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text("TODAY: $notification", style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => showComplaintSheet(s["id"]),
                        child: const Text("COMPLAINT", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: bressayBrown, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          final sh = await SharedPreferences.getInstance();
                          sh.setString('sid', s['id'].toString());
                          Navigator.push(context, MaterialPageRoute(builder: (_) => StationSlotsPage()));
                        },
                        child: const Text("VIEW SLOTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),

                if (!isRelay)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: bressayDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () async {
                          final sh = await SharedPreferences.getInstance();
                          sh.setString('sid', s['id'].toString());
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const UserViewMaintenanceServices()));
                        },
                        child: const Text("REQUEST MAINTENANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                // Services Scroll (Relay Only)
                if (isRelay && services.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text("Services Available", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: services.length,
                      itemBuilder: (_, i) => Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), image: DecorationImage(image: NetworkImage(services[i]["photo"]), fit: BoxFit.cover)),
                        child: Container(
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)])),
                          padding: const EdgeInsets.all(5),
                          child: Text(services[i]["name"], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                        ),
                      ),
                    ),
                  ),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => openGoogleMaps(double.parse(s["latitude"]), double.parse(s["longitude"])),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text("Get Directions"),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}