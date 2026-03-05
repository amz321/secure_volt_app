import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StationSlotsPage extends StatefulWidget {
  const StationSlotsPage({super.key});

  @override
  State<StationSlotsPage> createState() => _StationSlotsPageState();
}

class _StationSlotsPageState extends State<StationSlotsPage> {
  final Color skyBlueBg = const Color(0xFFE0F2FE);
  final Color bressayCard = Colors.white;
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color bressayMuted = const Color(0xFFE1D7C6);

  String baseUrl = "";
  String lid = "";
  String sid = "";
  bool isLoading = false;
  List slots = [];

  @override
  void initState() {
    super.initState();
    loadPref();
  }

  String formatToAmPm(String time24) {
    try {
      final inputFormat = DateFormat("HH:mm");
      final outputFormat = DateFormat("hh:mm a");
      final dateTime = inputFormat.parse(time24);
      return outputFormat.format(dateTime);
    } catch (e) {
      return time24;
    }
  }

  Future<void> loadPref() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      baseUrl = sp.getString("url") ?? "";
      lid = sp.getString("lid") ?? "";
      sid = sp.getString("sid") ?? "";
    });
    fetchSlots();
  }

  Future<void> fetchSlots() async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/UserViewStationChargingSlots/"),
        body: {"sid": sid},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() => slots = jsonData["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> bookSlot({required String sid, required String selectedDate}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/UserBookChargingSlot/"),
        body: {"lid": lid, "sid": sid, "date": selectedDate},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        _showStyledSnackBar("Reservation Confirmed", bressayBrown);
        fetchSlots();
      }
    } catch (e) {
      _showStyledSnackBar("Something went wrong", Colors.redAccent);
    }
  }

  void _showStyledSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void openBookingSheet(String sid) {
    DateTime? pickedDate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: skyBlueBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 28, right: 28, top: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom + 35,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 5, width: 50, decoration: BoxDecoration(color: bressayMuted, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 30),
                Text("Select Date", style: TextStyle(fontSize: 22, color: bressayDark, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                GestureDetector(
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 1),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: bressayBrown,
                              onPrimary: Colors.white,
                              onSurface: bressayDark,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(foregroundColor: bressayBrown),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (selected != null) setModalState(() => pickedDate = selected);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    decoration: BoxDecoration(
                      color: bressayCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: bressayMuted),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pickedDate == null ? "Pick a date" : DateFormat('dd/MM/yyyy').format(pickedDate!),
                          style: TextStyle(color: bressayDark, fontSize: 16),
                        ),
                        Icon(Icons.calendar_today_rounded, color: bressayBrown, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bressayBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (pickedDate == null) return;
                      final formatted = DateFormat('yyyy-MM-dd').format(pickedDate!);
                      Navigator.pop(context);
                      await bookSlot(sid: sid, selectedDate: formatted);
                    },
                    child: const Text("Confirm Reservation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: skyBlueBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("Parking Slots", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 24)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, color: bressayBrown),
              onPressed: fetchSlots,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: bressayBrown))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final s = slots[index];
          String formattedFrom = formatToAmPm(s["from_time"]);
          String formattedTo = formatToAmPm(s["to_time"]);

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bressayCard,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: bressayBrown.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: skyBlueBg.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text("AVAILABLE", style: TextStyle(color: bressayBrown, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        ),
                        const SizedBox(width: 8),
                        // --- DAILY HIGHLIGHT ---
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: bressayBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.event_repeat, color: bressayBrown, size: 12),
                              const SizedBox(width: 4),
                              Text("DAILY SLOT", style: TextStyle(color: bressayBrown, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text("₹${s["amount"]}", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 22)),
                  ],
                ),
                const SizedBox(height: 18),
                Text("$formattedFrom - $formattedTo",
                    style: TextStyle(fontSize: 20, color: bressayDark, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text("Available every day at this time", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bressayBrown,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () => openBookingSheet(s["id"].toString()),
                        child: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}