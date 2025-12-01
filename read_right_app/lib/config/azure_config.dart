import 'package:flutter_dotenv/flutter_dotenv.dart';

class AzureConfig {
  static String get speechApiKey => dotenv.env['AZURE_SPEECH_API_KEY'] ?? '';
  static const String region = 'eastus';
  static const String endpoint = 'https://$region.api.cognitive.microsoft.com';

  /// Assessment Settings
  /// Enable prosody assessment (stress, intonation, rhythm)
  /// Prosody analysis only works for en-US currently.
  /// Set to false if you want faster responses or don't need prosody scoring.
  /// When enabled, you get an extra "prosodyScore" in results.
  static const bool enableProsodyAssessment = true;

  /// Grading system: how scores are calculated
  /// Options:
  /// - "HundredMark" = 0-100 scale (recommended for kids, easy to understand)
  /// - "FivePoint" = 0-5 scale (academic style)
  /// We use HundredMark because it's intuitive for grades 1-3
  static const String gradingSystem = 'HundredMark';

  /// Granularity: how detailed the assessment is
  /// Options (from least to most detailed):
  /// - "FullText" = overall score only (fastest)
  /// - "Word" = word-by-word breakdown
  /// - "Phoneme" = phoneme-level analysis (slowest but most detailed)
  /// We use Phoneme for maximum detail - helps identify exactly which sounds
  /// the student is struggling with (like "th" vs "f")
  static const String granularity = 'Phoneme';

  /// Language code for assessment
  /// Must match the speech being assessed. For grades 1-3 English: en-US
  /// Other options: en-GB, en-AU, es-ES, fr-FR, etc.
  static const String language = 'en-US';

  /// Phoneme alphabet format
  /// Options:
  /// - "IPA" = International Phonetic Alphabet (standard linguistics format)
  /// - "SAPI" = Microsoft Speech API format (Windows-specific)
  /// IPA is universal and more widely recognized
  static const String phonemeAlphabet = 'IPA';

  /// Number of alternative phoneme candidates to return
  /// When a student mispronounces, Azure can suggest what they ACTUALLY said.
  /// 5 candidates gives good coverage without overwhelming with options.
  /// Example: Student says "fink" instead of "think"
  /// - Expected: /θ/ (th sound)
  /// - Candidates: [/f/, /s/, /t/, /θ/, /v/] with confidence scores
  static const int nBestPhonemeCount = 5;

  /// Network Settings
  /// Request timeout in seconds
  static const int timeoutSeconds = 30;

  /// Validation

  /// Check if API key has been configured
  /// Returns true if the placeholder text has been replaced
  static bool get isConfigured =>
      speechApiKey.isNotEmpty &&
      !speechApiKey.contains('YOUR_AZURE') &&
      !speechApiKey.contains('REPLACE');

  /// Get a helpful error message if not configured
  static String get configurationError => '''
Azure Speech API Key is not configured.
Please set AZURE_SPEECH_API_KEY in your .env file.
''';
}
