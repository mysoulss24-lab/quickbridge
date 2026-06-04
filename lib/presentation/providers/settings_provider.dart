import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final ThemeMode themeMode;
  final int? cleanupHours; // hours, null = never

  SettingsState({
    required this.themeMode,
    required this.cleanupHours,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? cleanupHours,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      cleanupHours: cleanupHours ?? this.cleanupHours,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(themeMode: ThemeMode.system, cleanupHours: 24));

  void toggleTheme(bool isDark) {
    state = state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void updateCleanupHours(int? hours) {
    state = state.copyWith(cleanupHours: hours);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
