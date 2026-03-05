import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  String baseUrl = "";
  String lid = "";
  bool isLoading = false;
  List complaints = [];
  final TextEditingController _complaintController = TextEditingController();

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
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/ViewComplaintResponse/"),
        body: {"lid": lid},
      );
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() => complaints = jsonData["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> sendComplaint() async {
    final text = _complaintController.text.trim();
    if (text.isEmpty) return;

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/UserSendComplaint/"),
        body: {"lid": lid, "complaint": text},
      );
      if (json.decode(res.body)["status"] == "ok") {
        _complaintController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report submitted successfully ✅")));
        fetchComplaints();
      }
    } catch (e) {
      debugPrint("Error: $e");
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
        title: Text("Support Center",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayBrown), onPressed: fetchComplaints),
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
            _buildNewComplaintBox(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Row(
                children: [
                  Text("PREVIOUS REPORTS",
                      style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  const Expanded(child: Divider(indent: 10, thickness: 1, color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: bressayBrown))
                  : complaints.isEmpty
                  ? const Center(child: Text("No support tickets found"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: complaints.length,
                itemBuilder: (context, index) => _buildComplaintItem(complaints[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewComplaintBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Report an Issue", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: _complaintController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Describe the issue you're facing...",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: bressayDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
              onPressed: sendComplaint,
              child: const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintItem(Map c) {
    bool isPending = c["reply"].toString().toLowerCase().contains("pending");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(isPending ? "PENDING" : "RESOLVED",
                    style: TextStyle(color: isPending ? Colors.orange[800] : Colors.green[800], fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              Text(c["date"].toString(), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text("My Report:", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 4),
          Text(c["complaint"] ?? "", style: TextStyle(color: bressayDark, fontSize: 14)),

          if (!isPending) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Colors.white, thickness: 1),
            ),
            Text("Official Reply:", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 4),
            Text(c["reply"] ?? "", style: TextStyle(color: bressayDark, fontSize: 14, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}