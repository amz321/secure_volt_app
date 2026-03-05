import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  // --- THEME COLORS ---
  final Color bressayBrown = const Color(0xFFB0926A);
  final Color bressayDark = const Color(0xFF433422);
  final Color skyBlueBg = const Color(0xFFE0F2FE);

  final _formKey = GlobalKey<FormState>();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: bressayDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Security Settings",
            style: TextStyle(color: bressayDark, fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skyBlueBg, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- SECURITY ICON ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: bressayBrown.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_reset_rounded, size: 64, color: bressayBrown),
                  ),
                  const SizedBox(height: 24),
                  Text('Change Password',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: bressayDark)),
                  const SizedBox(height: 8),
                  Text('Update your credentials to keep your account secure',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),

                  const SizedBox(height: 40),

                  // Current Password
                  _buildPasswordField(
                    controller: currentPasswordController,
                    label: 'Current Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscureCurrent,
                    onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    validator: (v) => v!.isEmpty ? 'Current password is required' : null,
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  _buildPasswordField(
                    controller: newPasswordController,
                    label: 'New Password',
                    icon: Icons.vpn_key_outlined,
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    validator: (v) {
                      if (v!.isEmpty) return 'New password is required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.verified_user_outlined,
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) {
                      if (v!.isEmpty) return 'Please confirm password';
                      if (v != newPasswordController.text) return 'Passwords don\'t match';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : sendData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bressayDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('UPDATE PASSWORD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: bressayBrown, fontWeight: FontWeight.w600, fontSize: 13),
        prefixIcon: Icon(icon, color: bressayBrown, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: bressayBrown, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: bressayBrown, width: 1)),
      ),
    );
  }

  // --- API LOGIC (REMAINING EXACTLY THE SAME) ---
  Future<void> sendData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final current = currentPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final sh = await SharedPreferences.getInstance();
    final url = sh.getString('url');
    final lid = sh.getString('lid');

    try {
      final response = await http.post(
        Uri.parse('$url/UserChangePassword/'),
        body: {'current_password': current, 'new_password': newPass, 'lid': lid},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          _showToast('Password updated successfully', Colors.green);
          Navigator.pop(context);
        } else {
          _showToast('Invalid current password', Colors.red);
        }
      }
    } catch (e) {
      _showToast('Network error', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg, Color bg) {
    Fluttertoast.showToast(msg: msg, backgroundColor: bg, textColor: Colors.white);
  }
}