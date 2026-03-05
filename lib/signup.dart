import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:secure_volt/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final firstnameController = TextEditingController();
  final districtController = TextEditingController();
  final placeController = TextEditingController();
  final postController = TextEditingController();
  final pinController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  XFile? _image;

  // SECURE VOLT THEME
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color bgLight = const Color(0xFFF8FAFC);

  // Validation RegEx
  final RegExp nameRegExp = RegExp(r'^[A-Za-z ]{2,25}$');
  final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp phoneRegExp = RegExp(r'^[6789]\d{9}$');
  final RegExp pinRegExp = RegExp(r'^[0-9]{6}$');

  _imgFromCamera() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 50);
    if (image != null) setState(() => _image = image);
  }

  _imgFromGallery() async {
    XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _image = image);
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Photo Library'), onTap: () { _imgFromGallery(); Navigator.of(context).pop(); }),
              ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () { _imgFromCamera(); Navigator.of(context).pop(); }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: bressayDark, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text("Create Account", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _showPicker(context),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: bgLight,
                        backgroundImage: _image != null ? FileImage(File(_image!.path)) : null,
                        child: _image == null ? Icon(Icons.person_add_alt_1, color: bressayBrown, size: 40) : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: bressayBrown, child: const Icon(Icons.camera_alt, color: Colors.white, size: 15))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _sectionTitle("Personal Details"),
              _buildField(controller: firstnameController, label: "Full Name", icon: Icons.person_outline, validator: (v) => !nameRegExp.hasMatch(v!) ? "Enter a valid name" : null),
              _buildField(controller: emailController, label: "Email Address", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => !emailRegExp.hasMatch(v!) ? "Invalid email format" : null),
              _buildField(controller: phoneNumberController, label: "Phone Number", icon: Icons.phone_android, keyboardType: TextInputType.phone, validator: (v) => !phoneRegExp.hasMatch(v!) ? "Enter 10 digit number starting with 6-9" : null),

              const SizedBox(height: 20),
              _sectionTitle("Address Information"),
              _buildField(controller: placeController, label: "Place", icon: Icons.map_outlined, validator: (v) => v!.isEmpty ? "Required" : null),
              _buildField(controller: postController, label: "Post Office", icon: Icons.local_post_office_outlined, validator: (v) => v!.isEmpty ? "Required" : null),
              _buildField(controller: pinController, label: "Pincode", icon: Icons.pin_drop_outlined, keyboardType: TextInputType.number, validator: (v) => !pinRegExp.hasMatch(v!) ? "Enter 6 digit pincode" : null),
              _buildField(controller: districtController, label: "District", icon: Icons.location_city, validator: (v) => v!.isEmpty ? "Required" : null),

              const SizedBox(height: 20),
              _sectionTitle("Security"),
              _buildField(controller: usernameController, label: "Username", icon: Icons.alternate_email, validator: (v) => v!.length < 4 ? "Username too short" : null),
              _buildField(
                controller: passwordController,
                label: "Password",
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                validator: (v) => v!.length < 6 ? "Password must be at least 6 chars" : null,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: bressayBrown),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: bressayDark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
                  onPressed: _handleSignUp,
                  child: const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(title, style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool obscureText = false, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: bressayDark, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: Icon(icon, color: bressayBrown, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a profile image")));
      return;
    }

    if (_formKey.currentState!.validate()) {
      final sh = await SharedPreferences.getInstance();
      String url = sh.getString("url").toString();

      try {
        var uri = Uri.parse('$url/user_registration/');
        var request = http.MultipartRequest('POST', uri);

        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
        request.fields['name'] = firstnameController.text;
        request.fields['email'] = emailController.text;
        request.fields['place'] = placeController.text;
        request.fields['post'] = postController.text;
        request.fields['pin'] = pinController.text;
        request.fields['district'] = districtController.text;
        request.fields['phone'] = phoneNumberController.text;
        request.fields['username'] = usernameController.text;
        request.fields['password'] = passwordController.text;

        var response = await request.send();
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully Registered'), backgroundColor: Colors.green));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const login()));
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }
}