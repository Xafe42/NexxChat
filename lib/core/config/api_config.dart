/// Zentrale API-Konfiguration für NexxChat.
///
/// Die Schlüssel können beim Starten der App dynamisch über `--dart-define`
/// übergeben werden, sodass keine geheimen Keys im Git-Repository landen:
///
/// ```bash
/// flutter run --dart-define=HF_TOKEN=hf_xxx --dart-define=GEMINI_API_KEY=AIza_xxx
/// ```
class ApiConfig {
  /// Hugging Face API-Token für Bild- und Textgenerierung
  static const String huggingFaceToken = String.fromEnvironment(
    'HF_TOKEN',
    defaultValue: '',
  );

  /// Google Gemini API-Key für den KI-Support und Assistenten
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}

