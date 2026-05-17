import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/owner_sidebar.dart';
import '../services/supabase_service.dart';
import '../services/staff_service.dart';
import '../services/constants.dart';


import '../staff/shared/staff_roles.dart';

class AddStaffPage extends StatefulWidget {
  final Map<String, dynamic>? staff;
  final bool isReadOnly;
  const AddStaffPage({super.key, this.staff, this.isReadOnly = false});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}


class _AddStaffPageState extends State<AddStaffPage> {
  StaffRole _selectedRole = StaffRole.chef;
  SubRole _selectedSubRole = SubRole.none;
  StaffShift _selectedShift = StaffShift.fullDay;
  late Map<String, bool> _permissions;
  late List<String> _workingDays;

  final List<String> _allDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  final TextEditingController _startTimeController =
      TextEditingController(text: "08:00 AM");
  final TextEditingController _endTimeController =
      TextEditingController(text: "04:00 PM");
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedBloodGroup;


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (bytes.length > AuthConstants.maxImageSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image too large. Maximum size is ${AuthConstants.maxImageSizeBytes ~/ (1024 * 1024)}MB")),
          );
        }
        return;
      }
      setState(() {
        _pickedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _permissions = {
      'Manage Orders': true,
      'Access Inventory': true,
      'Staff Management': false,
      'Hygiene & Maintenance': false,
      'Menu & Pricing': false,
      'Sales Intelligence': false,
      'Handle Payments': false,
    };
    _workingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    if (widget.staff != null) {
      final s = widget.staff!;
      _nameController.text = s['name'] ?? '';
      _phoneController.text = s['phone'] ?? '';
      _emailController.text = s['email'] ?? '';
      _addressController.text = s['address'] ?? '';
      _dobController.text = s['dob'] ?? '';
      _selectedBloodGroup = s['bloodGroup'];
      _emergencyNameController.text = s['emergencyName'] ?? '';
      _emergencyPhoneController.text = s['emergencyPhone'] ?? '';
      _selectedRole = StaffRole.values.firstWhere(
        (r) => r.dbValue == (s['role'] ?? 'CHEF'),
        orElse: () => StaffRole.chef,
      );
      _selectedSubRole = SubRole.values.firstWhere(
        (sr) => sr.name.toUpperCase() == (s['sub_role'] ?? 'NONE'),
        orElse: () => SubRole.none,
      );
      _selectedShift = StaffShift.values.firstWhere(
        (ss) => ss.dbValue == (s['shift'] ?? 'FULL_DAY'),
        orElse: () => StaffShift.fullDay,
      );
      
      if (s['permissions'] != null) {
        _permissions = Map<String, bool>.from(s['permissions']);
      }
      
      _startTimeController.text = s['shiftStart'] ?? '08:00 AM';
      _endTimeController.text = s['shiftEnd'] ?? '04:00 PM';
      
      if (s['workingDays'] != null) {
        _workingDays = List<String>.from(s['workingDays']);
      }
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
                               widget.isReadOnly ? "Staff Details" : (widget.staff != null ? "Edit Staff" : "Add New Staff"),
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
                          _buildAdditionalInfoSection(cs),
                          const SizedBox(height: 40),
                          _buildRoleSelectionSection(cs),
                          const SizedBox(height: 40),
                          _buildSubRoleSelectionSection(cs),
                          const SizedBox(height: 40),
                          _buildPermissionsSection(cs),
                          const SizedBox(height: 40),
                          _buildWorkDetailsSection(cs),
                          const SizedBox(height: 40),
                          if (!widget.isReadOnly) _buildActions(cs),
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
        GestureDetector(
          onTap: widget.isReadOnly ? null : _pickImage,
          child: Stack(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : (widget.staff?['imageUrl'] != null
                          ? FutureBuilder<String?>(
                              future: SupabaseService.getSignedUrl('staff_photos', widget.staff!['imageUrl']),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.network(snapshot.data!, fit: BoxFit.cover);
                                }
                                return Icon(Icons.add_a_photo_outlined, color: cs.secondary, size: 30);
                              },
                            )
                          : Icon(Icons.add_a_photo_outlined, color: cs.secondary, size: 30)),
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
        ),

            const SizedBox(width: 24),
            Expanded(
              child: _buildGhostInput(
                cs,
                label: "FULL NAME",
                placeholder: "e.g. Julianne Moretti",
                controller: _nameController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          _buildGhostInput(
            cs,
            label: "PHONE NUMBER",
            placeholder: "9876543210",
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixText: "+91 ",
          ),
          const SizedBox(height: 24),
          _buildGhostInput(
            cs,
            label: "EMAIL ADDRESS (OPTIONAL)",
            placeholder: "julianne@patisserie.com",
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "PHONE NUMBER",
                  placeholder: "9876543210",
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixText: "+91 ",
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "EMAIL ADDRESS (OPTIONAL)",
                  placeholder: "julianne@patisserie.com",
                  controller: _emailController,
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
          "SELECT STAFF CATEGORY",
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildRoleCard(cs, StaffRole.chef, Icons.cookie_outlined, "CHEF"),
              _buildRoleCard(cs, StaffRole.support, Icons.volunteer_activism_outlined, "SUPPORT"),
              _buildRoleCard(cs, StaffRole.cleaning, Icons.cleaning_services_outlined, "HYGIENE"),
              _buildRoleCard(cs, StaffRole.cashier, Icons.point_of_sale_outlined, "CASHIER"),
              _buildRoleCard(cs, StaffRole.delivery, Icons.motorcycle_outlined, "DELIVERY"),
              _buildRoleCard(cs, StaffRole.manager, Icons.badge_outlined, "MANAGER"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubRoleSelectionSection(ColorScheme cs) {
    if (_selectedRole != StaffRole.chef && _selectedRole != StaffRole.support) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SELECT SPECIALIZATION (SUB-ROLE)",
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<SubRole>(
          initialValue: _selectedSubRole,
          decoration: InputDecoration(
            filled: true,
            fillColor: cs.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: SubRole.values.map((sr) => DropdownMenuItem(
            value: sr,
            child: Text(sr.displayName),
          )).toList(),
          onChanged: widget.isReadOnly ? null : (v) => setState(() => _selectedSubRole = v!),
        ),
      ],
    );
  }

  Widget _buildRoleCard(ColorScheme cs, StaffRole role, IconData icon, String label) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: widget.isReadOnly ? null : () {
        setState(() {
          _selectedRole = role;
          // Auto-set permissions based on role
          _permissions['Manage Orders'] = (role == StaffRole.manager || role == StaffRole.chef || role == StaffRole.support || role == StaffRole.cashier);
          _permissions['Access Inventory'] = (role == StaffRole.manager || role == StaffRole.chef || role == StaffRole.cleaning);
          _permissions['Staff Management'] = (role == StaffRole.manager);
          _permissions['Hygiene & Maintenance'] = (role == StaffRole.manager || role == StaffRole.cleaning);
          _permissions['Menu & Pricing'] = (role == StaffRole.manager);
          _permissions['Sales Intelligence'] = (role == StaffRole.manager);
          _permissions['Handle Payments'] = (role == StaffRole.manager || role == StaffRole.cashier);
        });
      },
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
              label,
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
      onTap: widget.isReadOnly ? null : () => onChanged(!value),
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
              onTap: widget.isReadOnly ? null : () {
                setState(() {
                  if (isSelected) {
                    _workingDays.remove(day);
                  } else {
                    _workingDays.add(day);
                  }
                });
              },
              child: Container(
                width: 38,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  day.substring(0, 1),
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




  Future<String> _generateUniqueJoiningCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    for (int i = 0; i < AuthConstants.maxJoiningCodeRetries; i++) {
      final code = String.fromCharCodes(Iterable.generate(5, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
      final isTaken = await StaffService.isJoiningCodeTaken(code);
      if (!isTaken) return code;
    }
    throw StateError('Failed to generate a unique joining code after ${AuthConstants.maxJoiningCodeRetries} attempts');
  }

  Future<void> _saveStaff() async {
    final bool isEdit = widget.staff != null;
    
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill name and phone number")),
      );
      return;
    }

    // Phone validation (10 digits)
    String cleanPhone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Primary phone must be exactly 10 digits")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_pickedImage != null && _imageBytes != null) {
        final fileName = 'staff_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await StaffService.uploadStaffImage(fileName, _imageBytes!);
      }

      String? joiningCode;
      if (!isEdit) {
        joiningCode = await _generateUniqueJoiningCode();
      }

      final staff = {
        'name': _nameController.text,
        'phone': cleanPhone,
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'imageUrl': imageUrl ?? widget.staff?['imageUrl'],
        'address': _addressController.text,
        'dob': _dobController.text,
        'bloodGroup': _selectedBloodGroup,
        'emergencyName': _emergencyNameController.text,
        'emergencyPhone': _emergencyPhoneController.text.replaceAll(RegExp(r'\D'), ''),
        'role': _selectedRole.dbValue,
        'sub_role': _selectedSubRole.name.toUpperCase(),
        'shift': _selectedShift.dbValue,
        'permissions': _permissions,
        'shiftStart': _startTimeController.text,
        'shiftEnd': _endTimeController.text,
        'workingDays': _workingDays,
        if (!isEdit) 'joiningCode': joiningCode,
        if (!isEdit) 'isActivated': false,
      };

      if (isEdit) {
        await StaffService.updateStaff(widget.staff!['id'], staff);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Staff member updated")),
          );
          Navigator.pop(context);
        }
      } else {
        await StaffService.addStaff(staff);
        if (mounted) {
          _showSuccessDialog(joiningCode!);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Staff Added Successfully!",
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Please share this 5-digit joining code with the staff member. This is a one-time code for their first login.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Text(
                code,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to settings
            },
            child: const Text("DONE"),
          ),
        ],
      ),
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
              onTap: _isSaving ? null : _saveStaff,
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: _isSaving
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: cs.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.staff != null ? "SAVE CHANGES" : "ADD STAFF",
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

  Widget _buildAdditionalInfoSection(ColorScheme cs) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(cs, "RESIDENTIAL & VITAL INFO"),
        const SizedBox(height: 24),
        
        _buildGhostInput(
          cs,
          label: "HOME ADDRESS",
          placeholder: "House No, Street, Area, City, Pincode",
          controller: _addressController,
          maxLines: 2,
        ),
        const SizedBox(height: 24),

        if (isMobile) ...[
          _buildGhostInput(
            cs,
            label: "DATE OF BIRTH",
            placeholder: "Select Date",
            controller: _dobController,
            isDate: true,
          ),
          const SizedBox(height: 24),
          _buildBloodGroupDropdown(cs),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "DATE OF BIRTH",
                  placeholder: "Select Date",
                  controller: _dobController,
                  isDate: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildBloodGroupDropdown(cs)),
            ],
          ),
        
        const SizedBox(height: 32),
        _buildSectionTitle(cs, "EMERGENCY CONTACT"),
        const SizedBox(height: 24),
        
        if (isMobile) ...[
          _buildGhostInput(
            cs,
            label: "EMERGENCY CONTACT NAME",
            placeholder: "Name of relative/friend",
            controller: _emergencyNameController,
          ),
          const SizedBox(height: 24),
          _buildGhostInput(
            cs,
            label: "EMERGENCY CONTACT PHONE",
            placeholder: "00000 00000",
            controller: _emergencyPhoneController,
            keyboardType: TextInputType.phone,
            prefixText: "+91 ",
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "EMERGENCY CONTACT NAME",
                  placeholder: "Name of relative/friend",
                  controller: _emergencyNameController,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildGhostInput(
                  cs,
                  label: "EMERGENCY CONTACT PHONE",
                  placeholder: "00000 00000",
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  prefixText: "+91 ",
                ),
              ),
            ],
          ),

      ],
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 2,
          color: cs.primary,
        ),
      ],
    );
  }

  Widget _buildBloodGroupDropdown(ColorScheme cs) {
    final groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BLOOD GROUP (OPTIONAL)",
          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _selectedBloodGroup,
          hint: Text(
            "Select Group",
            style: GoogleFonts.plusJakartaSans(
              color: cs.secondary.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primaryContainer, width: 0.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down, color: cs.secondary, size: 20),
          dropdownColor: cs.surface,
          items: groups.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(
                g,
                style: GoogleFonts.plusJakartaSans(
                  color: cs.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: widget.isReadOnly ? null : (val) => setState(() => _selectedBloodGroup = val),
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
    bool isDate = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
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
          readOnly: widget.isReadOnly || isTime || isDate,
          maxLines: maxLines,

          style: GoogleFonts.plusJakartaSans(
            color: cs.secondary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(

              color: cs.secondary.withValues(alpha: 0.3),
            ),
            prefixIcon: prefixText != null
                ? Container(
                    width: 40,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      prefixText,
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),


            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primaryContainer, width: 0.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            suffixIcon: (isTime || isDate)
                ? IconButton(
                    icon: Icon(isTime ? Icons.access_time : Icons.calendar_today, size: 18),
                    color: cs.secondary,
                    onPressed: () async {
                      if (isTime) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (!mounted) return;
                        if (time != null && controller != null) {
                          controller.text = time.format(context);
                        }
                      } else if (isDate) {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (!mounted) return;
                        if (date != null && controller != null) {
                          controller.text = "${date.day}/${date.month}/${date.year}";
                        }
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

