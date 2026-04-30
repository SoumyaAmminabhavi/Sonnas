import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'add_staff_page.dart';

class OwnerSettingsPage extends StatelessWidget {
  final ValueChanged<int>? onTabChanged;
  const OwnerSettingsPage({super.key, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        // Removing nested Scaffold as it's hosted in OwnerDashboard
        return _SettingsContent(isDesktop: isDesktop, onTabChanged: onTabChanged);
      },
    );
  }
}

class _SettingsContent extends StatefulWidget {
  final bool isDesktop;
  final ValueChanged<int>? onTabChanged;

  const _SettingsContent({required this.isDesktop, this.onTabChanged});

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  bool _pushNotifications = true;
  bool _inventoryAlerts = true;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = themeController.value == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
        Container(
          height: 1,
          color: cs.secondary.withValues(alpha: 0.3),
        ),
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
          _buildInfoRow(cs, "Address", "4TH Phase, Shop No. 5,6,7 Ground Floor, \"Aum Shree\" Commercial & Residential Apartment Plot No-25, Akshay Colony, Unkal, Village, Karnataka 580021"),
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
            _isDarkMode,
            (val) {
              setState(() {
                _isDarkMode = val;
                themeController.value = val ? ThemeMode.dark : ThemeMode.light;
              });
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
          _buildStaffRow(cs, "Chef Julian", "Senior Artisan", true),
          _buildStaffRow(cs, "Aisha M.", "Pastry Assistant", true),
          _buildStaffRow(cs, "Marcus T.", "Delivery", false),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddStaffPage()),
                );
                if (result is int && widget.onTabChanged != null) {
                  widget.onTabChanged!(result);
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
          _buildActionRow(cs, "Sales Reports", Icons.bar_chart, "View historical data"),
          _buildActionRow(cs, "Expense Reports", Icons.receipt_long, "Analyze costs"),
          _buildActionRow(cs, "Inventory Analytics", Icons.inventory, "Stock trends"),
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

  Widget _buildSwitchRow(ColorScheme cs, String title, String subtitle, bool value, ValueChanged<bool>? onChanged) {
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

  Widget _buildStaffRow(ColorScheme cs, String name, String role, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.1),
            child: Text(
              name[0],
              style: GoogleFonts.plusJakartaSans(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
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
              color: active ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
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
        ],
      ),
    );
  }

  Widget _buildActionRow(ColorScheme cs, String title, IconData icon, String subtitle) {
    return InkWell(
      onTap: () {},
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
            Icon(Icons.chevron_right, color: cs.secondary.withValues(alpha: 0.5)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: child,
          ),
        ],
      ),
    );
  }
}
