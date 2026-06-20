import '../models/quiz_model.dart';

/// Stand-in for a real backend call. Swap the body of [fetchQuiz] for an
/// http call and nothing else in the app needs to change, since every
/// downstream widget already renders from [QuizModel].
class StoryService {
  static const String storyText =
      "Once upon a time, a clever little robot named Pip lost his shiny "
      "blue gear in the Whispering Woods...";

  Future<QuizModel> fetchQuiz() async {
    await Future.delayed(const Duration(milliseconds: 150));
    const json = {
      "question": "What colour was Pip the Robot's lost gear?",
      "options": ["Red", "Green", "Blue", "Yellow"],
      "answer": "Blue",
    };
    return QuizModel.fromJson(json);
  }
}
