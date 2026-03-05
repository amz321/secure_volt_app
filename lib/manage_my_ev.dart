import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageVehiclePage extends StatefulWidget {
  const ManageVehiclePage({super.key});

  @override
  State<ManageVehiclePage> createState() => _ManageVehiclePageState();
}

class _ManageVehiclePageState extends State<ManageVehiclePage> {
  // --- SECURE VOLT THEME ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  List vehicles = [];
  bool isLoading = false;
  String baseUrl = "";
  String lid = "";

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
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/UserViewOwnVehicles/"),
        body: {"lid": lid},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() => vehicles = jsonData["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteVehicle(String vid) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/RemoveVehicle/"),
        body: {"vid": vid},
      );
      if (json.decode(res.body)["status"] == "ok") {
        fetchVehicles();
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
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
        title: Text("My EV Garage",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: bressayDark,
        onPressed: () => openVehicleBottomSheet(),
        child: const Icon(Icons.add, color: Colors.white),
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
            : vehicles.isEmpty
            ? Center(child: Text("No vehicles added yet.", style: TextStyle(color: bressayBrown)))
            : ListView.builder(
          padding: const EdgeInsets.only(top: 120, left: 20, right: 20, bottom: 80),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final v = vehicles[index];
            return _buildVehicleCard(v);
          },
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Map v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 60, height: 60, color: skyBlueBg,
            child: (v["photo"] != null && v["photo"].toString().isNotEmpty)
                ? Image.network(v["photo"], fit: BoxFit.cover)
                : Icon(Icons.directions_car, color: bressayBrown),
          ),
        ),
        title: Text(v["vehicle_name"] ?? "",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900)),
        subtitle: Text(v["vehicle_no"],
            style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w600, fontSize: 12)),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: bressayDark),
          itemBuilder: (context) => [
            const PopupMenuItem(value: "edit", child: Text("Edit")),
            const PopupMenuItem(value: "delete", child: Text("Delete", style: TextStyle(color: Colors.red))),
          ],
          onSelected: (val) {
            if (val == "edit") openVehicleBottomSheet(vehicle: v);
            if (val == "delete") deleteVehicle(v["id"].toString());
          },
        ),
      ),
    );
  }

  void openVehicleBottomSheet({Map? vehicle}) {
    final bool isEdit = vehicle != null;
    final nameC = TextEditingController(text: isEdit ? vehicle["vehicle_name"] : "");
    final noC = TextEditingController(text: isEdit ? vehicle["vehicle_no"] : "");
    String vType = isEdit ? vehicle["vehicle_type"] : "Two Wheeler";
    File? img;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 25, right: 25, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? "Update Vehicle" : "New Vehicle", style: TextStyle(color: bressayDark, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _sheetField(nameC, "Vehicle Name", Icons.edit),
              const SizedBox(height: 12),
              _sheetField(noC, "Registration Number", Icons.tag),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: vType,
                decoration: _sheetDecoration("Type", Icons.category),
                items: ["Two Wheeler", "Four Wheeler"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (s) => setModalState(() => vType = s!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) setModalState(() => img = File(picked.path));
                },
                child: Text(img == null ? "Pick Photo" : "Photo Selected ✅"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: bressayDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                  onPressed: () {
                    Navigator.pop(context);
                    if (isEdit) {
                      updateVehicle(vid: vehicle["id"].toString(), vehicleName: nameC.text, vehicleNo: noC.text, vehicleType: vType, imageFile: img);
                    } else {
                      addVehicle(vehicleName: nameC.text, vehicleNo: noC.text, vehicleType: vType, imageFile: img!);
                    }
                  },
                  child: Text(isEdit ? "SAVE CHANGES" : "ADD TO GARAGE", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _sheetDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: bressayBrown),
      filled: true, fillColor: skyBlueBg.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  Widget _sheetField(TextEditingController c, String l, IconData i) => TextField(controller: c, decoration: _sheetDecoration(l, i));

  // --- API LOGIC (KEEP YOUR ORIGINAL METHODS HERE) ---
  Future<void> addVehicle({required String vehicleName, required String vehicleNo, required String vehicleType, required File imageFile}) async {
    var req = http.MultipartRequest("POST", Uri.parse("$baseUrl/UserAddVehicle/"));
    req.fields.addAll({"lid": lid, "vehicle_name": vehicleName, "vehicle_no": vehicleNo, "vehicle_type": vehicleType});
    req.files.add(await http.MultipartFile.fromPath("photo", imageFile.path));
    await req.send(); fetchVehicles();
  }

  Future<void> updateVehicle({required String vid, required String vehicleName, required String vehicleNo, required String vehicleType, File? imageFile}) async {
    var req = http.MultipartRequest("POST", Uri.parse("$baseUrl/UpdateVehicle/"));
    req.fields.addAll({"vid": vid, "vehicle_name": vehicleName, "vehicle_no": vehicleNo, "vehicle_type": vehicleType});
    if (imageFile != null) req.files.add(await http.MultipartFile.fromPath("photo", imageFile.path));
    await req.send(); fetchVehicles();
  }
}