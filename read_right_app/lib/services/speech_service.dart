import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class SpeechService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  /// Stops TTS
  Future<void> stopTts() async => await _tts.stop();

  /// Stops speech recognition
  Future<void> stopListening() async => await _speech.stop();

  Future<bool> init() async {
    return await _speech.initialize();
  }

  Future<String?> recordOnce({int timeoutSeconds = 7}) async {
    bool available = await init();
    if (!available) return null;

    String? transcript;

    // Stop any previous listening first
    if (_speech.isListening) {
      await _speech.stop();
    }

    final completer = Completer<String?>();

    await _speech.listen(
      onResult: (res) {
        transcript = res.recognizedWords;
        if (res.finalResult) {
          completer.complete(transcript);
        }
      },
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      pauseFor: Duration(seconds: timeoutSeconds),
    );

    // Timeout in case finalResult is never triggered
    Future.delayed(Duration(seconds: timeoutSeconds), () {
      if (!completer.isCompleted) completer.complete(transcript);
    });

    final result = await completer.future;
    await _speech.stop();
    return result;
  }

  /// Speaks text with TTS
  Future<void> speak(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);
    await _tts.speak(text);
  }
}
