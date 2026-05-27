import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'auth_service.dart';

/// Key used to persist owner auth in SharedPreferences
const _kOwnerAuthKey = 'owner_is_authenticated';

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
    // Read persisted owner auth flag synchronously — SharedPreferences may not
    // be ready here, so we kick off an async restore and begin with the in-memory
    // Supabase session as the initial source of truth.
    sb.User? currentUser;
    try {
      _listenToAuthChanges();
      currentUser = sb.Supabase.instance.client.auth.currentUser;
    } catch (_) {
      // Supabase is not initialized (e.g. in test environment)
    }

    // Restore persisted owner PIN-auth flag in the background
    _restoreOwnerSession();

    return AppAuthState(
      isAuthenticated: currentUser != null,
      user: currentUser,
    );
  }

  /// Reads the persisted flag and updates state if the owner was previously
  /// authenticated via PIN (no Supabase session is involved for PIN auth).
  Future<void> _restoreOwnerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wasAuthenticated = prefs.getBool(_kOwnerAuthKey) ?? false;
      if (wasAuthenticated && !state.isAuthenticated) {
        state = state.copyWith(isAuthenticated: true);
      }
    } catch (_) {
      // Ignore — prefs unavailable (e.g. test)
    }
  }

  void _listenToAuthChanges() {
    try {
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
    } catch (_) {
      // Supabase is not initialized (e.g. in test environment)
    }
  }

  Future<bool> verifyOwnerPin(String pin) async {
    if (state.isLockedOut) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final isValid = await AuthService.verifyOwnerPin(pin);
      
      if (isValid) {
        // Persist the authenticated flag so the session survives app restarts
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kOwnerAuthKey, true);

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
    // Clear the persisted owner session flag first
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kOwnerAuthKey);
    } catch (_) {
      // Ignore
    }

    try {
      await sb.Supabase.instance.client.auth.signOut();
    } catch (_) {
      // May not have a Supabase session if PIN auth was used
    }

    state = AppAuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppAuthState>(AuthNotifier.new);
