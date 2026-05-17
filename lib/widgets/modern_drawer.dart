import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../owner/owner_dashboard.dart';
import '../staff/auth/login_page.dart';
import '../services/auth_provider.dart';

class ModernDrawer extends ConsumerWidget {
  const ModernDrawer({super.key});

  void _showOwnerAuth(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);

            return AlertDialog(
              title:
                  Text("Owner Authentication", style: GoogleFonts.notoSerif()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Please enter your admin PIN to continue.",
                      style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter PIN",
                      border: const OutlineInputBorder(),
                      errorText: authState.error,
                    ),
                  ),
                  if (authState.isLockedOut)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Too many attempts. Try again in ${authState.lockoutUntil!.difference(DateTime.now()).inSeconds}s",
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: authState.isLoading || authState.isLockedOut
                      ? null
                      : () async {
                          final isValid = await ref
                              .read(authProvider.notifier)
                              .verifyOwnerPin(pinController.text);
                          if (isValid && context.mounted) {
                            final navigator = Navigator.of(context, rootNavigator: true);
                            Navigator.pop(context);
                            navigator.push(
                              MaterialPageRoute(
                                settings:
                                    const RouteSettings(name: 'OwnerDashboard'),
                                builder: (context) => const OwnerDashboard(),
                              ),
                            );
                          }
                        },
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("VERIFY"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: cs.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Sonna's Patisserie & Cafe",
                      style: GoogleFonts.notoSerif(
                        color: cs.primary,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Consumer(
                builder: (context, ref, child) {
                  final isAuthenticated =
                      ref.watch(authProvider).isAuthenticated;
                  return _DrawerItem(
                    icon: isAuthenticated
                        ? Icons.dashboard_outlined
                        : Icons.admin_panel_settings_outlined,
                    label:
                        isAuthenticated ? "Go to Dashboard" : "Login as Owner",
                    onTap: () {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      Navigator.of(context).pop();
                      if (isAuthenticated) {
                        navigator.push(
                          MaterialPageRoute(
                            settings:
                                const RouteSettings(name: 'OwnerDashboard'),
                            builder: (context) => const OwnerDashboard(),
                          ),
                        );
                      } else {
                        _showOwnerAuth(navigator.context, ref);
                      }
                    },
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.badge_outlined,
                label: "Login as Staff",
                onTap: () {
                  final navigator = Navigator.of(context, rootNavigator: true);
                  Navigator.of(context).pop();
                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => const StaffLoginPage(),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Divider(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              _DrawerItem(icon: Icons.info_outline, label: "Business Info"),
              Consumer(
                builder: (context, ref, child) {
                  final isAuthenticated =
                      ref.watch(authProvider).isAuthenticated;
                  if (!isAuthenticated) return const SizedBox();

                  return _DrawerItem(
                    icon: Icons.logout,
                    label: "Sign Out",
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  );
                },
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LOCATION",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "4TH Phase, Shop No. 5,6,7 Ground Floor, Hubballi",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: cs.onSurface,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _DrawerItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      hoverColor: cs.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
