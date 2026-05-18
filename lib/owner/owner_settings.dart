import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'add_staff_page.dart';
import 'inventory_analytics_page.dart';
import 'sales_reports_page.dart';
import 'expense_reports_page.dart';

import '../services/staff_service.dart';
import '../widgets/skeleton.dart';
import '../widgets/secure_avatar.dart';
import '../services/theme_service.dart';

class OwnerSettingsPage extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;
  const OwnerSettingsPage({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        // Removing nested Scaffold as it's hosted in OwnerDashboard
        return _SettingsContent(
          isDesktop: isDesktop,
          onTabChanged: onTabChanged,
        );
      },
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  final bool isDesktop;
  final ValueChanged<int>? onTabChanged;

  const _SettingsContent({required this.isDesktop, this.onTabChanged});

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  bool _pushNotifications = true;
  bool _inventoryAlerts = true;
  Widget? _activeSubPage;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_activeSubPage != null) {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) return;
          setState(() => _activeSubPage = null);
        },
        child: _activeSubPage!,
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isDesktop ? 48.0 : 16.0,
        vertical: 24.0,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CONTROL PANEL",
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Business Settings",
                  style: GoogleFonts.notoSerif(
                    color: cs.secondary,
                    fontSize: widget.isDesktop ? 48 : 32,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(height: 1, color: cs.secondary.withValues(alpha: 0.3)),
        const SizedBox(height: 48),

        LayoutBuilder(
          builder: (context, constraints) {
            final isTwoCol = constraints.maxWidth > 800;

            if (isTwoCol) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildEstablishmentSection(cs),
                        const SizedBox(height: 32),
                        _buildStaffSection(cs),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        _buildPreferencesSection(cs),
                        const SizedBox(height: 32),
                        _buildBISection(cs),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEstablishmentSection(cs),
                const SizedBox(height: 32),
                _buildPreferencesSection(cs),
                const SizedBox(height: 32),
                _buildStaffSection(cs),
                const SizedBox(height: 32),
                _buildBISection(cs),
                const SizedBox(height: 64),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEstablishmentSection(ColorScheme cs) {
    return _SettingsCard(
      title: "Establishment Details",
      icon: Icons.storefront,
      child: Column(
        children: [
          _buildInfoRow(cs, "Bakery Name", "Sonna's Patisserie & Cafe"),
          _buildInfoRow(cs, "Contact Phone", "+91 91132 31424"),
          _buildInfoRow(cs, "Instagram", "@sonnas__"),
          _buildInfoRow(cs, "Contact Email", "sonnaspatisseriecafe@gmail.com"),
          _buildInfoRow(
            cs,
            "Address",
            "4TH Phase, Shop No. 5,6,7 Ground Floor, \"Aum Shree\" Commercial & Residential Apartment Plot No-25, Akshay Colony, Unkal, Village, Karnataka 580021",
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.edit, size: 16, color: cs.primary),
              label: Text(
                "Edit Information",
                style: GoogleFonts.plusJakartaSans(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(ColorScheme cs) {
    return _SettingsCard(
      title: "App Preferences",
      icon: Icons.tune,
      child: Column(
        children: [
          _buildSwitchRow(
            cs,
            "Push Notifications",
            "Receive alerts for new orders",
            _pushNotifications,
            (val) => setState(() => _pushNotifications = val),
          ),
          _buildSwitchRow(
            cs,
            "Inventory Alerts",
            "Notify when ingredients are low",
            _inventoryAlerts,
            (val) => setState(() => _inventoryAlerts = val),
          ),
          _buildSwitchRow(
            cs,
            "Dark Mode",
            "Toggle between light and dark aesthetics",
            ref.watch(themeProvider) == ThemeMode.dark,
            (val) async {
              final prevTheme = ref.read(themeProvider);
              final mode = val ? ThemeMode.dark : ThemeMode.light;
              ref.read(themeProvider.notifier).setTheme(mode);
              try {
                await ThemeService.saveThemeMode(mode);
              } catch (e) {
                debugPrint("Theme Persistence Error: $e");
                if (!mounted) return;
                ref.read(themeProvider.notifier).setTheme(prevTheme);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection(ColorScheme cs) {
    return _SettingsCard(
      title: "Staff Management",
      icon: Icons.people_outline,
      child: Column(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: StaffService.getStaffStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SkeletonWrapper(
                  child: Column(
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            const Skeleton(
                              height: 40,
                              width: 40,
                              borderRadius: 20,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Skeleton(height: 14, width: 120),
                                  const SizedBox(height: 8),
                                  const Skeleton(height: 10, width: 80),
                                ],
                              ),
                            ),
                            const Skeleton(
                              height: 24,
                              width: 60,
                              borderRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final staff = snapshot.data ?? [];

              if (staff.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No staff members added yet.",
                      style: GoogleFonts.plusJakartaSans(
                        color: cs.secondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: staff
                    .map(
                      (s) => _buildStaffRow(
                        cs,
                        s['name'] ?? 'Unknown',
                        s['role'] ?? 'Staff',
                        s['isActivated'] ?? true,
                        imageUrl: s['imageUrl'],
                        staffData: s,
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddStaffPage()),
                );
                if (result != null && result is int) {
                  widget.onTabChanged?.call(result);
                }
              },
              icon: Icon(Icons.person_add, color: cs.primary),
              label: Text(
                "Add New Staff",
                style: GoogleFonts.plusJakartaSans(color: cs.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBISection(ColorScheme cs) {
    return _SettingsCard(
      title: "Business Intelligence",
      icon: Icons.insights,
      child: Column(
        children: [
          _buildActionRow(
            cs,
            "Sales Reports",
            Icons.bar_chart,
            "View historical data",
            onTap: () => setState(
              () => _activeSubPage = SalesReportsPage(
                onClose: () => setState(() => _activeSubPage = null),
              ),
            ),
          ),
          _buildActionRow(
            cs,
            "Expense Reports",
            Icons.receipt_long,
            "Analyze costs",
            onTap: () => setState(
              () => _activeSubPage = ExpenseReportsPage(
                onClose: () => setState(() => _activeSubPage = null),
              ),
            ),
          ),

          _buildActionRow(
            cs,
            "Inventory Analytics",
            Icons.inventory,
            "Stock trends",
            onTap: () => setState(
              () => _activeSubPage = InventoryAnalyticsPage(
                onClose: () => setState(() => _activeSubPage = null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ColorScheme cs, String label, String value) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 300;

        if (isSmall) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchRow(
    ColorScheme cs,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: cs.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStaffRow(
    ColorScheme cs,
    String name,
    String role,
    bool active, {
    String? imageUrl,
    Map<String, dynamic>? staffData,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          SecureAvatar(
            path: imageUrl,
            bucket: 'staff_photos',
            name: name,
            radius: 20,
            textStyle: GoogleFonts.plusJakartaSans(
              color: cs.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.plusJakartaSans(
                    color: cs.secondary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              active ? "Active" : "Offline",
              style: GoogleFonts.plusJakartaSans(
                color: active ? Colors.green[700] : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (staffData != null)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: cs.secondary.withValues(alpha: 0.5),
              ),
              elevation: 4,
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: cs.surface,
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddStaffPage(staff: staffData),
                    ),
                  );
                } else if (value == 'view') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddStaffPage(staff: staffData, isReadOnly: true),
                    ),
                  );
                } else if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Remove Staff"),
                      content: Text(
                        "Are you sure you want to remove ${staffData['name']}?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Remove",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await StaffService.deleteStaff(staffData['id']);
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "View Details",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Edit Staff",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Remove Staff",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    ColorScheme cs,
    String title,
    IconData icon,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: cs.secondary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.secondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: cs.secondary.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(icon, color: cs.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    color: cs.primary,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: cs.secondary.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
