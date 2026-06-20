/// Data-driven quiz model.
///
/// This is intentionally generic: `options` is just a List<String> of
/// arbitrary length (3, 4, 5, ...). Nothing in the UI layer assumes a
/// fixed count or fixed text, so a new JSON payload from the backend
/// renders correctly with zero code changes.
class QuizModel {
  final String question;
  final List<String> options;
  final String answer;

  const QuizModel({
    required this.question,
    required this.options,
    required this.answer,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return QuizModel(
      question: json['question'] as String? ?? '',
      options: rawOptions.map((e) => e.toString()).toList(),
      answer: json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answer': answer,
      };

  bool isCorrect(String selected) =>
      selected.trim().toLowerCase() == answer.trim().toLowerCase();
}
