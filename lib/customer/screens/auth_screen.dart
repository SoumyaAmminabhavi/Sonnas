import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../../owner/owner_dashboard.dart';

class AuthScreen extends StatefulWidget {
  final bool isOwner;
  const AuthScreen({super.key, this.isOwner = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  static const Color primary = Color(0xFFFF4D8D);
  static const Color accent = Color(0xFFFFB6D3);
  static const Color background = Color(0xFFFFF0F6);
  static const String _emailKey = 'saved_email';

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    if (savedEmail != null && mounted) {
      _emailController.text = savedEmail;
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      if (_isSignUp) {
        await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Please check your email for verification.")),
          );
          setState(() => _isSignUp = false);
        }
      } else {
          await supabase.auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          
          // Save email for next time
          await _saveEmail(_emailController.text.trim());

          if (mounted) {
          if (widget.isOwner) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OwnerDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: primary),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background Design
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, color: primary),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    widget.isOwner ? "OWNER PORTAL" : "GUEST ACCESS",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: primary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? "Create Your\nAccount" : "Welcome back to\nSonna's",
                    style: GoogleFonts.notoSerif(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2B1606),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  AutofillGroup(
                    child: Column(
                      children: [
                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: "Email Address",
                          hint: "yourname@email.com",
                          icon: Icons.email_outlined,
                          autofillHints: [AutofillHints.email],
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        
                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          hint: "••••••••",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          autofillHints: [AutofillHints.password],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isSignUp ? "SIGN UP" : "SIGN IN",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Toggle Login/SignUp
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp 
                          ? "Already have an account? Sign In" 
                          : "New here? Create an account",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF701235),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Iterable<String>? autofillHints,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF701235).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          autofillHints: autofillHints,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, color: const Color(0xFF2B1606)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.black12),
            prefixIcon: Icon(icon, color: primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: accent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
