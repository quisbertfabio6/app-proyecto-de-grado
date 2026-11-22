import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencia visual local. No usa API, tokens ni credenciales.
class SitaThemeController extends ChangeNotifier {
  static const _preferenceKey = 'sita_dark_mode';
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _mode = preferences.getBool(_preferenceKey) == true
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (_) {
      _mode = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_preferenceKey, isDark);
    } catch (_) {
      // El tema funciona durante esta sesión aunque falle el almacenamiento.
    }
  }
}

final sitaThemeController = SitaThemeController();

const _sitaRed = Color(0xFFD32F2F);
const _sitaBackgroundDark = Color(0xFF111827);
const _sitaSurfaceDark = Color(0xFF1C2737);
const _sitaTextDark = Color(0xFFE9EEF7);

ThemeData get sitaLightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _sitaRed),
      scaffoldBackgroundColor: const Color(0xFFF6F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

ThemeData get sitaDarkTheme {
  final colors = ColorScheme.fromSeed(
    seedColor: _sitaRed,
    brightness: Brightness.dark,
  ).copyWith(
    surface: _sitaSurfaceDark,
    onSurface: _sitaTextDark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colors,
    scaffoldBackgroundColor: _sitaBackgroundDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: _sitaSurfaceDark,
      foregroundColor: _sitaTextDark,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: _sitaSurfaceDark,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: _sitaSurfaceDark,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF172233),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

class SitaThemeToggle extends StatelessWidget {
  final bool showLabel;

  const SitaThemeToggle({super.key, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sitaThemeController,
      builder: (context, _) {
        final dark = sitaThemeController.isDark;
        final tooltip = dark ? 'Activar modo claro' : 'Activar modo oscuro';
        final icon = dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined;

        if (showLabel) {
          return TextButton.icon(
            onPressed: sitaThemeController.toggle,
            icon: Icon(icon),
            label: Text(dark ? 'Modo claro' : 'Modo oscuro'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          );
        }

        return IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: sitaThemeController.toggle,
        );
      },
    );
  }
}
