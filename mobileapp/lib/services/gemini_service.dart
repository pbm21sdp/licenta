import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  late final GenerativeModel _model;
  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  factory GeminiService() => _instance;

  GeminiService._internal() {
    _initializeService();
  }

  void _initializeService() {
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY must be provided via --dart-define');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
      systemInstruction: Content.system(
        'You are a helpful pet adoption assistant. You help users with questions about pet adoption, '
        'care requirements, application processes, and shelter policies. Be friendly, informative, and concise. '
        'Focus on adoption-related topics. If asked about unrelated topics, politely redirect to adoption questions.',
      ),
    );
  }

  Future<String> sendMessage(
    String message,
    List<Map<String, dynamic>> chatHistory,
  ) async {
    try {
      final chat = _model.startChat(
        history: chatHistory.map((msg) {
          return Content(msg['role'] == 'user' ? 'user' : 'model', [
            TextPart(msg['message'] as String),
          ]);
        }).toList(),
      );

      final response = await chat.sendMessage(Content.text(message));
      return response.text ??
          'I apologize, but I could not generate a response. Please try again.';
    } catch (e) {
      if (e.toString().contains('API key')) {
        return 'API configuration error. Please contact support.';
      } else if (e.toString().contains('SAFETY')) {
        return 'I cannot respond to that request. Please ask about pet adoption topics.';
      }
      return 'I encountered an error. Please try again in a moment.';
    }
  }

  List<String> getQuickSuggestions() {
    return [
      'What is the adoption process?',
      'What are the adoption fees?',
      'What documents do I need?',
      'How do I prepare my home?',
      'What about pet care requirements?',
    ];
  }
}
