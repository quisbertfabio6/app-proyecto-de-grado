import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/theme/sita_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('El modo oscuro se recupera y se guarda sin usar la API', () async {
    SharedPreferences.setMockInitialValues({'sita_dark_mode': true});

    final controller = SitaThemeController();
    await controller.load();
    expect(controller.mode, ThemeMode.dark);

    await controller.toggle();
    expect(controller.mode, ThemeMode.light);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('sita_dark_mode'), false);

    controller.dispose();
  });
}
