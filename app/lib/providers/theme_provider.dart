import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeState {
  final ThemeMode mode;
  final bool isDark;

  ThemeState({required this.mode}) : isDark = mode == ThemeMode.dark;

  ThemeState copyWith({ThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() => ThemeState(mode: ThemeMode.dark);

  void toggleTheme() {
    state = ThemeState(
      mode: state.isDark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void setTheme(ThemeMode mode) {
    state = ThemeState(mode: mode);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  () => ThemeNotifier(),
);
