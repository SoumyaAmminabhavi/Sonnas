import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/owner_sidebar.dart';

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}


class _AddStaffPageState extends State<AddStaffPage> {
  String _selectedRole = 'BAKER';
  final Map<String, bool> _permissions = {
    'Manage Orders': true,
    'Access Inventory': true,
    'View Reports': false,
    'Handle Payments': false,
  };
  final List<String> _workingDays = ['M', 'T', 'W', 'T', 'F'];
  final List<String> _allDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  final TextEditingController _startTimeController =
      TextEditingController(text: "08:00 AM");
  final TextEditingController _endTimeController =
      TextEditingController(text: "04:00 PM");

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: cs.surface,
          appBar: isDesktop
              ? AppBar(
                  backgroundColor: cs.surface.withValues(alpha: 0.9),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "Sonna's Patisserie & Cafe",
                    style: GoogleFonts.notoSerif(
                      color: cs.primary,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                )
              : AppBar(
                  backgroundColor: cs.surface.withValues(alpha: 0.8),
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Staff",
                        style: GoogleFonts.notoSerif(
                          color: cs.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "CREATE AND ASSIGN ROLES FOR YOUR TEAM",
                        style: GoogleFonts.plusJakartaSans(
                          color: cs.secondary.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
          body: Row(
            children: [
              if (isDesktop)
                OwnerSidebar(
                  currentIndex: 4, // Active under Settings
                  onTap: (index) {
                    Navigator.pop(context, index);
                  },
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDesktop) ...[
                             Text(
                               "Add New Staff",
                               style: GoogleFonts.notoSerif(
                                 color: cs.primary,
                                 fontSize: 32,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(height: 8),
                             Text(
                               "CREATE AND ASSIGN ROLES FOR YOUR TEAM",
                               style: GoogleFonts.plusJakartaSans(
                                 color: cs.secondary.withValues(alpha: 0.6),
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold,
                                 letterSpacing: 1.0,
                               ),
                             ),
                             const SizedBox(height: 40),
                          ],
                          _buildBasicInfoSection(cs),
                          const SizedBox(height: 40),
                          _buildRoleSelectionSection(cs),
                          const SizedBox(height: 40),
                          _buildPermissionsSection(cs),
                          const SizedBox(height: 40),
                          _buildWorkDetailsSection(cs),
                          const SizedBox(height: 40),
                          _buildAccountSetupSection(cs),
                          const SizedBox(height: 40),
                          _buildActions(cs),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection(ColorScheme cs) {
    bool isMobile = MediaQuery.of(context).size.width < 500;
    return Column(
      children: [
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: cs.secondary,
                    size: 30,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildGhostInput(
                cs,
                label: "FULL NAME",
                placeholder: "e.g. Julianne Moretti",
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildGhostInput(
            cs,
            label: "PHONE NUMBER",
            placeholder: "+91 9876543210",
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          _buildGhostInput(
            cs,
            label: "EMAIL ADDRESS (OPTIONAL)",
            placeholder: "julianne@patisserie.com",
            keyboardType: TextInputType.emailAddress,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "PHONE NUMBER",
                  placeholder: "+91 9876543210",
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "EMAIL ADDRESS (OPTIONAL)",
                  placeholder: "julianne@patisserie.com",
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRoleSelectionSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SELECT STAFF ROLE",
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildRoleCard(
                    cs,
                    "BAKER",
                    Icons.cookie_outlined,
                  ),
                  _buildRoleCard(cs, "CASHIER", Icons.point_of_sale_outlined),
                  _buildRoleCard(cs, "DELIVERY", Icons.motorcycle_outlined),
                  _buildRoleCard(cs, "MANAGER", Icons.badge_outlined),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(ColorScheme cs, String role, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.1)
              : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cs.primaryContainer : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? cs.primary
                  : cs.secondary.withValues(alpha: 0.4),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected
                    ? cs.primary
                    : cs.secondary.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: cs.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                "Permissions",
                style: GoogleFonts.notoSerif(
                  color: cs.secondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._permissions.keys.map((key) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key,
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.secondary.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _buildToggle(cs, _permissions[key]!, (val) {
                    setState(() => _permissions[key] = val);
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToggle(ColorScheme cs, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 40,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? cs.primary : cs.primaryContainer.withValues(alpha: 0.4),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: value ? cs.onPrimary : cs.surface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkDetailsSection(ColorScheme cs) {
    bool isMobile = MediaQuery.of(context).size.width < 500;
    Widget shiftTiming = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SHIFT TIMING",
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "START",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  _buildGhostInput(
                    cs,
                    placeholder: "",
                    controller: _startTimeController,
                    isTime: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18.0, left: 16, right: 16),
              child: Text(
                "to",
                style: GoogleFonts.notoSerif(
                  color: cs.primary.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "END",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  _buildGhostInput(
                    cs,
                    placeholder: "",
                    controller: _endTimeController,
                    isTime: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    Widget workingDays = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "WORKING DAYS",
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _allDays.map((day) {
            bool isSelected = _workingDays.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _workingDays.remove(day);
                  } else {
                    _workingDays.add(day);
                  }
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected
                        ? cs.onPrimary
                        : cs.secondary.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [shiftTiming, const SizedBox(height: 32), workingDays],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shiftTiming,
        const SizedBox(width: 48),
        Expanded(child: workingDays),
      ],
    );
  }

  Widget _buildAccountSetupSection(ColorScheme cs) {
    bool isMobile = MediaQuery.of(context).size.width < 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: cs.primaryContainer.withValues(alpha: 0.3)),
        const SizedBox(height: 24),
        _buildGhostInput(cs, label: "USERNAME", placeholder: "staff_julianne"),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildGhostInput(
            cs,
            label: "PASSWORD",
            placeholder: "••••••••",
            obscureText: true,
          ),
          const SizedBox(height: 24),
          _buildGhostInput(
            cs,
            label: "CONFIRM PASSWORD",
            placeholder: "••••••••",
            obscureText: true,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "PASSWORD",
                  placeholder: "••••••••",
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "CONFIRM PASSWORD",
                  placeholder: "••••••••",
                  obscureText: true,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildActions(ColorScheme cs) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    "ADD STAFF",
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "CANCEL",
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostInput(
    ColorScheme cs, {
    String? label,
    required String placeholder,
    TextEditingController? controller,
    String? initialValue,
    bool obscureText = false,
    bool isTime = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: isTime,
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.3),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primaryContainer, width: 0.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            suffixIcon: isTime
                ? IconButton(
                    icon: const Icon(Icons.access_time, size: 18),
                    color: cs.secondary,
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: cs.surface,
                                hourMinuteShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: cs.primary.withValues(alpha: 0.2)),
                                ),
                                hourMinuteColor: cs.surfaceContainer,
                                hourMinuteTextColor: cs.secondary,
                                dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                                    states.contains(WidgetState.selected)
                                        ? cs.primary
                                        : Colors.transparent),
                                dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                                    states.contains(WidgetState.selected)
                                        ? cs.onPrimary
                                        : cs.secondary),
                                dayPeriodShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color: cs.primary.withValues(alpha: 0.5)),
                                ),
                                dialBackgroundColor: cs.surfaceContainer,
                                dialHandColor: cs.primary,
                                dialTextColor: cs.secondary,
                                entryModeIconColor: cs.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                helpTextStyle: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: cs.secondary,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  textStyle: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  foregroundColor: cs.primary,
                                ),
                              ),
                              colorScheme: cs.copyWith(
                                surface: cs.surface,
                                onSurface: cs.secondary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (!mounted) return;
                      if (time != null && controller != null) {
                        controller.text = time.format(context);
                      }
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

