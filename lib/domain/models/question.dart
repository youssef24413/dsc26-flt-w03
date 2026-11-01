/// One practice question chosen for a student by the Masaraat backend.
final class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.stem,
    required this.choices,
  });

  final String id;
  final String skillId;
  final String stem;
  final List<String> choices;

  /// Reads one question from the API. Unknown fields are ignored.
  ///
  /// Throws a [FormatException] for a missing or wrongly typed field, or when
  /// `choices` is not a list of 2 to 6 non-empty strings.
  factory Question.fromJson(Map<String, Object?> json) {
    final id = _nonEmptyString(json, 'id');
    final skillId = _nonEmptyString(json, 'skillId');
    final stem = _nonEmptyString(json, 'stem');

    final rawChoices = json['choices'];
    if (rawChoices is! List<Object?>) {
      throw const FormatException('choices must be a list');
    }
    if (rawChoices.length < 2 || rawChoices.length > 6) {
      throw const FormatException('choices must have 2 to 6 items');
    }
    final choices = <String>[];
    for (final choice in rawChoices) {
      if (choice is! String || choice.isEmpty) {
        throw const FormatException('every choice must be a non-empty string');
      }
      choices.add(choice);
    }

    return Question(
      id: id,
      skillId: skillId,
      stem: stem,
      choices: List<String>.unmodifiable(choices),
    );
  }

  static String _nonEmptyString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }
}
