import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'staff_roles.dart';
import 'staff_dashboard.dart';
import '../services/supabase_service.dart';
import '../services/biometric_service.dart';

class StaffLoginPage extends StatefulWidget {
  const StaffLoginPage({super.key});

  @override
  State<StaffLoginPage> createState() => _StaffLoginPageState();
}

class _StaffLoginPageState extends State<StaffLoginPage> {
  bool _isLoginTab = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Login controllers
  final TextEditingController _loginPhoneController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();

  // Registration controllers
  final TextEditingController _regPhoneController = TextEditingController();
  final TextEditingController _regCodeController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regConfirmPasswordController = TextEditingController();

  // Registration state
  Map<String, dynamic>? _verifiedStaff;

  @override
  void dispose() {
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _regPhoneController.dispose();
    _regCodeController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _handleLogin() async {
    // Strip non-digits just like in add_staff_page
    final phone = _loginPhoneController.text.replaceAll(RegExp(r'\D'), '');
    final password = _loginPasswordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showError("Please enter mobile number and password.");
      return;
    }

    setState(() => _isLoading = true);

    final staff = await SupabaseService.loginStaff(phone, password);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (staff != null) {
      _routeToDashboard(staff);
    } else {
      _showError("Invalid credentials. Please check your number and password.");
    }
  }

  Future<void> _handleBiometricLogin() async {
    final bool canCheck = await BiometricService.canCheckBiometrics();
    if (!canCheck) {
      _showError("Biometric authentication (Windows Hello / Fingerprint) is not available on this device.");
      return;
    }

    final bool authenticated = await BiometricService.authenticate();
    if (authenticated) {
      // For Biometric login, we check if there is a staff member with this phone number.
      // In a real production app, we would store the last logged-in phone number in Secure Storage (SharedPreferences).
      // For now, if _loginPhoneController is empty, we'll ask them to enter it once to "link" it.
      final phone = _loginPhoneController.text.replaceAll(RegExp(r'\D'), '');
      
      if (phone.isEmpty || phone.length != 10) {
        _showError("Please enter your 10-digit mobile number once to link it with Biometrics.");
        return;
      }

      setState(() => _isLoading = true);
      // We query the staff directly by phone since biometric passed
      final staff = await SupabaseService.myClient
          .from('Staff')
          .select()
          .eq('phone', phone)
          .eq('isActivated', true)
          .maybeSingle();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (staff != null) {
        _routeToDashboard(staff);
      } else {
        _showError("No activated staff member found for this number.");
      }
    }
  }

  Future<void> _handleVerifyCode() async {
    final phone = _regPhoneController.text.replaceAll(RegExp(r'\D'), '');
    final code = _regCodeController.text.trim().toUpperCase();

    if (phone.isEmpty || code.isEmpty) {
      _showError("Please enter mobile number and the 5-character code.");
      return;
    }

    setState(() => _isLoading = true);

    final staff = await SupabaseService.verifyStaffCode(phone, code);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (staff != null) {
      setState(() {
        _verifiedStaff = staff;
        _errorMessage = null;
      });
    } else {
      _showError("Invalid code or mobile number. Make sure the code hasn't been used yet.");
    }
  }

  Future<void> _handleSetPassword() async {
    if (_verifiedStaff == null) return;

    final password = _regPasswordController.text;
    final confirm = _regConfirmPasswordController.text;

    if (password.length < 6) {
      _showError("Password must be at least 6 characters.");
      return;
    }
    if (password != confirm) {
      _showError("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    final success = await SupabaseService.registerStaff(_verifiedStaff!['id'], password);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      // Auto login after registering
      _routeToDashboard(_verifiedStaff!);
    } else {
      _showError("Failed to set password. Please try again.");
    }
  }

  void _routeToDashboard(Map<String, dynamic> staff) {
    // Map string role to Enum
    final roleStr = (staff['role'] as String).toUpperCase();
    StaffRole mappedRole = StaffRole.baker; // fallback

    if (roleStr.contains('BAKER')) mappedRole = StaffRole.baker;
    else if (roleStr.contains('CASHIER')) mappedRole = StaffRole.cashier;
    else if (roleStr.contains('DELIVERY')) mappedRole = StaffRole.delivery;
    else if (roleStr.contains('MANAGER')) mappedRole = StaffRole.manager;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => StaffDashboard(role: mappedRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDByacWHy0qBkvb3ebrlLczBbsGfLJBx9g4Vj3Hf4Rf569lIXYKgH5nlnkTzU9zV4vEdhwPTtSpJbUM35KeRyEkvcU8cANByCauDlJo-EbylTpSvlTVI4mi8vLC2KjT5unMk_UwxMzUa_iRFQpAWBRVM-cIwySNaEJKYvDZAga_G0__V0h0mKmn7WZfPBUWETga8cpX86pb2zsU5fiMipshkb08cFRwG1zuIO7psicDnlPSrRJrC1Wva6_OgBNVKJ0I64vcZYWy7-KE',
            fit: BoxFit.cover,
          ),
          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.85],
                colors: [
                  Color(0x882B1606), 
                  Color(0xF2FFF8F5), 
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_rounded, size: 48, color: cs.primary),
                            const SizedBox(height: 24),
                            Text(
                              "Staff Portal",
                              style: GoogleFonts.notoSerif(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: cs.secondary,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Tabs
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildTabButton(
                                      "Login", 
                                      _isLoginTab, 
                                      () => setState(() {
                                        _isLoginTab = true;
                                        _errorMessage = null;
                                      }),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildTabButton(
                                      "First Time", 
                                      !_isLoginTab, 
                                      () => setState(() {
                                        _isLoginTab = false;
                                        _errorMessage = null;
                                        _verifiedStaff = null; // reset flow
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.plusJakartaSans(color: Colors.red, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isLoginTab ? _buildLoginTab(cs) : _buildRegisterTab(cs),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : cs.secondary.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab(ColorScheme cs) {
    return Column(
      key: const ValueKey('login'),
      children: [
        _buildTextField(
          controller: _loginPhoneController,
          label: "Mobile Number",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          prefixText: "+91 ",
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _loginPasswordController,
          label: "Password",
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Or use Windows Hello / Biometrics",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: cs.secondary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: _handleBiometricLogin,
              icon: const Icon(Icons.fingerprint_rounded),
              tooltip: "Login with Windows Hello / Fingerprint",
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton("Login securely", _handleLogin),
      ],
    );
  }

  Widget _buildRegisterTab(ColorScheme cs) {
    if (_verifiedStaff != null) {
      return Column(
        key: const ValueKey('set_password'),
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              Text(
                "Verified as ${_verifiedStaff!['name']}",
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _regPasswordController,
            label: "Create new password",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _regConfirmPasswordController,
            label: "Confirm password",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton("Set Password & Login", _handleSetPassword),
        ],
      );
    }

    return Column(
      key: const ValueKey('verify_code'),
      children: [
        _buildTextField(
          controller: _regPhoneController,
          label: "Mobile Number",
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          prefixText: "+91 ",
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _regCodeController,
          label: "5-Character Code",
          icon: Icons.vpn_key_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        Text(
          "Ask the owner or manager for your one-time joining code.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton("Verify Code", _handleVerifyCode),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? prefixText,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(color: cs.secondary.withValues(alpha: 0.6)),
        prefixIcon: Icon(icon, color: cs.primary.withValues(alpha: 0.6)),
        prefixText: prefixText,
        prefixStyle: GoogleFonts.plusJakartaSans(
          color: cs.secondary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        filled: true,
        fillColor: cs.surfaceContainerLow,
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
      ),
    );
  }
}
