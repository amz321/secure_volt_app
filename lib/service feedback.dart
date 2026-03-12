import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServiceFeedback extends StatefulWidget {
  const ServiceFeedback({super.key});

  @override
  State<ServiceFeedback> createState() => _ServiceFeedbackState();
}

class _ServiceFeedbackState extends State<ServiceFeedback> {
  // --- THEME COLORS (Matching project style) ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  List feedbackList = [];
  bool isLoading = false;
  final TextEditingController feedbackController = TextEditingController();
  double _rating = 0;
  String baseUrl = "";
  String lid = "";
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
      lid = sh.getString('lid') ?? "";
      sid = sh.getString('feedback_sid') ?? "";
    });
    if (baseUrl.isNotEmpty && lid.isNotEmpty && sid.isNotEmpty) {
      getFeedback();
    }
  }

  Future<void> getFeedback() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse("$baseUrl/userservicefeedback/$lid/$sid/"));
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

  Future<void> sendFeedback() async {
    if (_rating == 0 || feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide both rating and feedback")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/userservicefeedback/$lid/$sid/"),
        body: {
          'feedback': feedbackController.text.trim(),
          'rating': _rating.toString(),
        },
      );
      var data = jsonDecode(response.body);
      if (data['status'] == 'ok') {
        feedbackController.clear();
        setState(() => _rating = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Feedback sent successfully ✅")),
        );
        getFeedback();
      }
    } catch (e) {
      debugPrint("Send Error: $e");
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
        title: Text("Service Feedback",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayBrown), onPressed: getFeedback),
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
            _buildInputSection(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Divider(thickness: 1, color: Colors.white),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: bressayBrown))
                  : feedbackList.isEmpty
                      ? Center(child: Text("No feedback history found", style: TextStyle(color: bressayDark.withOpacity(0.5))))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: feedbackList.length,
                          itemBuilder: (context, index) => _buildFeedbackCard(feedbackList[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        children: [
          Text("Rate the Service",
              style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            allowHalfRating: true,
            itemSize: 32,
            unratedColor: bressayBrown.withOpacity(0.2),
            itemPadding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, _) => Icon(Icons.star_rounded, color: bressayBrown),
            onRatingUpdate: (rating) => setState(() => _rating = rating),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: feedbackController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "What do you think about the service?",
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
              onPressed: sendFeedback,
              child: const Text("SUBMIT FEEDBACK",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: skyBlueBg,
                child: Icon(Icons.person, color: bressayBrown, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Your Feedback", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 13)),
                        if (f.containsKey("date"))
                          Text(f["date"] ?? "", style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: double.tryParse(f["rating"].toString()) ?? 0,
                      itemBuilder: (context, _) => Icon(Icons.star_rounded, color: bressayBrown),
                      itemCount: 5,
                      itemSize: 14,
                    ),
                    const SizedBox(height: 6),
                    Text(f["feedbacks"] ?? "",
                        style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          // --- REPLY SECTION ---
          if (f["reply"] != null && f["reply"].toString().isNotEmpty && f["reply"].toString().toLowerCase() != "null") ...[
            const Padding(
              padding: EdgeInsets.only(left: 40, top: 10),
              child: Divider(height: 1, color: Colors.white),
            ),
            Container(
              margin: const EdgeInsets.only(left: 40, top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bressayBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded, color: bressayBrown, size: 14),
                      const SizedBox(width: 6),
                      Text("Station Reply", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w900, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(f["reply"], style: TextStyle(color: bressayDark, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
