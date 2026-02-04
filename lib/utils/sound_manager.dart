import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart'; // Para vibración

class SoundManager {
  static final AudioPlayer _player = AudioPlayer();

  // Sonido de Escaneo Correcto (Beep corto)
  static Future<void> playScan() async {
    try {
      await _player.stop(); // Detener si ya sonaba algo
      await _player.play(AssetSource('sounds/beep.mp3'));
      HapticFeedback.heavyImpact(); // Vibración fuerte
    } catch (e) {
      print("Error sonido: $e");
    }
  }

  // Sonido de Éxito (Sincronización o Licencia enviada)
  static Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.mp3'));
      HapticFeedback.mediumImpact(); // Vibración media
    } catch (e) {
      print("Error sonido: $e");
    }
  }

  // Sonido de Error
  static Future<void> playError() async {
    HapticFeedback.vibrate(); // Vibración larga
    // Aquí podrías poner un sonido de error.mp3 si quieres
  }
}