import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/owner_sidebar.dart';

// Brand Colors - Sweet Pink Bakery Theme
const Color _bgColor = Color(0xFFFFF0F6);
const Color _primaryColor = Color(0xFFFF4D8D);
const Color _secondaryColor = Color(0xFF701235);
const Color _surfaceContainerLow = Color(0xFFFFF5F9);
const Color _outlineVariant = Color(0xFFFFB6D3);
const Color _primaryContainer = Color(0xFFFFB6D3);

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          backgroundColor: _bgColor,
          appBar: isDesktop
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: _primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    "Sonna's Patisserie & Cafe",
                    style: GoogleFonts.notoSerif(
                      color: const Color(0xFFD9B87A),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                )
              : AppBar(
                  backgroundColor: _bgColor.withValues(alpha: 0.8),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: _primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Staff",
                        style: GoogleFonts.notoSerif(
                          color: _primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "CREATE AND ASSIGN ROLES FOR YOUR TEAM",
                        style: GoogleFonts.plusJakartaSans(
                          color: _secondaryColor.withValues(alpha: 0.6),
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
                    Navigator.pop(context);
                  },
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDesktop) ...[
                             Text(
                              "Add New Staff",
                              style: GoogleFonts.notoSerif(
                                color: _primaryColor,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "CREATE AND ASSIGN ROLES FOR YOUR TEAM",
                              style: GoogleFonts.plusJakartaSans(
                                color: _secondaryColor.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                          _buildBasicInfoSection(),
                          const SizedBox(height: 40),
                          _buildRoleSelectionSection(),
                          const SizedBox(height: 40),
                          _buildPermissionsSection(),
                          const SizedBox(height: 40),
                          _buildWorkDetailsSection(),
                          const SizedBox(height: 40),
                          _buildAccountSetupSection(),
                          const SizedBox(height: 40),
                          _buildActions(),
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

  Widget _buildBasicInfoSection() {
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
                    color: _surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _outlineVariant.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: _secondaryColor,
                    size: 30,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _primaryColor,
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
                label: "FULL NAME",
                placeholder: "e.g. Julianne Moretti",
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildGhostInput(
            label: "PHONE NUMBER",
            placeholder: "+1 (555) 000-0000",
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          _buildGhostInput(
            label: "EMAIL ADDRESS (OPTIONAL)",
            placeholder: "julianne@patisserie.com",
            keyboardType: TextInputType.emailAddress,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildGhostInput(
                  label: "PHONE NUMBER",
                  placeholder: "+1 (555) 000-0000",
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGhostInput(
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

  Widget _buildRoleSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SELECT STAFF ROLE",
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor,
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
                    "BAKER",
                    Icons.cookie_outlined,
                  ), // Simplified icon for "cooking"
                  _buildRoleCard("CASHIER", Icons.point_of_sale_outlined),
                  _buildRoleCard("DELIVERY", Icons.motorcycle_outlined),
                  _buildRoleCard("MANAGER", Icons.badge_outlined),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(String role, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryContainer.withValues(alpha: 0.1)
              : _surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _primaryContainer : Colors.transparent,
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
                  ? _primaryColor
                  : _secondaryColor.withValues(alpha: 0.4),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              role,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected
                    ? _primaryColor
                    : _secondaryColor.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: _primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                "Permissions",
                style: GoogleFonts.notoSerif(
                  color: _secondaryColor,
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
                      color: _secondaryColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _buildToggle(_permissions[key]!, (val) {
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

  Widget _buildToggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 40,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? _primaryColor : _outlineVariant.withValues(alpha: 0.4),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkDetailsSection() {
    bool isMobile = MediaQuery.of(context).size.width < 500;
    Widget shiftTiming = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SHIFT TIMING",
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "START",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: _secondaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  _buildGhostInput(
                    placeholder: "",
                    initialValue: "08:00 AM",
                    isTime: true,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 20.0, left: 8, right: 8),
              child: Text("to", style: TextStyle(color: _outlineVariant)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "END",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: _secondaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                  _buildGhostInput(
                    placeholder: "",
                    initialValue: "04:00 PM",
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
            color: _secondaryColor,
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
                  color: isSelected ? _primaryColor : _surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected
                        ? Colors.white
                        : _secondaryColor.withValues(alpha: 0.5),
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
        Expanded(child: shiftTiming),
        const SizedBox(width: 40),
        Expanded(child: workingDays),
      ],
    );
  }

  Widget _buildAccountSetupSection() {
    bool isMobile = MediaQuery.of(context).size.width < 500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _outlineVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 24),
        _buildGhostInput(label: "USERNAME", placeholder: "staff_julianne"),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildGhostInput(
            label: "PASSWORD",
            placeholder: "••••••••",
            obscureText: true,
          ),
          const SizedBox(height: 24),
          _buildGhostInput(
            label: "CONFIRM PASSWORD",
            placeholder: "••••••••",
            obscureText: true,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildGhostInput(
                  label: "PASSWORD",
                  placeholder: "••••••••",
                  obscureText: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGhostInput(
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

  Widget _buildActions() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryColor, _primaryContainer],
            ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.3),
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
                      color: Colors.white,
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
              color: _secondaryColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostInput({
    String? label,
    required String placeholder,
    String? initialValue,
    bool obscureText = false,
    bool isTime = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: _secondaryColor.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(
            color: _secondaryColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: _secondaryColor.withValues(alpha: 0.3),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _outlineVariant, width: 0.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
            suffixIcon: isTime
                ? const Icon(
                    Icons.access_time,
                    color: _secondaryColor,
                    size: 18,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
