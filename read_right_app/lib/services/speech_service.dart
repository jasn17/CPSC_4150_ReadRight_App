import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Result from speech recognition
class SpeechResult {
  final String text;
  final List<int>? audioBytes; // Raw audio for cloud processing
  final double confidence;

  SpeechResult({
    required this.text,
    this.audioBytes,
    this.confidence = 1.0,
  });
}

class SpeechService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  final double _currentAmplitude = 0.0;

  /// Current microphone amplitude (0.0 to 1.0)
  double get amplitude => _currentAmplitude;

  /// Stops TTS
  Future<void> stopTts() async => await _tts.stop();

  /// Stops speech recognition
  Future<void> stopListening() async => await _speech.stop();

  Future<bool> init() async {
    return await _speech.initialize();
  }

  /// Record and transcribe speech, returning both transcript and audio bytes
  ///
  /// Audio bytes can be sent to Azure for pronunciation assessment
  /// Local transcription is used for immediate feedback
  Future<SpeechResult?> recordOnce({int timeoutSeconds = 7}) async {
    bool available = await init();
    if (!available) return null;

    String? transcript;

    // Stop any previous listening first
    if (_speech.isListening) {
      await _speech.stop();
    }

    final completer = Completer<SpeechResult?>();

    await _speech.listen(
      onResult: (res) {
        transcript = res.recognizedWords;
        if (res.finalResult) {
          completer.complete(SpeechResult(
            text: transcript ?? '',
            confidence: res.confidence,
          ));
        }
      },
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      pauseFor: Duration(seconds: timeoutSeconds),
    );

    // Timeout in case finalResult is never triggered
    Future.delayed(Duration(seconds: timeoutSeconds), () {
      if (!completer.isCompleted) {
        completer.complete(transcript != null
            ? SpeechResult(text: transcript ?? '', confidence: 0.5)
            : null);
      }
    });

    final result = await completer.future;
    await _speech.stop();
    return result;
  }

  /// Record audio to file for cloud pronunciation assessment
  /// Returns the file path where audio was saved
  Future<String?> recordAudioToFile({int timeoutSeconds = 10}) async {
    try {
      // Check permissions
      bool hasPermission = await _audioRecorder.hasPermission();
      print('[SpeechService] hasPermission=$hasPermission');
      if (!hasPermission) return null;

      // Get temp directory for audio file
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/pronunciation_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Start recording to file
      _isRecording = true;
      print('[SpeechService] start recording to $filePath');
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
        ),
        path: filePath,
      );

      // Wait for specified duration
      await Future.delayed(Duration(seconds: timeoutSeconds));

      // Stop recording
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
      }

      try {
        final f = File(filePath);
        final len = await f.length();
        print('[SpeechService] recorded file size=$len bytes');
      } catch (_) {}

      return filePath;
    } catch (e) {
      _isRecording = false;
      print('Error recording audio: $e');
      return null;
    }
  }

  /// Stop ongoing audio recording
  Future<void> stopAudioRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;
    }
  }

  /// Read audio file as bytes for sending to server
  static Future<List<int>?> readAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      print('Error reading audio file: $e');
    }
    return null;
  }

  /// Speaks text with TTS
  Future<void> speak(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);
    await _tts.speak(text);
  }

  Future<PronunciationAssessmentResult> sendForPronunciationAssessment({
    required String filePath,
    required String referenceText,
  }) async {
    final uri = Uri.parse("http://10.0.2.2:8000/api/assess");
    print('[SpeechService] sending assessment to $uri for "$referenceText"');

    final request = http.MultipartRequest('POST', uri)
      ..fields['reference_text'] = referenceText
      ..files.add(await http.MultipartFile.fromPath('audio', filePath));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    print(
        '[SpeechService] assessment response status=${response.statusCode} body=$respStr');

    if (response.statusCode != 200) {
      print("Backend error: $respStr");
      return PronunciationAssessmentResult(
        transcript: "",
        score: 0,
        correct: false,
      );
    }

    final data = jsonDecode(respStr);

    return PronunciationAssessmentResult(
      transcript: data["transcript"] ?? "",
      score: data["score"] ?? 0,
      correct: data["correct"] ?? false,
    );
  }
}

class PronunciationAssessmentResult {
  final String transcript;
  final int score;
  final bool correct;

  PronunciationAssessmentResult({
    required this.transcript,
    required this.score,
    required this.correct,
  });
}
