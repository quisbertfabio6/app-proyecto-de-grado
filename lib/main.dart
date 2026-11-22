import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/sita_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sitaThemeController.load();
  runApp(const SitaApp());
}

class SitaApp extends StatelessWidget {
  const SitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sitaThemeController,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SITA App',
        theme: sitaLightTheme,
        darkTheme: sitaDarkTheme,
        themeMode: sitaThemeController.mode,
        home: const SplashScreen(),
      ),
    );
  }
}
