// PURPOSE: Handles mic recording + local speech-to-text.
// DEPENDS: speech_to_text: ^6.6.0

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

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


  Future<void> stop() async {
    await _speech.stop();
  }
}
