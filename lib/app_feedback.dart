import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  List feedbacks = [];
  bool isLoading = false;
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 0;
  String baseUrl = "";
  String lid = "";

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      baseUrl = sp.getString("url") ?? "";
      lid = sp.getString("lid") ?? "";
    });
    if (baseUrl.isNotEmpty) fetchFeedbacks();
  }

  Future<void> fetchFeedbacks() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/UserViewFeedbacks/"));
      final jsonData = json.decode(res.body);
      if (jsonData["status"] == "ok") {
        setState(() => feedbacks = jsonData["data"] ?? []);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> sendFeedback() async {
    if (_rating == 0 || _feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide both rating and feedback")),
      );
      return;
    }
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/UserSendFeedback/"),
        body: {
          "lid": lid,
          "rating": _rating.toString(),
          "feedback": _feedbackController.text.trim(),
        },
      );
      if (json.decode(res.body)["status"] == "ok") {
        _feedbackController.clear();
        setState(() => _rating = 0);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feedback sent successfully ✅")));
        fetchFeedbacks();
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
        title: Text("App Feedback",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: bressayBrown), onPressed: fetchFeedbacks),
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
                  : feedbacks.isEmpty
                  ? const Center(child: Text("No feedbacks yet"))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: feedbacks.length,
                itemBuilder: (context, index) => _buildFeedbackCard(feedbacks[index]),
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
          Text("How's your experience?",
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
            controller: _feedbackController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Share your thoughts...",
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
              child: const Text("SUBMIT FEEDBACK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: skyBlueBg,
            backgroundImage: (f["user_photo"] != null && f["user_photo"].toString().isNotEmpty)
                ? NetworkImage(f["user_photo"]) : null,
            child: (f["user_photo"] == null || f["user_photo"].toString().isEmpty)
                ? Icon(Icons.person, color: bressayBrown) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(f["user"] ?? "User", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800)),
                    Text(f["date"] ?? "", style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                  ],
                ),
                RatingBarIndicator(
                  rating: double.tryParse(f["rating"].toString()) ?? 0,
                  itemBuilder: (context, _) => Icon(Icons.star_rounded, color: bressayBrown),
                  itemCount: 5,
                  itemSize: 16,
                ),
                const SizedBox(height: 6),
                Text(f["feedback"] ?? "", style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}