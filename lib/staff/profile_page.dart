import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'staff_roles.dart';

class StaffProfilePage extends StatelessWidget {
  final ColorScheme cs;
  final bool isDesktop;
  final StaffRole role;
  const StaffProfilePage({super.key, required this.cs, required this.isDesktop, required this.role});


  @override
  Widget build(BuildContext context) {
    final double imageSize = isDesktop ? 240 : 200;
    
    final String name;
    final String title;
    final List<String> specialties;
    final String stat1Label;
    final String stat1Value;
    final IconData stat1Icon;
    final String stat2Label;
    final String stat2Value;
    final IconData stat2Icon;
    final String pulse1Label;
    final String pulse1Value;
    final String pulse2Label;
    final String pulse2Value;

    switch (role) {
      case StaffRole.cashier:
        name = "Alex Costa";
        title = "Lead Cashier & Host";
        specialties = ["POS Expert", "Customer Care", "Coffee Brewing"];
        stat1Label = "CUSTOMERS";
        stat1Value = "142";
        stat1Icon = Icons.people_alt_rounded;
        stat2Label = "SHIFT TIME";
        stat2Value = "4.5h";
        stat2Icon = Icons.schedule_rounded;
        pulse1Label = "Satisfaction";
        pulse1Value = "4.8/5.0";
        pulse2Label = "Till Accuracy";
        pulse2Value = "100%";
        break;
      case StaffRole.delivery:
        name = "Marcus Johnson";
        title = "Delivery Specialist";
        specialties = ["Route Optimization", "Fragile Handling", "Express Dispatch"];
        stat1Label = "DELIVERIES";
        stat1Value = "14";
        stat1Icon = Icons.local_shipping_rounded;
        stat2Label = "ON ROAD";
        stat2Value = "3.8h";
        stat2Icon = Icons.schedule_rounded;
        pulse1Label = "On-Time Delivery";
        pulse1Value = "99%";
        pulse2Label = "Customer Feedback";
        pulse2Value = "4.9/5.0";
        break;
      case StaffRole.manager:
        name = "Sarah Jenkins";
        title = "Store Manager";
        specialties = ["Operations", "Staff Scheduling", "Inventory Control"];
        stat1Label = "PENDING";
        stat1Value = "03";
        stat1Icon = Icons.approval_rounded;
        stat2Label = "ACTIVE STAFF";
        stat2Value = "12";
        stat2Icon = Icons.groups_rounded;
        pulse1Label = "Store Revenue";
        pulse1Value = "+12%";
        pulse2Label = "Staff Efficiency";
        pulse2Value = "95%";
        break;
      case StaffRole.baker:
      default:
        name = "Elena Moretti";
        title = "Master Pastry Decorator";
        specialties = ["Chantilly Specialist", "Sugar Flowers", "Fondant Sculpting", "+2 More"];
        stat1Label = "TASKS TODAY";
        stat1Value = "08";
        stat1Icon = Icons.cake_rounded;
        stat2Label = "CLOCKED IN";
        stat2Value = "5.2h";
        stat2Icon = Icons.schedule_rounded;
        pulse1Label = "Customer Reviews";
        pulse1Value = "4.9/5.0";
        pulse2Label = "Order Accuracy";
        pulse2Value = "98%";
        break;
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: 32,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Section
                Center(
                  child: Column(
                    children: [
                      _PetalProfileImage(
                        size: imageSize,
                        imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuDo2ENnYxDVpfI8RTk9ZisL-q4SvC7DL8uXbsqzu9cjZL71n98mjLIZQmpwHtfrJ2n1RBWvNDJTdr1hCnqEb1Kab0xuL-wCeN7NdMcpfr2dVnVN8_oUPs6S98K1uqkyZqUQ81XEK_Qv9jux8M4tXZhWi3mHqTBjNtZDecLpSRG3_RdICbFO4sHu8vtLju-9RFPsvaIMULrazKm9xyXZmmXmhAteemfWdeIQEFcRBhY7scGrTyGSjx_xVOG6H-RMY4YK9j2boA4jifk",
                      ),
                      const SizedBox(height: 24),
                      Text(
                        name,
                        style: GoogleFonts.notoSerif(
                          fontSize: isDesktop ? 40 : 32,
                          fontWeight: FontWeight.w800,
                          color: cs.secondary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isDesktop ? 18 : 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Duty Status Card
                const _DutyStatusCard(),
                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                  children: [
                    _ProfileStatCard(
                      icon: stat1Icon,
                      value: stat1Value,
                      label: stat1Label,
                      color: cs.surfaceContainerLow,
                      iconColor: cs.primary,
                    ),
                    _ProfileStatCard(
                      icon: stat2Icon,
                      value: stat2Value,
                      label: stat2Label,
                      color: const Color(0xFFFCDAB2).withValues(alpha: 0.4),
                      iconColor: const Color(0xFF825433),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Specialties Section
                Text(
                  "Specialties",
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: specialties.map((s) => _SpecialtyChip(label: s, isActive: true)).toList(),
                ),
                const SizedBox(height: 32),

                // Weekly Pulse Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Weekly Pulse",
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.secondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _WeeklyPulseRow(
                        label: pulse1Label,
                        value: pulse1Value,
                        color: const Color(0xFF825433),
                      ),
                      const SizedBox(height: 16),
                      _WeeklyPulseRow(
                        label: pulse2Label,
                        value: pulse2Value,
                        color: const Color(0xFFFFB6D3),
                      ),
                    ],
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

class _PetalProfileImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  const _PetalProfileImage({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative background petal
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
                bottomLeft: Radius.circular(size * 0.3),
                bottomRight: Radius.circular(size * 0.15),
              ),
            ),
          ),
        ),
        // Main image petal
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.3),
              topRight: Radius.circular(size * 0.15),
              bottomLeft: Radius.circular(size * 0.3),
              bottomRight: Radius.circular(size * 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF705862).withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(color: Colors.white, width: 4),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}

class _DutyStatusCard extends StatefulWidget {
  const _DutyStatusCard();

  @override
  State<_DutyStatusCard> createState() => _DutyStatusCardState();
}

class _DutyStatusCardState extends State<_DutyStatusCard> {
  bool _isOn = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF705862).withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DUTY STATUS",
                style: GoogleFonts.notoSerif(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isOn ? "Ready for custom orders" : "On Break",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _isOn = !_isOn),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 64,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _isOn ? const Color(0xFFFCBF96) : Colors.grey[300],
                borderRadius: BorderRadius.circular(100),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    alignment: _isOn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: _isOn ? Alignment.centerLeft : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _isOn ? "ON" : "OFF",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isOn ? const Color(0xFF784C2B) : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color iconColor;

  const _ProfileStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.notoSerif(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withValues(alpha: 0.6),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _SpecialtyChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? cs.primaryContainer.withValues(alpha: 0.8) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? cs.secondary : cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _WeeklyPulseRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WeeklyPulseRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
