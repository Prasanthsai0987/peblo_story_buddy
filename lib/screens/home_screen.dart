import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/quiz_model.dart';
import '../providers/narration_provider.dart';
import '../providers/quiz_provider.dart';
import '../services/story_service.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/story_card.dart';
import '../widgets/quiz_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = StoryService();
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  QuizModel? _quiz;
  bool _loadingQuiz = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quiz = await _service.fetchQuiz();
    if (!mounted) return;
    setState(() {
      _quiz = quiz;
      _loadingQuiz = false;
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingQuiz || _quiz == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF1D6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      // Recreated only when the quiz JSON itself changes.
      create: (_) => QuizProvider(_quiz!),
      child: Scaffold(
        body: Stack(
          children: [
            // ---- Kid-friendly gradient backdrop ----
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF1D6), // warm cream
                    Color(0xFFFFE3EC), // soft pink
                    Color(0xFFE3F0FF), // soft sky blue
                  ],
                ),
              ),
            ),
            // ---- Floating blurred light blobs ----
            const Positioned(
              top: -60,
              left: -40,
              child: _GlowBlob(color: Color(0xFFFFC93C), size: 220),
            ),
            const Positioned(
              top: 160,
              right: -70,
              child: _GlowBlob(color: Color(0xFF6FA8FF), size: 200),
            ),
            const Positioned(
              bottom: -50,
              left: -30,
              child: _GlowBlob(color: Color(0xFF4CD964), size: 180),
            ),
            const Positioned(
              bottom: 120,
              right: -40,
              child: _GlowBlob(color: Color(0xFFFF6B6B), size: 160),
            ),
            // ---- Foreground content ----
            SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Consumer2<NarrationProvider, QuizProvider>(
                      builder: (context, narration, quizProvider, _) {
                        final mood =
                            _moodFor(narration.status, quizProvider.phase);

                        // Trigger confetti exactly once on success.
                        if (quizProvider.phase == QuizPhase.answeredCorrect &&
                            _confetti.state == ConfettiControllerState.stopped) {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) => _confetti.play());
                        }

                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              'Story Time with Pip!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2D2A4A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            BuddyAvatar(mood: mood),
                            const SizedBox(height: 20),
                            StoryCard(
                              storyText: StoryService.storyText,
                              onFinished: () => quizProvider.reveal(),
                            ),
                            const SizedBox(height: 20),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: quizProvider.phase == QuizPhase.hidden
                                  ? const SizedBox.shrink(key: ValueKey('empty'))
                                  : const QuizCard(key: ValueKey('quiz')),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirection: pi / 2,
                      maxBlastForce: 12,
                      minBlastForce: 6,
                      numberOfParticles: 24,
                      gravity: 0.25,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFFFF6B6B),
                        Color(0xFFFFC93C),
                        Color(0xFF4CD964),
                        Color(0xFF6FA8FF),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BuddyMood _moodFor(NarrationStatus narrationStatus, QuizPhase phase) {
    if (phase == QuizPhase.answeredCorrect) return BuddyMood.happy;
    if (phase == QuizPhase.answeredWrong) return BuddyMood.confused;
    if (narrationStatus == NarrationStatus.playing) return BuddyMood.listening;
    return BuddyMood.neutral;
  }
}

/// A soft, blurred circle of color used to give the background a dreamy,
/// "glass-lit" feel behind the frosted cards. Cheap: just a blurred
/// gradient circle, no images, no shaders beyond ImageFilter.blur.
class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.55),
        ),
      ),
    );
  }
}
