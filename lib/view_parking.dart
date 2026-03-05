import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:secure_volt/view_parking_slots.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ParkingNearMePage extends StatefulWidget {
  const ParkingNearMePage({super.key});

  @override
  State<ParkingNearMePage> createState() => _ParkingNearMePageState();
}

class _ParkingNearMePageState extends State<ParkingNearMePage> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  bool isLoading = false;
  Position? currentPosition;
  List allParkings = [];
  List filteredParkings = [];
  String selectedPlace = "All";

  @override
  void initState() {
    super.initState();
    loadPref();
  }

  Future<void> loadPref() async {
    final sp = await SharedPreferences.getInstance();
    baseUrl = sp.getString("url") ?? "";
    fetchParkings();
  }

  Future<void> fetchParkings() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/UserViewParkings/"));
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        allParkings = jsonData["data"] ?? [];
        applyFilterAndSort();
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
    setState(() => isLoading = false);
  }

  // --- LOCATION & DISTANCE LOGIC ---
  Future<void> getMyLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => currentPosition = pos);
    applyFilterAndSort();
  }

  double _deg2rad(double deg) => deg * (pi / 180);
  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) + cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  void applyFilterAndSort() {
    List temp = List.from(allParkings);
    if (selectedPlace != "All") {
      temp = temp.where((p) => (p["place"] ?? "") == selectedPlace).toList();
    }
    if (currentPosition != null) {
      for (var p in temp) {
        p["distance"] = calculateDistanceKm(currentPosition!.latitude, currentPosition!.longitude,
            double.tryParse(p["latitude"].toString()) ?? 0, double.tryParse(p["longitude"].toString()) ?? 0);
      }
      temp.sort((a, b) => (a["distance"] ?? 999999).compareTo((b["distance"] ?? 999999)));
    }
    setState(() => filteredParkings = temp);
  }

  Future<void> openGoogleMaps(double lat, double lon) async {
    final Uri gmapUri = Uri.parse("google.navigation:q=$lat,$lon&mode=d");
    if (await canLaunchUrl(gmapUri)) await launchUrl(gmapUri, mode: LaunchMode.externalApplication);
  }

  List<String> getPlaces() {
    final places = allParkings.map((p) => p["place"].toString()).toSet().toList();
    places.sort();
    return ["All", ...places];
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
        title: Text("Nearby Parking",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayBrown), onPressed: fetchParkings),
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
            _buildFilters(),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: bressayBrown))
                  : filteredParkings.isEmpty
                  ? const Center(child: Text("No parking areas found"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: filteredParkings.length,
                itemBuilder: (context, index) => _buildParkingCard(filteredParkings[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: getMyLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentPosition == null ? bressayBrown : Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.my_location, size: 18, color: Colors.white),
                  label: Text(currentPosition == null ? "Find Nearest" : "Located",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPlace,
                      isExpanded: true,
                      style: TextStyle(color: bressayDark, fontSize: 12, fontWeight: FontWeight.w600),
                      items: getPlaces().map((pl) => DropdownMenuItem(value: pl, child: Text(pl))).toList(),
                      onChanged: (val) {
                        setState(() => selectedPlace = val!);
                        applyFilterAndSort();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard(Map p) {
    final lat = double.tryParse(p["latitude"].toString()) ?? 0;
    final lon = double.tryParse(p["longitude"].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: p["proof"] != null && p["proof"].toString().isNotEmpty
                    ? Image.network(p["proof"], height: 80, width: 80, fit: BoxFit.cover)
                    : Container(height: 80, width: 80, color: skyBlueBg, child: Icon(Icons.local_parking, color: bressayBrown)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p["name"] ?? "", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(p["place"] ?? "", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    if (p["distance"] != null)
                      Text("${p["distance"].toStringAsFixed(1)} km away", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => openGoogleMaps(lat, lon),
                icon: const Icon(Icons.directions_outlined, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bressayDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: () async {
                final sh = await SharedPreferences.getInstance();
                sh.setString('parking_id', p["id"].toString());
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ParkingSlotsPage()));
              },
              child: const Text("VIEW AVAILABLE SLOTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}