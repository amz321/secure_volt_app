import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';



void main() {
  runApp(const ipsetpage());
}

class ipsetpage extends StatelessWidget {
  const ipsetpage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ipset(),
      debugShowCheckedModeBanner: false,
    );
  }
}




class ipset extends StatefulWidget {
  const ipset({super.key});

  @override
  State<ipset> createState() => _ipsetstate();
}

class _ipsetstate extends State<ipset> {
  final TextEditingController ipController = TextEditingController();

  // --- SECURE VOLT THEME PALETTE ---
  final Color bressayBrown = const Color(0xFFB0926A); // Gold/Bronze
  final Color bressayDark = const Color(0xFF433422);  // Rich Brown
  final Color bgLight = const Color(0xFFF8FAFC);      // Off-white background

  @override
  void initState() {
    super.initState();
    _loadSavedIP(); // Load previous IP on startup
  }

  // Retrieve the raw IP from SharedPreferences
  Future<void> _loadSavedIP() async {
    final sh = await SharedPreferences.getInstance();
    setState(() {
      ipController.text = sh.getString("ip_only") ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Top Navigation Bar to match your screenshot
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text("SECURE", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
            Text("VOLT", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w400, fontSize: 18, letterSpacing: -0.5)),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                "Configuration",
                style: TextStyle(color: bressayDark, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                "Setup your server connection to begin managing Secure Volt stations.",
                style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),

              // --- STYLED IP INPUT ---
              Container(
                decoration: BoxDecoration(
                  color: bgLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: ipController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontWeight: FontWeight.bold, color: bressayDark),
                  decoration: InputDecoration(
                    labelText: "IP ADDRESS",
                    labelStyle: TextStyle(color: bressayBrown, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
                    hintText: "0.0.0.0",
                    hintStyle: TextStyle(color: bressayDark.withOpacity(0.2)),
                    prefixIcon: Icon(Icons.dns_rounded, color: bressayBrown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- ACTION BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    String ip = ipController.text.trim();
                    if (ip.isEmpty) return;

                    final sh = await SharedPreferences.getInstance();

                    // Store the full URL for the application
                    sh.setString("url", "http://$ip:8000/myapp");

                    // Store the raw IP to reload into the text field
                    sh.setString("ip_only", ip);

                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const login()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bressayDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // Pill shape like Logout
                    elevation: 0,
                  ),
                  child: const Text("INITIALIZE CONNECTION", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 14)),
                ),
              ),

              const Spacer(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text("SECURE VOLT v1.0.4", style: TextStyle(color: bressayBrown.withOpacity(0.5), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 2)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}