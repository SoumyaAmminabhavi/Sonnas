import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'auth_service.dart';

/// Local application-level Auth State
class AppAuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final sb.User? user;
  final int attempts;
  final DateTime? lockoutUntil;
  final String? error;

  AppAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.attempts = 0,
    this.lockoutUntil,
    this.error,
  });

  bool get isLockedOut => lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  AppAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    sb.User? user,
    int? attempts,
    DateTime? lockoutUntil,
    String? error,
  }) {
    return AppAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      attempts: attempts ?? this.attempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends Notifier<AppAuthState> {
  StreamSubscription<sb.AuthState>? _authSubscription;

  @override
  AppAuthState build() {
    // Listen for Supabase Auth changes
    _listenToAuthChanges();
    
    final currentUser = sb.Supabase.instance.client.auth.currentUser;
    return AppAuthState(
      isAuthenticated: currentUser != null,
      user: currentUser,
    );
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      state = state.copyWith(
        isAuthenticated: session != null,
        user: session?.user,
      );
    });

    // Cleanup subscription when provider is disposed
    ref.onDispose(() => _authSubscription?.cancel());
  }

  Future<bool> verifyOwnerPin(String pin) async {
    if (state.isLockedOut) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final isValid = await AuthService.verifyOwnerPin(pin);
      
      if (isValid) {
        state = state.copyWith(
          isLoading: false, 
          isAuthenticated: true, 
          attempts: 0,
          error: null
        );
        return true;
      } else {
        final newAttempts = state.attempts + 1;
        DateTime? newLockout;
        if (newAttempts >= 3) {
          newLockout = DateTime.now().add(const Duration(seconds: 30));
        }
        state = state.copyWith(
          isLoading: false,
          attempts: newAttempts,
          lockoutUntil: newLockout,
          error: "Incorrect PIN",
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Verification error");
      return false;
    }
  }

  Future<void> signOut() async {
    await sb.Supabase.instance.client.auth.signOut();
    state = AppAuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);
