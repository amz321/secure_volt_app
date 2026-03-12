import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewServiceFeedback extends StatefulWidget {
  const ViewServiceFeedback({super.key});

  @override
  State<ViewServiceFeedback> createState() => _ViewServiceFeedbackState();
}

class _ViewServiceFeedbackState extends State<ViewServiceFeedback> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  List feedbackList = [];
  bool isLoading = true;
  String baseUrl = "";
  String sid = "";

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final sh = await SharedPreferences.getInstance();
    setState(() {
      baseUrl = sh.getString('url') ?? "";
      sid = sh.getString('sid') ?? ""; // Reusing 'sid' which is saved when clicking a station
    });
    if (baseUrl.isNotEmpty && sid.isNotEmpty) {
      fetchAllFeedbacks();
    }
  }

  Future<void> fetchAllFeedbacks() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/userViewservicefeedback/"),
        body: {'sid': sid},
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          setState(() {
            feedbackList = data['data'] ?? [];
          });
        }
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
        title: Text("Station Feedbacks",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayBrown), onPressed: fetchAllFeedbacks),
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
            : feedbackList.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 80, color: bressayBrown.withOpacity(0.3)),
                      const SizedBox(height: 15),
                      Text("No feedbacks yet for this station",
                          style: TextStyle(color: bressayDark.withOpacity(0.5))),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
                    itemCount: feedbackList.length,
                    itemBuilder: (context, index) => _buildFeedbackCard(feedbackList[index]),
                  ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: bressayDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: skyBlueBg,
                child: Icon(Icons.person, color: bressayBrown, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("User Review", // Django values() might not have user name joined unless handled in view
                            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(f["date"]?.toString() ?? "", 
                            style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    RatingBarIndicator(
                      rating: double.tryParse(f["rating"].toString()) ?? 0,
                      itemBuilder: (context, _) => Icon(Icons.star_rounded, color: bressayBrown),
                      itemCount: 5,
                      itemSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(f["feedbacks"] ?? "",
              style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4)),

          // --- REPLY SECTION ---
          if (f["reply"] != null && f["reply"].toString().isNotEmpty && f["reply"].toString().toLowerCase() != "null") ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bressayBrown.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded, color: bressayBrown, size: 14),
                      const SizedBox(width: 6),
                      Text("Station Response", 
                          style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(f["reply"], 
                      style: TextStyle(color: bressayDark, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
