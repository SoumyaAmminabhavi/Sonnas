import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  bool _isLoading = false;
  bool _otpSent = false;

  Timer? _timer;
  int _countdown = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color primary = Color(0xFFFF4D8D);
  static const Color accent = Color(0xFFFFB6D3);
  static const Color background = Color(0xFFFFF0F6);
  static const Color berry = Color(0xFF701235);
  static const String _phoneKey = 'saved_phone';

  @override
  void initState() {
    super.initState();
    _loadSavedDetails();
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
    _timer?.cancel();
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString('guest_phone') ?? prefs.getString(_phoneKey);
    final savedName = prefs.getString('guest_name');
    if (mounted) {
      if (savedPhone != null) _phoneController.text = savedPhone;
      if (savedName != null) _nameController.text = savedName;
    }
  }

  Future<void> _savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phoneKey, phone);
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _saveGuestDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_name', name);
      await prefs.setString('guest_phone', phone);
      await prefs.setBool('is_guest_logged_in', true);

      if (mounted) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          unawaited(Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
          ));
        }
      }
    } catch (e) {
      debugPrint("Error saving guest profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to enter. Please try again."),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _routeUserAfterLogin(String phone) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? {};
    final bool isSetupCompleted = metadata['profile_setup_completed'] == true;

    await _savePhone(phone);

    if (mounted) {
      if (!isSetupCompleted && !widget.isOwner) {
        unawaited(Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupScreen(
              onSuccess: widget.onSuccess,
              isOwner: widget.isOwner,
            ),
          ),
        ));
      } else {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else if (widget.isOwner) {
          await owner_dashboard.loadLibrary();
          if (mounted) {
            unawaited(Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'OwnerDashboard'),
                builder: (context) => owner_dashboard.OwnerDashboard(),
              ),
            ));
          }
        } else {
          unawaited(Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CustomerMainScreen()),
          ));
        }
      }
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signInWithOtp(
        phone: '+91$phone',
      );
      
      if (mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _startCountdown();
        _otpFocusNode.requestFocus();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("OTP sent successfully!"),
            backgroundColor: berry,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = e.message;
        if (message.toLowerCase().contains("unsupported phone provider")) {
          message = "Phone authentication is not enabled in your Supabase dashboard (Authentication > Providers > Phone).";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("OTP Send error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send OTP. Please check your network and try again."),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.verifyOTP(
        phone: '+91$phone',
        token: otp,
        type: OtpType.sms,
      );

      if (mounted) {
        if (response.session != null || supabase.auth.currentUser != null) {
          await _routeUserAfterLogin(phone);
        } else {
          throw const AuthException("Verification failed. Please try again.");
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = e.message;
        if (message.toLowerCase().contains("invalid")) {
          message = "Invalid OTP. Please check the code and try again.";
        } else if (message.toLowerCase().contains("expired")) {
          message = "OTP Expired. Please request a new OTP.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("OTP Verification error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification failed. Please check the OTP and try again."),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
                        _otpSent ? "Verify Mobile\nNumber" : "Welcome back\nto Sonna's",
                        style: GoogleFonts.notoSerif(
                          fontSize: 42,
                          fontWeight: FontWeight.w400,
                          color: berry,
                          height: 1.1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 48),

                      if (!widget.isOwner) ...[
                        _buildLabel("Full Name"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_isLoading,
                          style: GoogleFonts.plusJakartaSans(
                            color: berry, 
                            fontWeight: FontWeight.w600
                          ),
                          decoration: _buildInputDecoration(
                            "Enter your full name", 
                            Icons.person_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return "Name is required";
                            if (value.trim().length < 2) return "Please enter a valid name";
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Phone Field
                      _buildLabel("Mobile Number"),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        enabled: !_otpSent && !_isLoading,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: GoogleFonts.plusJakartaSans(
                          color: _otpSent ? berry.withValues(alpha: 0.5) : berry, 
                          fontWeight: FontWeight.w600
                        ),
                        decoration: _buildInputDecoration(
                          "Enter your 10-digit phone number", 
                          Icons.phone_outlined,
                          prefixText: "+91 ",
                          prefixStyle: GoogleFonts.plusJakartaSans(
                            color: _otpSent ? berry.withValues(alpha: 0.5) : berry,
                            fontWeight: FontWeight.w600,
                          ),
                          suffixIcon: _otpSent 
                            ? TextButton(
                                onPressed: _isLoading 
                                  ? null 
                                  : () {
                                      setState(() {
                                        _otpSent = false;
                                        _otpController.clear();
                                        _phoneFocusNode.requestFocus();
                                      });
                                    },
                                child: Text(
                                  "Change",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Phone number is required";
                          if (value.length != 10) return "Phone number must be 10 digits";
                          if (!RegExp(r'^[6-9]').hasMatch(value)) return "Invalid phone number";
                          return null;
                        },
                      ),
                      
                      if (_otpSent) ...[
                        const SizedBox(height: 24),
                        // OTP Field
                        _buildLabel("Enter 6-Digit OTP"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          enabled: !_isLoading,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: GoogleFonts.plusJakartaSans(
                            color: berry, 
                            fontWeight: FontWeight.w600,
                            letterSpacing: 8,
                          ),
                          textAlign: TextAlign.center,
                          decoration: _buildInputDecoration(
                            "\u2022\u2022\u2022\u2022\u2022\u2022", 
                            Icons.lock_outline,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "OTP is required";
                            if (value.length != 6) return "OTP must be 6 digits";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Resend OTP Countdown
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: (_countdown > 0 || _isLoading) ? null : _sendOtp,
                            child: Text(
                              _countdown > 0 
                                ? "Resend OTP in ${_countdown}s" 
                                : "Resend OTP",
                              style: GoogleFonts.plusJakartaSans(
                                color: _countdown > 0 ? berry.withValues(alpha: 0.4) : primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 48),
                      
                      // Primary Action Button
                      Hero(
                        tag: 'auth_button',
                        child: SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isLoading 
                              ? null 
                              : (widget.isOwner 
                                  ? (_otpSent ? _verifyOtp : _sendOtp)
                                  : _saveGuestDetails),
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
                                  widget.isOwner 
                                    ? (_otpSent ? "VERIFY & SIGN IN" : "SEND OTP")
                                    : "CONTINUE",
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
                      
                      // Helper Terms Text
                      Center(
                        child: Text(
                          "By signing in, you agree to Sonna's Terms and Privacy Policy.",
                          style: GoogleFonts.plusJakartaSans(
                            color: berry.withValues(alpha: 0.5), 
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
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

  InputDecoration _buildInputDecoration(
    String hint, 
    IconData icon, {
    String? prefixText, 
    TextStyle? prefixStyle, 
    Widget? suffixIcon
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: berry.withValues(alpha: 0.2), letterSpacing: 0),
      prefixIcon: Icon(icon, color: primary, size: 22),
      prefixText: prefixText,
      prefixStyle: prefixStyle,
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

