import 'package:http/http.dart' as http;
import 'azure_config.dart';

Future<void> checkAzureApiConnection() async {
  final endpoint = AzureConfig.endpoint;
  final apiKey = AzureConfig.speechApiKey;
  if (apiKey.isEmpty) {
    print('[Azure API Check] API key missing.');
    return;
  }
  try {
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Ocp-Apim-Subscription-Key': apiKey,
      },
    );
    print('[Azure API Check] Connected: ${response.statusCode == 404 || response.statusCode == 200}');
  } catch (e) {
    print('[Azure API Check] Connected: false');
    print('[Azure API Check] Error: $e');
  }
}
