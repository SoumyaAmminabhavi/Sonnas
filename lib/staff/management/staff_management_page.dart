import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/staff_service.dart';
import 'staff_add_page.dart';
import '../../widgets/secure_avatar.dart';

class ManageStaffPage extends StatefulWidget {
  final ColorScheme cs;
  final bool isDesktop;

  const ManageStaffPage({
    super.key,
    required this.cs,
    required this.isDesktop,
  });

  @override
  State<ManageStaffPage> createState() => ManageStaffPageState();
}

class ManageStaffPageState extends State<ManageStaffPage> {
  bool _isAddingStaff = false;
  Map<String, dynamic>? _editingStaff;

  void reset() {
    setState(() {
      _isAddingStaff = false;
      _editingStaff = null;
    });
  }

  void _showAddStaff({Map<String, dynamic>? staff}) {
    setState(() {
      _isAddingStaff = true;
      _editingStaff = staff;
    });
  }

  void _hideAddStaff() {
    setState(() {
      _isAddingStaff = false;
      _editingStaff = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isAddingStaff) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _hideAddStaff();
          }
        },
        child: StaffAddPage(
          cs: widget.cs,
          staff: _editingStaff,
          onClose: _hideAddStaff,
          isNested: true,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(widget.isDesktop ? 48.0 : 24.0),
          child: widget.isDesktop ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderInfo(),
              _buildAddButton(),
            ],
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderInfo(),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: _buildAddButton()),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: StaffService.getStaffStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final staffList = snapshot.data ?? [];

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: widget.isDesktop ? 48 : 24),
                itemCount: staffList.length,
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return _StaffCard(
                    staff: staff, 
                    cs: widget.cs, 
                    isDesktop: widget.isDesktop,
                    onTap: () => _showAddStaff(staff: staff),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "STAFF OPERATIONS",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: widget.cs.primary,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "MANAGE STAFF",
          style: GoogleFonts.plusJakartaSans(
            fontSize: widget.isDesktop ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: widget.cs.secondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: widget.cs.secondary.withValues(alpha: 0.1)),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => _showAddStaff(),
      icon: const Icon(Icons.add),
      label: const Text("Add Staff Member"),
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.cs.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;
  final ColorScheme cs;
  final bool isDesktop;
  final VoidCallback onTap;

  const _StaffCard({
    required this.staff, 
    required this.cs, 
    required this.isDesktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActivated = (staff['isActivated'] as bool?) ?? false;
    final String role = (staff['role'] as String?) ?? 'STAFF';
    final String subRole = (staff['sub_role'] as String?) ?? 'NONE';
    final String shift = (staff['shift'] as String?) ?? 'FULL_DAY';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
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
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SecureAvatar(
                    path: staff['imageUrl'] as String?,
                    bucket: 'staff_photos',
                    name: (staff['name'] as String?) ?? '?',
                    radius: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                (staff['name'] as String?) ?? "Unknown",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: cs.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(isActivated: isActivated, cs: cs),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              (staff['phone'] as String?) ?? "No phone",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    Text(
                      shift,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(height: 1, thickness: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 12, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        "$role • $subRole",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  if (!isActivated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
                      child: Text("ID: ${staff['id'].toString().substring(0, 5)}", style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: cs.primary)),
                    ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: cs.primary.withValues(alpha: 0.3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Staff Member?"),
        content: Text("Are you sure you want to remove ${staff['name']}? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                await StaffService.deleteStaff(staff['id'] as String);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e, st) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete staff, please try again")),
                );
                debugPrint('Failed to delete staff: $e\n$st');
              }
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent))
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
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: isActivated ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
