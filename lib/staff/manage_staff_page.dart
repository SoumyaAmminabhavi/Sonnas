import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import 'staff_roles.dart';

class ManageStaffPage extends StatefulWidget {
  final ColorScheme cs;
  final bool isDesktop;

  const ManageStaffPage({
    super.key,
    required this.cs,
    required this.isDesktop,
  });

  @override
  State<ManageStaffPage> createState() => _ManageStaffPageState();
}

class _ManageStaffPageState extends State<ManageStaffPage> {
  String _generateJoiningCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No O, 0, I, 1
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _showAddStaffDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    StaffRole selectedRole = StaffRole.chef;
    SubRole selectedSubRole = SubRole.none;
    StaffShift selectedShift = StaffShift.fullDay;
    String generatedCode = _generateJoiningCode();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            "Add New Staff Member",
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                    prefixIcon: Icon(Icons.phone_outlined),
                    prefixText: "+91 ",
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                _buildRoleSelection(widget.cs, selectedRole, (v) => setDialogState(() => selectedRole = v!)),
                const SizedBox(height: 24),
                if (selectedRole == StaffRole.chef || selectedRole == StaffRole.support)
                  DropdownButtonFormField<SubRole>(
                    value: selectedSubRole,
                    decoration: InputDecoration(
                      labelText: "Specialization (Sub-Role)",
                      prefixIcon: const Icon(Icons.stars_outlined),
                      filled: true,
                      fillColor: widget.cs.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: SubRole.values.map((sr) => DropdownMenuItem(
                      value: sr,
                      child: Text(sr.displayName),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedSubRole = v!),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StaffShift>(
                  value: selectedShift,
                  decoration: InputDecoration(
                    labelText: "Shift",
                    prefixIcon: const Icon(Icons.access_time),
                    filled: true,
                    fillColor: widget.cs.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: StaffShift.values.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedShift = v!),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.cs.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "JOINING CODE",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            generatedCode,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: widget.cs.primary,
                              letterSpacing: 4.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: () => setDialogState(() => generatedCode = _generateJoiningCode()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  return;
                }
                setDialogState(() => isSubmitting = true);
                try {
                  await SupabaseService.addStaff({
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'role': selectedRole.dbValue,
                    'sub_role': selectedSubRole.name.toUpperCase(),
                    'shift': selectedShift.dbValue,
                    'joiningCode': generatedCode,
                    'isActivated': false,
                    'permissions': {}, // Placeholder
                    'shiftStart': '09:00',
                    'shiftEnd': '18:00',
                    'workingDays': ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
                  });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  setDialogState(() => isSubmitting = false);
                }
              },
              child: isSubmitting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text("Add Staff"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupabaseService.getStaffStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final staffList = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Manage Staff",
                          style: GoogleFonts.notoSerif(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: widget.cs.secondary,
                          ),
                        ),
                        Text(
                          "Assign roles, shifts, and joining codes",
                          style: GoogleFonts.plusJakartaSans(
                            color: widget.cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddStaffDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Staff Member"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return _StaffCard(staff: staff, cs: widget.cs);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleSelection(ColorScheme cs, StaffRole selected, ValueChanged<StaffRole?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CATEGORY",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: cs.primary.withValues(alpha: 0.7),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: StaffRole.values.where((r) => r != StaffRole.manager).map((role) {
              final isSelected = selected == role;
              IconData icon;
              switch (role) {
                case StaffRole.manager: icon = Icons.badge_outlined; break;
                case StaffRole.chef: icon = Icons.cookie_outlined; break;
                case StaffRole.support: icon = Icons.volunteer_activism_outlined; break;
                case StaffRole.cleaning: icon = Icons.cleaning_services_outlined; break;
                case StaffRole.cashier: icon = Icons.point_of_sale_outlined; break;
                case StaffRole.delivery: icon = Icons.motorcycle_outlined; break;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(role.displayName),
                  avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : cs.primary),
                  selected: isSelected,
                  onSelected: (val) => onChanged(role),
                  selectedColor: cs.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : cs.secondary,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final ColorScheme cs;

  const _StaffCard({required this.staff, required this.cs});

  @override
  Widget build(BuildContext context) {
    final bool isActivated = staff['isActivated'] ?? false;
    final String role = staff['role'] ?? 'STAFF';
    final String subRole = staff['sub_role'] ?? 'NONE';
    final String shift = staff['shift'] ?? 'FULL_DAY';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.3),
            child: Text(
              staff['name']?[0]?.toUpperCase() ?? "?",
              style: GoogleFonts.notoSerif(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      staff['name'] ?? "Unknown",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(isActivated: isActivated, cs: cs),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      staff['phone'] ?? "No phone",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.badge_outlined, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      "$role • $subRole",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                shift,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.secondary.withValues(alpha: 0.5),
                ),
              ),
              if (!isActivated) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "CODE: ${staff['joiningCode']}",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: cs.secondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              // Confirmation dialog before delete
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Staff Member?"),
                  content: Text("Are you sure you want to remove ${staff['name']}? This action cannot be undone."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    TextButton(
                      onPressed: () async {
                        await SupabaseService.deleteStaff(staff['id']);
                        if (context.mounted) Navigator.pop(context);
                      }, 
                      child: const Text("Delete", style: TextStyle(color: Colors.redAccent))
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActivated;
  final ColorScheme cs;

  const _StatusBadge({required this.isActivated, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActivated 
            ? Colors.green.withValues(alpha: 0.1) 
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActivated 
              ? Colors.green.withValues(alpha: 0.3) 
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isActivated ? "ACTIVE" : "PENDING",
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActivated ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
