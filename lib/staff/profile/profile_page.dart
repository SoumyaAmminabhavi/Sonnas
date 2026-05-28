import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/biometric_service.dart';
import '../../services/staff_service.dart';
import '../../services/session_service.dart';
import '../../services/theme_service.dart';
import '../../main.dart';
import '../shared/staff_roles.dart';

class StaffProfilePage extends ConsumerStatefulWidget {
  final ColorScheme cs;
  final bool isDesktop;
  final StaffRole role;
  final String staffId;
  final bool currentBiometricStatus;
  final Map<String, dynamic>? staffData;

  const StaffProfilePage({
    super.key,
    required this.cs,
    required this.isDesktop,
    required this.role,
    required this.staffId,
    required this.currentBiometricStatus,
    this.staffData,
  });

  @override
  ConsumerState<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends ConsumerState<StaffProfilePage> {
  late bool _biometricEnabled;
  late Map<String, dynamic> _localData;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = widget.currentBiometricStatus;
    _localData = Map<String, dynamic>.from(widget.staffData ?? {});
  }

  String get _displayName {
    final name = _localData['name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }
    return 'Staff Member';
  }

  String get _displayPhone {
    final phone = _localData['phone'];
    if (phone != null) return '+91 $phone';
    return '—';
  }

  String get _displayRole {
    return widget.role.name[0].toUpperCase() + widget.role.name.substring(1);
  }

  String get _displayShift {
    final start = (_localData['shiftStart'] as String?) ?? '—';
    final end = (_localData['shiftEnd'] as String?) ?? '—';
    return '$start – $end';
  }

  String get _displayBloodGroup => (_localData['bloodGroup'] as String?) ?? '—';
  String get _displayAddress => (_localData['address'] as String?) ?? '—';
  String get _displayEmail => (_localData['email'] as String?) ?? '—';
  String get _displayEmergencyName => (_localData['emergencyName'] as String?) ?? '—';
  String get _displayEmergencyPhone =>
      (_localData['emergencyPhone'] as String?) ?? '—';

  void _showEditProfileSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController(text: _localData['name'] as String? ?? '');
    final phoneCtl = TextEditingController(text: _localData['phone'] as String? ?? '');
    final emailCtl = TextEditingController(text: _localData['email'] as String? ?? '');
    final addressCtl = TextEditingController(text: _localData['address'] as String? ?? '');
    final initialBlood = _localData['bloodGroup'] as String?;
    final emergNameCtl = TextEditingController(text: _localData['emergencyName'] as String? ?? '');
    final emergPhoneCtl = TextEditingController(text: _localData['emergencyPhone'] as String? ?? '');

    bool saving = false;
    String? blood = initialBlood;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 20),
                      decoration: BoxDecoration(color: widget.cs.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Edit Profile", style: GoogleFonts.notoSerif(fontSize: 24, fontWeight: FontWeight.bold, color: widget.cs.secondary)),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: widget.cs.secondary.withValues(alpha: 0.4)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("Update your personal information", style: GoogleFonts.plusJakartaSans(fontSize: 13, color: widget.cs.secondary.withValues(alpha: 0.5))),
                    const SizedBox(height: 28),
                    _sectionLabel("PERSONAL INFORMATION", widget.cs),
                    const SizedBox(height: 16),
                    _editField("Full Name", nameCtl, Icons.person_outlined, widget.cs),
                    const SizedBox(height: 14),
                    _editField("Phone", phoneCtl, Icons.phone_outlined, widget.cs),
                    const SizedBox(height: 14),
                    _editField("Email", emailCtl, Icons.email_outlined, widget.cs),
                    const SizedBox(height: 14),
                    _editField("Address", addressCtl, Icons.location_on_outlined, widget.cs),
                    const SizedBox(height: 14),
                    _bloodDropdown(blood, (v) => setSheetState(() => blood = v), widget.cs),
                    const SizedBox(height: 28),
                    _sectionLabel("EMERGENCY CONTACT", widget.cs),
                    const SizedBox(height: 16),
                    _editField("Contact Name", emergNameCtl, Icons.person_outline_rounded, widget.cs),
                    const SizedBox(height: 14),
                    _editField("Contact Phone", emergPhoneCtl, Icons.phone_forwarded_outlined, widget.cs),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: saving ? null : () async {
                          if (!formKey.currentState!.validate()) return;
                          setSheetState(() => saving = true);
                          final updates = <String, dynamic>{};
                          updates['name'] = nameCtl.text.trim();
                          updates['phone'] = phoneCtl.text.trim();
                          updates['email'] = emailCtl.text.trim();
                          updates['address'] = addressCtl.text.trim();
                           updates['bloodGroup'] = blood;

                          updates['emergencyName'] = emergNameCtl.text.trim();
                          updates['emergencyPhone'] = emergPhoneCtl.text.trim();
                          try {
                            await StaffService.updateStaff(widget.staffId, updates);
                            if (mounted && ctx.mounted) {
                              setState(() {
                                _localData.addAll(updates);
                                if (widget.staffData != null) {
                                  widget.staffData!.addAll(updates);
                                }
                              });
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Profile updated"), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setSheetState(() { saving = false; });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.cs.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: saving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Text("SAVE CHANGES", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label, ColorScheme cs) {
    return Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 1.8));
  }

  Widget _bloodDropdown(String? selected, ValueChanged<String?> onChanged, ColorScheme cs) {
    const groups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        initialValue: groups.contains(selected) ? selected : null,
        hint: Row(
          children: [
            Icon(Icons.water_drop_outlined, size: 18, color: cs.primary.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Text("Blood Group", style: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.secondary.withValues(alpha: 0.3))),
          ],
        ),
        items: groups.map((g) => DropdownMenuItem(
          value: g,
          child: Text(g, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: cs.secondary)),
        )).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.secondary.withValues(alpha: 0.4)),
        dropdownColor: cs.surface,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _editField(String label, TextEditingController controller, IconData icon, ColorScheme cs) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: cs.secondary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.5)),
        hintText: label,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.secondary.withValues(alpha: 0.3)),
        filled: true,
        fillColor: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.secondary.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.3))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double imageSize = widget.isDesktop ? 200 : 160;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 48 : 24,
        vertical: 32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Text(
                  "STAFF MEMBER",
                  style: GoogleFonts.plusJakartaSans(
                    color: widget.cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Profile",
                  style: GoogleFonts.notoSerif(
                    fontSize: widget.isDesktop ? 48 : 36,
                    color: widget.cs.secondary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  color: widget.cs.secondary.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 48),

                Center(
                  child: Column(
                    children: [
                      _PetalProfileImage(
                        size: imageSize,
                        imageUrl: _localData['imageUrl'] as String?,
                        name: _displayName,
                        cs: widget.cs,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _displayName,
                        style: GoogleFonts.notoSerif(
                          fontSize: widget.isDesktop ? 36 : 28,
                          fontWeight: FontWeight.w800,
                          color: widget.cs.secondary,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _displayRole.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: widget.cs.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    height: 44,
                    child: TextButton.icon(
                      onPressed: _showEditProfileSheet,
                      icon: Icon(Icons.edit_outlined, size: 16, color: widget.cs.primary),
                      label: Text(
                        "EDIT PROFILE",
                        style: GoogleFonts.plusJakartaSans(
                          color: widget.cs.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                          side: BorderSide(color: widget.cs.primary.withValues(alpha: 0.3)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Duty Status Card
                _DutyStatusCard(shift: _displayShift),
                const SizedBox(height: 16),

                // Info Grid
                GridView.count(
                  crossAxisCount: widget.isDesktop ? 2 : 1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: widget.isDesktop ? 1.8 : 3.0,
                  children: [
                    _InfoCard(
                      icon: Icons.phone_rounded,
                      label: "MOBILE",
                      value: _displayPhone,
                      cs: widget.cs,
                    ),
                    _InfoCard(
                      icon: Icons.email_outlined,
                      label: "EMAIL",
                      value: _displayEmail,
                      cs: widget.cs,
                    ),
                    _InfoCard(
                      icon: Icons.water_drop_outlined,
                      label: "BLOOD GROUP",
                      value: _displayBloodGroup,
                      cs: widget.cs,
                    ),
                    _InfoCard(
                      icon: Icons.location_on_outlined,
                      label: "ADDRESS",
                      value: _displayAddress,
                      cs: widget.cs,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Emergency Contact
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.cs.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emergency_rounded,
                        color: Colors.orange.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EMERGENCY CONTACT",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange.shade800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _displayEmergencyName,
                              style: GoogleFonts.notoSerif(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.cs.secondary,
                              ),
                            ),
                            Text(
                              _displayEmergencyPhone,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: widget.cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Security & Auth Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: widget.cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: widget.cs.primary.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Security & Auth",
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.cs.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.cs.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: widget.cs.primary,
                          ),
                        ),
                        title: Text(
                          "Biometric Login",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: widget.cs.secondary,
                          ),
                        ),
                        subtitle: Text(
                          _biometricEnabled
                              ? "Fingerprint / Face ID login is enabled"
                              : "Enable for quick fingerprint / Face ID login",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: widget.cs.onSurfaceVariant,
                          ),
                        ),
                        trailing: Switch(
                          value: _biometricEnabled,
                          activeThumbColor: widget.cs.primary,
                          onChanged: (val) async {
                            try {
                              if (val) {
                                final bool canCheck =
                                    await BiometricService.canCheckBiometrics();
                                if (!canCheck) {
                                  if (!mounted) return;
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              "No biometric hardware detected.",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                    );
                                  }
                                  return;
                                }
                                final bool success =
                                    await BiometricService.authenticate();
                                if (success) {
                                  final bool dbUpdated =
                                      await StaffService.updateBiometricStatus(
                                        widget.staffId,
                                        val,
                                      );
                                  if (!context.mounted) return;

                                  if (dbUpdated) {
                                    await SessionService.updateBiometricStatus(val);
                                    if (!context.mounted) return;
                                    if (widget.staffData != null) {
                                      widget.staffData!['biometricEnabled'] = val;
                                    }
                                    setState(() => _biometricEnabled = val);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "Biometric Login Enabled",
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Revert toggle on failure
                                    setState(() => _biometricEnabled = !val);
                                  }
                                }
                              } else {
                                final bool dbUpdated =
                                    await StaffService.updateBiometricStatus(
                                      widget.staffId,
                                      false,
                                    );
                                if (!context.mounted) return;

                                if (dbUpdated) {
                                  await SessionService.updateBiometricStatus(false);
                                  if (!context.mounted) return;
                                  if (widget.staffData != null) {
                                    widget.staffData!['biometricEnabled'] = false;
                                  }
                                  setState(() => _biometricEnabled = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              "Biometric Login Disabled",
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  // Revert toggle on failure
                                  setState(() => _biometricEnabled = !val);
                                }
                              }
                            } catch (e) {
                              debugPrint('Biometric toggle error: $e');
                              // Revert toggle on exception
                              if (mounted) {
                                setState(() => _biometricEnabled = !val);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Failed to update biometric settings. Please try again.",
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const Divider(height: 32),
                      Builder(
                        builder: (context) {
                          final themeMode = ref.watch(themeProvider);
                          final isDarkEnabled =
                              themeMode == ThemeMode.dark ||
                              (themeMode == ThemeMode.system &&
                                  Theme.of(context).brightness ==
                                      Brightness.dark);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.cs.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDarkEnabled
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: widget.cs.primary,
                              ),
                            ),
                            title: Text(
                              "Dark Mode",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: widget.cs.secondary,
                              ),
                            ),
                            subtitle: Text(
                              "Adjust app appearance",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: widget.cs.onSurfaceVariant,
                              ),
                            ),
                            trailing: Switch(
                              value: isDarkEnabled,
                              activeThumbColor: widget.cs.primary,
                              onChanged: (val) async {
                                final prevTheme = ref.read(themeProvider);
                                final mode = val
                                    ? ThemeMode.dark
                                    : ThemeMode.light;
                                ref.read(themeProvider.notifier).setTheme(mode);
                                try {
                                  await ThemeService.saveThemeMode(mode);
                                } catch (e) {
                                  debugPrint("Theme Persistence Error: $e");
                                  ref
                                      .read(themeProvider.notifier)
                                      .setTheme(prevTheme);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Failed to save theme preference"),
                                        ),
                                      );
                                    }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      // Do NOT clear biometric status on logout
                      await SessionService.clearSession();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(
                      "Log Out",
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-Widgets ─────────────────────────────────────────────────────────────

class _PetalProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final ColorScheme cs;

  const _PetalProfileImage({
    required this.imageUrl,
    required this.name,
    required this.size,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(12, 12),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.3),
                topRight: Radius.circular(size * 0.15),
                bottomLeft: Radius.circular(size * 0.15),
                bottomRight: Radius.circular(size * 0.4),
              ),
            ),
          ),
        ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.4),
              topRight: Radius.circular(size * 0.15),
              bottomLeft: Radius.circular(size * 0.15),
              bottomRight: Radius.circular(size * 0.3),
            ),
            image: (imageUrl != null && imageUrl!.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.notoSerif(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _DutyStatusCard extends StatelessWidget {
  final String shift;
  const _DutyStatusCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B4D3E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF64FFDA),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    "Currently on Duty",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "SHIFT: $shift",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: cs.secondary.withValues(alpha: 0.4),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.secondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
