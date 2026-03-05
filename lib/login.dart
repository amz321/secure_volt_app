import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:secure_volt/signup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'home.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // --- SECURE VOLT THEME PALETTE ---
  final Color bressayBrown = const Color(0xFFB0926A); // Gold
  final Color bressayDark = const Color(0xFF433422);  // Rich Brown
  final Color bgLight = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: bressayDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("SECURE", style: TextStyle(color: bressayDark, fontWeight: FontWeight.w800, fontSize: 18)),
            Text("VOLT", style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w400, fontSize: 18)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Text("Welcome Back",
                  style: TextStyle(color: bressayDark, fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text("Sign in to continue managing your charging stations.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 15)),

              const SizedBox(height: 50),

              // --- USERNAME FIELD ---
              _buildTextField(
                controller: usernameController,
                label: "USERNAME",
                hint: "Enter your username",
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 20),

              // --- PASSWORD FIELD ---
              _buildTextField(
                controller: passwordController,
                label: "PASSWORD",
                hint: "••••••••",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 40),

              // --- LOGIN BUTTON (Pill Shape) ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bressayDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    elevation: 0,
                  ),
                  child: const Text("LOGIN TO DASHBOARD",
                      style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),

              const SizedBox(height: 20),

              // --- REGISTRATION LINK ---
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpForm()));
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "New to the platform? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Register Now",
                          style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: bressayBrown, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: bgLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: bressayDark.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: bressayBrown, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    final sh = await SharedPreferences.getInstance();
    String uname = usernameController.text.trim();
    String passwd = passwordController.text.trim();
    String? baseUrl = sh.getString("url");

    if (uname.isEmpty || passwd.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter credentials");
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("$baseUrl/and_login/"),
        body: {'username': uname, "password": passwd},
      );

      var jsonData = json.decode(response.body);
      if (jsonData['status'] == "ok") {
        sh.setString("lid", jsonData['lid'].toString());
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      } else {
        Fluttertoast.showToast(msg: 'Invalid Username Or Password');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    }
  }
}