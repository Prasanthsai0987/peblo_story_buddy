import 'package:flutter/foundation.dart';
import '../models/quiz_model.dart';

enum QuizPhase { hidden, revealed, answeredWrong, answeredCorrect }

class QuizProvider extends ChangeNotifier {
  QuizProvider(this.quiz);

  final QuizModel quiz;

  QuizPhase _phase = QuizPhase.hidden;
  QuizPhase get phase => _phase;

  String? _selected;
  String? get selected => _selected;

  int _wrongAttempts = 0;
  int get wrongAttempts => _wrongAttempts;

  /// Bumped every time a wrong answer is picked, purely so the UI's
  /// shake animation can listen for "trigger again" even if the same
  /// wrong option is tapped twice in a row.
  int _shakeTick = 0;
  int get shakeTick => _shakeTick;

  void reveal() {
    if (_phase == QuizPhase.hidden) {
      _phase = QuizPhase.revealed;
      notifyListeners();
    }
  }

  void selectOption(String option) {
    if (_phase == QuizPhase.answeredCorrect) return; // already solved

    _selected = option;
    if (quiz.isCorrect(option)) {
      _phase = QuizPhase.answeredCorrect;
    } else {
      _wrongAttempts++;
      _shakeTick++;
      _phase = QuizPhase.answeredWrong;
    }
    notifyListeners();
  }

  void resetForRetry() {
    _phase = QuizPhase.revealed;
    notifyListeners();
  }
}
