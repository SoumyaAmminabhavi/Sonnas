import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../../owner/owner_dashboard.dart' deferred as owner_dashboard;
import 'profile_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool isOwner;
  final VoidCallback? onSuccess;
  const AuthScreen({super.key, this.isOwner = false, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color primary = Color(0xFFFF4D8D);
  static const Color accent = Color(0xFFFFB6D3);
  static const Color background = Color(0xFFFFF0F6);
  static const Color berry = Color(0xFF701235);
  static const String _emailKey = 'saved_email';

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _routeUserAfterLogin(String email) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final bool isSetupCompleted = metadata['profile_setup_completed'] == true;

    await _saveEmail(email);

    if (mounted) {
      if (!isSetupCompleted && !widget.isOwner) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              onSuccess: widget.onSuccess,
              isOwner: widget.isOwner,
            ),
          ),
        );
      } else {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (widget.isOwner) {
          await owner_dashboard.loadLibrary();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => owner_dashboard.OwnerDashboard()),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
          );
        }
      }
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final supabase = Supabase.instance.client;
      if (_isSignUp) {
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          if (res.session != null || supabase.auth.currentUser != null) {
            await _routeUserAfterLogin(email);
            return;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Account created! Please check your email for verification."),
              backgroundColor: berry,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        await _routeUserAfterLogin(email);
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = e.message;
        if (e.code == 'email_address_invalid') {
          message = "This email format isn't accepted. Please check for typos.";
        } else if (e.code == 'invalid_credentials') {
          message = "Incorrect email or password.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Authentication error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication failed. Please try again later."),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
          ),
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
          // Elegant Background Elements
          Positioned(
            top: -150,
            right: -100,
            child: _buildCircle(400, accent.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: _buildCircle(300, primary.withValues(alpha: 0.05)),
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new, color: berry),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      Text(
                        widget.isOwner ? "OWNER PORTAL" : "GUEST ACCESS",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isSignUp ? "Create Your\nAccount" : "Welcome back\nto Sonna's",
                        style: GoogleFonts.notoSerif(
                          fontSize: 42,
                          fontWeight: FontWeight.w400,
                          color: berry,
                          height: 1.1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Email Field with autocomplete suggestions
                      _buildLabel("Email Address"),
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final input = textEditingValue.text;
                          if (input.isEmpty || input.length < 1) return const Iterable<String>.empty();
                          final domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com', 'icloud.com'];
                          final suggestions = <String>{};
                          if (input.contains('@')) {
                            final parts = input.split('@');
                            final local = parts[0];
                            final domainPart = parts.length > 1 ? parts[1] : '';
                            for (var d in domains) {
                              if (d.startsWith(domainPart)) suggestions.add('$local@$d');
                            }
                          } else {
                            for (var d in domains) {
                              suggestions.add('$input@$d');
                            }
                            // Offer saved typed email if it matches
                            if (_emailController.text.isNotEmpty && _emailController.text.startsWith(input)) {
                              suggestions.add(_emailController.text);
                            }
                          }
                          return suggestions;
                        },
                        onSelected: (String selection) {
                          setState(() {
                            _emailController.text = selection;
                          });
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          // Keep the original controller in sync with the Autocomplete field controller
                          textEditingController.text = _emailController.text;
                          textEditingController.selection = _emailController.selection;
                          textEditingController.addListener(() {
                            if (_emailController.text != textEditingController.text) {
                              _emailController.text = textEditingController.text;
                              _emailController.selection = textEditingController.selection;
                            }
                          });
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            style: GoogleFonts.plusJakartaSans(color: berry, fontWeight: FontWeight.w600),
                            decoration: _buildInputDecoration("yourname@email.com", Icons.email_outlined),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Email is required";
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                return "Enter a valid email address";
                              }
                              return null;
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 600),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option, style: GoogleFonts.plusJakartaSans()),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Password Field
                      _buildLabel("Password"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        style: GoogleFonts.plusJakartaSans(color: berry, fontWeight: FontWeight.w600),
                        decoration: _buildInputDecoration(
                          "••••••••", 
                          Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            color: berry.withValues(alpha: 0.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Password is required";
                          if (value.length < 6) return "Password must be at least 6 characters";
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Primary Action Button
                      Hero(
                        tag: 'auth_button',
                        child: SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isSignUp ? "CREATE ACCOUNT" : "SIGN IN",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Toggle Link
                      Center(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isSignUp = !_isSignUp;
                            if (_isSignUp) {
                              _animationController.reset();
                              _animationController.forward();
                            }
                          }),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(color: berry.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                              children: [
                                TextSpan(text: _isSignUp ? "Already have an account? " : "New to Sonna's? "),
                                TextSpan(
                                  text: _isSignUp ? "Sign In" : "Create one",
                                  style: const TextStyle(color: primary, fontWeight: FontWeight.w800),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: berry.withValues(alpha: 0.5),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: berry.withValues(alpha: 0.2)),
      prefixIcon: Icon(icon, color: primary, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(color: primary, fontWeight: FontWeight.w600),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1),
      ),
    );
  }
}
