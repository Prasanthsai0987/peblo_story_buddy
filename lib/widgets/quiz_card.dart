import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import 'shake_widget.dart';

/// Fully data-driven: builds one button per entry in `quiz.options`.
/// Works unchanged for 3, 4, 5+ options, any wording, any answer text.
class QuizCard extends StatelessWidget {
  const QuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final quiz = quizProvider.quiz;
    final phase = quizProvider.phase;

    if (phase == QuizPhase.hidden) return const SizedBox.shrink();

    final isCorrect = phase == QuizPhase.answeredCorrect;
    final isWrong = phase == QuizPhase.answeredWrong;

    if (isWrong) {
      HapticFeedback.mediumImpact();
    }
    if (isCorrect) {
      HapticFeedback.lightImpact();
    }

    return ShakeWidget(
      trigger: quizProvider.shakeTick,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isWrong
                    ? const Color(0xFFFF6B6B)
                    : isCorrect
                        ? const Color(0xFF4CD964)
                        : Colors.white.withOpacity(0.6),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quiz.question,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D2A4A),
                  ),
                ),
                const SizedBox(height: 14),
                // ---- the data-driven part ----
                ...List.generate(quiz.options.length, (i) {
                  final option = quiz.options[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionButton(option: option),
                  );
                }),
                if (isCorrect) ...[
                  const SizedBox(height: 6),
                  const _SuccessBanner(),
                ] else if (isWrong) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Oops! Not quite — give it another try! 💪',
                    style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.option});
  final String option;

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final phase = quizProvider.phase;
    final selected = quizProvider.selected;
    final isSelected = selected == option;
    final solved = phase == QuizPhase.answeredCorrect;

    Color bg = Colors.white.withOpacity(0.65);
    Color fg = const Color(0xFF2D2A4A);
    if (solved && quizProvider.quiz.isCorrect(option)) {
      bg = const Color(0xFF4CD964);
      fg = Colors.white;
    } else if (isSelected && phase == QuizPhase.answeredWrong) {
      bg = const Color(0xFFFFE1E1);
      fg = const Color(0xFFD9534F);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: solved
            ? null
            : () => context.read<QuizProvider>().selectOption(option),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          option,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC93C)),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Yay! You got it right! 🎉',
            style: TextStyle(
              color: Color(0xFF2D9C5A),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
