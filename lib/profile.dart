import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ViewProfile extends StatefulWidget {
  @override
  _ViewProfileState createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  Map<String, dynamic>? profileData;
  String ip = "";
  String lid = "";

  // Theme Colors
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    ip = prefs.getString('url') ?? "";
    lid = prefs.getString('lid') ?? "";
  }

  Future<void> fetchProfile() async {
    await loadPrefs();
    try {
      final response = await http.post(
        Uri.parse("$ip/view_profile_flutter/"),
        body: {"lid": lid},
      );
      if (response.statusCode == 200) {
        setState(() => profileData = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Profile Error: $e");
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
        title: Text("Account Profile",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          if (profileData != null)
            IconButton(
              icon: Icon(Icons.edit_note_rounded, color: bressayBrown, size: 28),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateProfile(profileData!)));
                fetchProfile();
              },
            )
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
        child: profileData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 120),
          child: Column(
            children: [
              // --- PROFILE IMAGE ---
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: bressayDark.withOpacity(0.1), blurRadius: 20)],
                ),
                child: CircleAvatar(
                  radius: 65,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage("${profileData!['photo']}"),
                ),
              ),
              const SizedBox(height: 15),
              Text(profileData!['name'],
                  style: TextStyle(color: bressayDark, fontSize: 24, fontWeight: FontWeight.w900)),
              Text("Secure Volt User",
                  style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w600, letterSpacing: 1, fontSize: 12)),

              const SizedBox(height: 40),

              // --- INFO CARDS ---
              _profileItem("Email Address", profileData!['email'], Icons.email_outlined),
              _profileItem("Mobile Number", profileData!['phone'].toString(), Icons.phone_android_rounded),
              _profileItem("Primary Location", profileData!['place'], Icons.location_on_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileItem(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: skyBlueBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: bressayBrown, size: 22),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: bressayDark, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class UpdateProfile extends StatefulWidget {
  final Map<String, dynamic> data;
  const UpdateProfile(this.data, {Key? key}) : super(key: key);

  @override
  _UpdateProfileState createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  late TextEditingController name;
  late TextEditingController email;
  late TextEditingController phone;
  late TextEditingController place;

  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  XFile? _image;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.data['name']);
    email = TextEditingController(text: widget.data['email']);
    phone = TextEditingController(text: widget.data['phone'].toString());
    place = TextEditingController(text: widget.data['place']);
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.photo_library), title: const Text("Gallery"), onTap: () { _imgFromGallery(); Navigator.pop(context); }),
            ListTile(leading: const Icon(Icons.camera_alt), title: const Text("Camera"), onTap: () { _imgFromCamera(); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  Future<void> _imgFromCamera() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 60);
    if (image != null) setState(() => _image = image);
  }

  Future<void> _imgFromGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image != null) setState(() => _image = image);
  }

  Future<void> updateProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ip = prefs.getString('url') ?? "";
    String lid = prefs.getString('lid') ?? "";

    var request = http.MultipartRequest("POST", Uri.parse("$ip/update_profile_flutter/"));
    request.fields['lid'] = lid;
    request.fields['name'] = name.text;
    request.fields['email'] = email.text;
    request.fields['phone'] = phone.text;
    request.fields['place'] = place.text;

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', _image!.path));
    }

    var response = await request.send();
    if (response.statusCode == 200) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close, color: bressayDark), onPressed: () => Navigator.pop(context)),
        title: Text("Edit Information", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: skyBlueBg,
                    backgroundImage: _image != null
                        ? FileImage(File(_image!.path))
                        : NetworkImage("${widget.data['photo']}") as ImageProvider,
                  ),
                  Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: bressayBrown, child: const Icon(Icons.camera_alt, size: 16, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _inputField(name, "Full Name", Icons.person_outline),
            _inputField(email, "Email Address", Icons.email_outlined),
            _inputField(phone, "Phone Number", Icons.phone_android, type: TextInputType.phone),
            _inputField(place, "Location", Icons.map_outlined),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bressayDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  elevation: 0,
                ),
                child: const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: bressayBrown, fontWeight: FontWeight.w700, fontSize: 12),
          prefixIcon: Icon(icon, color: bressayBrown, size: 20),
          filled: true,
          fillColor: skyBlueBg.withOpacity(0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}