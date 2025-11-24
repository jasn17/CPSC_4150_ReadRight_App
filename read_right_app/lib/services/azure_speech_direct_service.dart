import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/azure_config.dart';

/// Flow:
/// 1. Takes audio bytes (WAV format) from speech_service.dart
/// 2. Sends to Azure Speech API with pronunciation config
/// 3. Receives detailed assessment (phoneme-level analysis)
/// 4. Returns clean PronunciationAssessmentResult
class AzureSpeechDirectService {
  final http.Client _httpClient;

  AzureSpeechDirectService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Assess pronunciation by sending audio directly to Azure
  /// [audioFilePath] - Path to WAV file
  /// [referenceText] - The word/phrase being assessed
  /// [userId] - Optional user ID for tracking
  /// Returns detailed pronunciation scores from Azure
  Future<PronunciationAssessmentResult> assessPronunciation({
    required String audioFilePath,
    required String referenceText,
    String? userId,
  }) async {
    // Validate inputs
    if (referenceText.trim().isEmpty) {
      throw ArgumentError('referenceText cannot be empty');
    }

    if (!AzureConfig.isConfigured) {
      throw Exception(AzureConfig.configurationError);
    }

    final audioFile = File(audioFilePath);
    if (!await audioFile.exists()) {
      throw ArgumentError('Audio file not found: $audioFilePath');
    }

    try {
      // Read audio bytes
      final audioBytes = await audioFile.readAsBytes();

      // Build pronunciation assessment config JSON
      // This tells Azure what to analyze and how to score it
      final pronunciationConfig = {
        'referenceText': referenceText,
        'gradingSystem': AzureConfig.gradingSystem,
        'granularity': AzureConfig.granularity,
        'dimension':
            'Comprehensive', // Analyzes accuracy, fluency, completeness, prosody
        'enableMiscue':
            false, // Don't penalize insertions/omissions for single words
      };

      // Add prosody if enabled (only works for en-US)
      if (AzureConfig.enableProsodyAssessment &&
          AzureConfig.language == 'en-US') {
        pronunciationConfig['enableProsodyAssessment'] = true;
      }

      // Add phoneme settings if using phoneme granularity
      if (AzureConfig.granularity == 'Phoneme') {
        pronunciationConfig['phonemeAlphabet'] = AzureConfig.phonemeAlphabet;
        pronunciationConfig['nBestPhonemeCount'] =
            AzureConfig.nBestPhonemeCount;
      }

      // Build Azure Speech API URL
      // Format: https://eastus.api.cognitive.microsoft.com/speechtotext/v3.0/recognize
      final uri = Uri.parse(
        '${AzureConfig.endpoint}/speechtotext/v3.0/recognize',
      ).replace(queryParameters: {
        'language': AzureConfig.language,
        'format':
            'detailed', // Get full JSON response with NBest, phonemes, etc.
      });

      // Build request headers
      final headers = {
        'Ocp-Apim-Subscription-Key': AzureConfig.speechApiKey, // Azure API key
        'Content-Type':
            'audio/wav; codecs=audio/pcm; samplerate=16000', // WAV format
        'Accept': 'application/json',
        'Pronunciation-Assessment':
            jsonEncode(pronunciationConfig), // Assessment config
      };

      print('[Azure] Sending ${audioBytes.length} bytes to ${uri.toString()}');
      print('[Azure] Reference text: "$referenceText"');

      // Send POST request with audio bytes
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: audioBytes,
          )
          .timeout(Duration(seconds: AzureConfig.timeoutSeconds));

      // Handle response status codes
      if (response.statusCode == 200) {
        print('[Azure] ✅ Success! Parsing response...');
        return _parseAzureResponse(response.body, referenceText);
      } else if (response.statusCode == 401) {
        throw AzureAuthException(
          'Invalid Azure API key. Check your .env file and verify the key in Azure Portal.',
        );
      } else if (response.statusCode == 429) {
        throw AzureRateLimitException(
          'Too many requests to Azure. Wait a moment and try again.',
        );
      } else if (response.statusCode == 400) {
        throw ArgumentError(
          'Azure rejected the request. Check audio format (must be WAV, 16kHz) and reference text. '
          'Response: ${response.body}',
        );
      } else {
        throw Exception(
          'Azure API error [${response.statusCode}]: ${response.body}',
        );
      }
    } on SocketException catch (e) {
      throw Exception('Network error - check internet connection: $e');
    } on TimeoutException catch (e) {
      throw TimeoutException(
          'Azure did not respond within ${AzureConfig.timeoutSeconds}s: $e');
    } catch (e) {
      rethrow;
    }
  }

  /// Parse Azure's complex JSON response into our clean result object
  /// Azure's response structure:
  /// {
  ///   "RecognitionStatus": "Success",
  ///   "DisplayText": "hello",
  ///   "NBest": [
  ///     {
  ///       "Confidence": 0.95,
  ///       "Display": "hello",
  ///       "PronunciationAssessment": {
  ///         "AccuracyScore": 95.0,
  ///         "FluencyScore": 90.0,
  ///         "CompletenessScore": 100.0,
  ///         "ProsodyScore": 88.0,
  ///         "PronScore": 92.5
  ///       },
  ///       "Words": [...]
  ///     }
  ///   ]
  /// }
  PronunciationAssessmentResult _parseAzureResponse(
      String body, String referenceText) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Check recognition status
      final status = json['RecognitionStatus'] as String?;
      if (status != 'Success') {
        throw Exception('Azure recognition failed: $status');
      }

      // Get the best result from NBest array (Azure returns multiple interpretations)
      final nBest = json['NBest'] as List?;
      if (nBest == null || nBest.isEmpty) {
        throw Exception('No recognition results in Azure response');
      }

      final bestResult = nBest.first as Map<String, dynamic>;
      final assessment =
          bestResult['PronunciationAssessment'] as Map<String, dynamic>?;

      if (assessment == null) {
        throw Exception('No pronunciation assessment in Azure response');
      }

      // Extract scores (Azure returns them as doubles)
      final accuracyScore =
          (assessment['AccuracyScore'] as num?)?.toDouble() ?? 0.0;
      final fluencyScore =
          (assessment['FluencyScore'] as num?)?.toDouble() ?? 0.0;
      final completenessScore =
          (assessment['CompletenessScore'] as num?)?.toDouble() ?? 0.0;
      final prosodyScore =
          (assessment['ProsodyScore'] as num?)?.toDouble() ?? 0.0;
      final pronunciationScore =
          (assessment['PronScore'] as num?)?.toDouble() ?? 0.0;

      // Get recognized text (what Azure heard)
      final recognizedText = (bestResult['Display'] as String?) ??
          (json['DisplayText'] as String?) ??
          '';

      // Parse word-level details if available
      final words = _parseWords(bestResult['Words'] as List?);

      print(
          '[Azure] 📊 Scores - Accuracy: $accuracyScore, Fluency: $fluencyScore, '
          'Completeness: $completenessScore, Prosody: $prosodyScore, Overall: $pronunciationScore');
      print(
          '[Azure] 🎤 Recognized: "$recognizedText" (expected: "$referenceText")');

      return PronunciationAssessmentResult(
        accuracyScore: accuracyScore,
        fluencyScore: fluencyScore,
        completenessScore: completenessScore,
        prosodyScore: prosodyScore,
        pronunciationScore: pronunciationScore,
        recognizedText: recognizedText,
        words: words,
        rawResponse: json, // Keep full JSON for debugging
      );
    } catch (e) {
      print('[Azure] ❌ Error parsing response: $e');
      print('[Azure] Response body: $body');
      throw Exception('Failed to parse Azure response: $e');
    }
  }

  /// Parse word-level assessment details from Azure response
  /// This function extracts each word's accuracy and phoneme breakdown
  List<WordAssessment> _parseWords(List? wordsJson) {
    if (wordsJson == null || wordsJson.isEmpty) return [];

    return wordsJson.map((wordJson) {
      final word = wordJson as Map<String, dynamic>;
      final assessment =
          word['PronunciationAssessment'] as Map<String, dynamic>?;

      return WordAssessment(
        word: word['Word'] as String? ?? '',
        accuracyScore:
            (assessment?['AccuracyScore'] as num?)?.toDouble() ?? 0.0,
        errorType: assessment?['ErrorType'] as String? ?? 'None',
        syllables: _parseSyllables(word['Syllables'] as List?),
        phonemes: _parsePhonemes(word['Phonemes'] as List?),
      );
    }).toList();
  }

  /// Parse syllable-level details (en-US only)
  /// This function extracts each syllable's accuracy score
  List<SyllableAssessment>? _parseSyllables(List? syllablesJson) {
    if (syllablesJson == null || syllablesJson.isEmpty) return null;

    return syllablesJson.map((syllableJson) {
      final syllable = syllableJson as Map<String, dynamic>;
      final assessment =
          syllable['PronunciationAssessment'] as Map<String, dynamic>?;

      return SyllableAssessment(
        syllable: syllable['Syllable'] as String? ?? '',
        accuracyScore:
            (assessment?['AccuracyScore'] as num?)?.toDouble() ?? 0.0,
        offset: syllable['Offset'] as int? ?? 0,
        duration: syllable['Duration'] as int? ?? 0,
      );
    }).toList();
  }

  /// Parse phoneme-level details with alternative candidates
  /// This function extracts each phoneme's accuracy and NBest alternatives
  List<PhonemeAssessment>? _parsePhonemes(List? phonemesJson) {
    if (phonemesJson == null || phonemesJson.isEmpty) return null;

    return phonemesJson.map((phonemeJson) {
      final phoneme = phonemeJson as Map<String, dynamic>;
      final assessment =
          phoneme['PronunciationAssessment'] as Map<String, dynamic>?;

      // Parse alternative phoneme candidates (what else it could be)
      final nBestJson = assessment?['NBestPhonemes'] as List?;
      final nBest = nBestJson?.map((candidate) {
            final c = candidate as Map<String, dynamic>;
            return PhonemeCandidate(
              phoneme: c['Phoneme'] as String? ?? '',
              score: (c['Score'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList() ??
          [];

      return PhonemeAssessment(
        phoneme: phoneme['Phoneme'] as String? ?? '',
        accuracyScore:
            (assessment?['AccuracyScore'] as num?)?.toDouble() ?? 0.0,
        nBestPhonemes: nBest,
        offset: phoneme['Offset'] as int? ?? 0,
        duration: phoneme['Duration'] as int? ?? 0,
      );
    }).toList();
  }

  /// Check if Azure Speech API is reachable (communcation between client and Azure is stable)
  /// Note: Azure doesn't have a dedicated health endpoint,
  /// so we check if the API responds to requests
  Future<bool> isAzureAvailable() async {
    if (!AzureConfig.isConfigured) return false;

    try {
      // Simple connectivity check - just ping the endpoint
      final uri = Uri.parse(AzureConfig.endpoint);
      final response =
          await _httpClient.get(uri).timeout(const Duration(seconds: 5));

      // Any response means Azure is reachable (even 404 is fine)
      return response.statusCode < 500;
    } catch (e) {
      print('[Azure] Availability check failed: $e');
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Complete pronunciation assessment result from Azure
class PronunciationAssessmentResult {
  /// Accuracy of pronunciation (0-100)
  final double accuracyScore;

  /// How smooth and natural the speech was (0-100)
  final double fluencyScore;

  /// Percentage of reference text that was spoken (0-100)
  final double completenessScore;

  /// How natural the stress/intonation was (0-100, en-US only)
  final double prosodyScore;

  /// Overall weighted score (0-100)
  final double pronunciationScore;

  /// What Azure recognized (what the student actually said with Azure recognizing)
  final String recognizedText;

  /// Word-by-word breakdown
  final List<WordAssessment> words;

  /// Raw JSON from Azure (for debugging/logging)
  final Map<String, dynamic>? rawResponse;

  PronunciationAssessmentResult({
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.prosodyScore,
    required this.pronunciationScore,
    required this.recognizedText,
    required this.words,
    this.rawResponse,
  });

  /// Convert to simple 0-100 integer score (compatible with existing code)
  int get simpleScore => pronunciationScore.toInt();

  /// Pass/fail threshold (80% is standard for pronunciation)
  bool get isPassed => pronunciationScore >= 80;

  /// Convert to JSON for storage in Firebase/SQLite
  Map<String, dynamic> toJson() => {
        'accuracyScore': accuracyScore,
        'fluencyScore': fluencyScore,
        'completenessScore': completenessScore,
        'prosodyScore': prosodyScore,
        'pronunciationScore': pronunciationScore,
        'recognizedText': recognizedText,
        'words': words.map((w) => w.toJson()).toList(),
        'rawResponse': rawResponse,
      };

  @override
  String toString() => 'PronunciationScore: $pronunciationScore '
      '(Accuracy: $accuracyScore, Fluency: $fluencyScore, '
      'Completeness: $completenessScore, Prosody: $prosodyScore)';
}
