import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// All the real-world states narration can be in.
/// Keeping this explicit (instead of a couple of booleans) avoids
/// impossible/ambiguous UI states like "loading AND error at once".
enum NarrationStatus { idle, loading, playing, finished, error }

class NarrationProvider extends ChangeNotifier {
  NarrationProvider({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _init();
  }

  final FlutterTts _tts;

  NarrationStatus _status = NarrationStatus.idle;
  NarrationStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _disposed = false;

  Future<void> _init() async {
    // Tuned for a clear, friendly, kid-appropriate pace.
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.15);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      _setStatus(NarrationStatus.playing);
    });

    _tts.setCompletionHandler(() {
      _setStatus(NarrationStatus.finished);
    });

    _tts.setCancelHandler(() {
      _setStatus(NarrationStatus.idle);
    });

    _tts.setErrorHandler((msg) {
      _errorMessage = 'We couldn\'t read the story right now. '
          'Please check your sound or try again!';
      _setStatus(NarrationStatus.error);
    });
  }

  Future<void> readStory(String text) async {
    if (_status == NarrationStatus.loading ||
        _status == NarrationStatus.playing) {
      return; // ignore double taps while busy
    }
    _errorMessage = null;
    _setStatus(NarrationStatus.loading);

    try {
      // A short, deliberate delay represents the "preparing audio" step
      // (e.g. fetching a remote TTS clip). It also guarantees the
      // loading state is visible even on very fast devices/engines.
      await Future.delayed(const Duration(milliseconds: 350));

      final result = await _tts.speak(text).timeout(
        const Duration(seconds: 8),
        onTimeout: () => 0,
      );

      if (result != 1) {
        _errorMessage = 'No network or audio engine available. '
            'Tap retry to try again.';
        _setStatus(NarrationStatus.error);
      }
    } catch (_) {
      _errorMessage = 'Something went wrong while preparing the story.';
      _setStatus(NarrationStatus.error);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _setStatus(NarrationStatus.idle);
  }

  void reset() {
    _setStatus(NarrationStatus.idle);
  }

  void _setStatus(NarrationStatus s) {
    if (_disposed) return;
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tts.stop();
    super.dispose();
  }
}
