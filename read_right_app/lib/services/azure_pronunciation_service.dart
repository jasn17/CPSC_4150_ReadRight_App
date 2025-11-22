// FILE: lib/services/azure_pronunciation_service.dart
// PURPOSE: Interface for Azure pronunciation assessment scoring
// The actual speech processing happens on the backend server

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PronunciationScore {
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double prosodyScore;
  final double pronunciationScore;
  final String recognizedText;
  final Map<String, dynamic>? detailedResults; // Full assessment details

  PronunciationScore({
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.prosodyScore,
    required this.pronunciationScore,
    required this.recognizedText,
    this.detailedResults,
  });

  /// Convert Azure score (0-100) to simple pass/fail (0-100 compatible)
  int get simpleScore => pronunciationScore.toInt();

  /// Determine if pronunciation is acceptable (>= 80)
  bool get isPassed => pronunciationScore >= 80;

  factory PronunciationScore.fromJson(Map<String, dynamic> json) {
    return PronunciationScore(
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble() ?? 0.0,
      fluencyScore: (json['fluencyScore'] as num?)?.toDouble() ?? 0.0,
      completenessScore: (json['completenessScore'] as num?)?.toDouble() ?? 0.0,
      prosodyScore: (json['prosodyScore'] as num?)?.toDouble() ?? 0.0,
      pronunciationScore:
          (json['pronunciationScore'] as num?)?.toDouble() ?? 0.0,
      recognizedText: json['recognizedText'] as String? ?? '',
      detailedResults: json['detailedResults'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'accuracyScore': accuracyScore,
        'fluencyScore': fluencyScore,
        'completenessScore': completenessScore,
        'prosodyScore': prosodyScore,
        'pronunciationScore': pronunciationScore,
        'recognizedText': recognizedText,
        'detailedResults': detailedResults,
      };
}

class AzurePronunciationService {
  final String _serverBaseUrl;
  final http.Client _httpClient;
  static const int _timeoutSeconds = 30;

  AzurePronunciationService({
    required String serverBaseUrl,
    http.Client? httpClient,
  })  : _serverBaseUrl = serverBaseUrl.endsWith('/')
            ? serverBaseUrl.substring(0, serverBaseUrl.length - 1)
            : serverBaseUrl,
        _httpClient = httpClient ?? http.Client();

  /// Send audio file to server for pronunciation assessment
  ///
  /// [audioData] - Raw audio bytes from recorder
  /// [referenceText] - The word/phrase being pronounced
  /// [userId] - Optional user ID for logging/tracking
  ///
  /// Returns [PronunciationScore] if successful
  /// Throws exception if server error or timeout
  Future<PronunciationScore> assessPronunciation({
    required List<int> audioData,
    required String referenceText,
    String? userId,
  }) async {
    try {
      // Build request
      final uri = Uri.parse('$_serverBaseUrl/api/pronunciation/assess');

      // Create multipart request for audio file
      final request = http.MultipartRequest('POST', uri);

      // Add audio file
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioData,
          filename: 'pronunciation.wav',
        ),
      );

      // Add reference text
      request.fields['referenceText'] = referenceText;

      // Add optional user ID
      if (userId != null) {
        request.fields['userId'] = userId;
      }

      // Send request with timeout
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(Duration(seconds: _timeoutSeconds));

      final response = await http.Response.fromStream(streamedResponse);

      // Handle response
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return PronunciationScore.fromJson(jsonData);
      } else if (response.statusCode == 408 || response.statusCode == 504) {
        throw Exception('Server timeout processing audio');
      } else if (response.statusCode == 400) {
        throw ArgumentError('Invalid reference text or audio format');
      } else {
        throw Exception(
          'Pronunciation assessment failed: ${response.statusCode} - ${response.body}',
        );
      }
    } on SocketException catch (e) {
      throw Exception('Network error: $e');
    } catch (e) {
      rethrow;
    }
  }

  /// Batch assess multiple pronunciations
  /// Useful for assessing word lists
  Future<List<PronunciationScore>> assessMultiple({
    required List<({List<int> audioData, String referenceText})> items,
    String? userId,
  }) async {
    final results = <PronunciationScore>[];

    for (final item in items) {
      try {
        final score = await assessPronunciation(
          audioData: item.audioData,
          referenceText: item.referenceText,
          userId: userId,
        );
        results.add(score);
      } catch (e) {
        // Log error but continue with next item
        print('Error assessing ${item.referenceText}: $e');
        // Could optionally add a failed score or rethrow
        rethrow;
      }
    }

    return results;
  }

  /// Check if server is reachable
  Future<bool> isServerAvailable() async {
    try {
      final uri = Uri.parse('$_serverBaseUrl/health');
      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
