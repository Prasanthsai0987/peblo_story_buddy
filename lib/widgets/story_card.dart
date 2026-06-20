import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/narration_provider.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.storyText, required this.onFinished});

  final String storyText;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final narration = context.watch<NarrationProvider>();

    // Fire the callback exactly once when narration completes.
    if (narration.status == NarrationStatus.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onFinished());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.4),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                storyText,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.5,
                  color: Color(0xFF3A3760),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              _ActionArea(narration: narration, storyText: storyText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({required this.narration, required this.storyText});
  final NarrationProvider narration;
  final String storyText;

  @override
  Widget build(BuildContext context) {
    switch (narration.status) {
      case NarrationStatus.loading:
        return const Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: Color(0xFFFF6B6B)),
            ),
            SizedBox(width: 12),
            Text('Getting the story ready...',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6A6790))),
          ],
        );

      case NarrationStatus.playing:
        return Row(
          children: [
            const _PlayingPulse(),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Pip is telling the story...',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6A6790))),
            ),
            TextButton(
              onPressed: () => context.read<NarrationProvider>().stop(),
              child: const Text('Stop'),
            ),
          ],
        );

      case NarrationStatus.error:
        return Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6B6B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                narration.errorMessage ?? 'Something went wrong.',
                style: const TextStyle(color: Color(0xFFD9534F), fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => context.read<NarrationProvider>().readStory(storyText),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        );

      case NarrationStatus.idle:
      case NarrationStatus.finished:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.read<NarrationProvider>().readStory(storyText),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Read Me a Story',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC93C),
              foregroundColor: const Color(0xFF2D2A4A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
          ),
        );
    }
  }
}

/// Tiny pulsing dot — cheap (single opacity tween) so it doesn't cost
/// frame budget on low-end devices.
class _PlayingPulse extends StatefulWidget {
  const _PlayingPulse();
  @override
  State<_PlayingPulse> createState() => _PlayingPulseState();
}

class _PlayingPulseState extends State<_PlayingPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: const CircleAvatar(radius: 6, backgroundColor: Color(0xFFFF6B6B)),
    );
  }
}
