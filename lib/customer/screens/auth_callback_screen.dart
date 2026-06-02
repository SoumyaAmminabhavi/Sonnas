import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'profile_setup_screen.dart';
import 'cart_screen.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    // Wait for Supabase to parse the URL and establish the session
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        await _authSubscription?.cancel();
        
        final user = data.session!.user;
        final metadata = user.userMetadata ?? {};
        final bool isSetupCompleted = metadata['profile_setup_completed'] == true;

        if (!mounted) return;

        if (!isSetupCompleted) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupScreen(),
            ),
          );
        } else {
          // If profile is complete, always route to my bag page as requested
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F6),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF4D8D)),
            const SizedBox(height: 24),
            Text(
              "Authenticating...",
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF701235),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
