import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  TextToSpeechService();

  final FlutterTts _tts = FlutterTts();

  Future<void> speakFinishLine() async {
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1);
      await _tts.speak("You've reached the finish line.");
    } catch (_) {
      // Ride completion should never be blocked by a TTS failure.
    }
  }
}
