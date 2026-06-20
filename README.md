# Peblo AI Story Buddy (Flutter)

A single-screen, kid-friendly mobile app: a buddy character reads a story
snippet aloud, then a JSON-driven quiz appears, with shake/haptic feedback
on wrong answers and confetti on success.

## Why Flutter

Chosen over native Swift because Peblo's stated primary audience is
**mid-range Android devices**, and the brief explicitly asks to optimize for
that segment. Flutter compiles to native ARM code (no JS bridge), gives full
control over the widget tree for predictable 60fps animations, and ships a
single codebase that could later extend to iOS without a rewrite — useful
for a startup iterating fast across both platforms.

## Project structure

```
lib/
  models/quiz_model.dart        # JSON <-> QuizModel, no UI-layer assumptions
  providers/narration_provider.dart  # TTS state machine (ChangeNotifier)
  providers/quiz_provider.dart       # Quiz state machine (ChangeNotifier)
  services/story_service.dart        # Mock "backend" call returning quiz JSON
  widgets/story_card.dart       # Story text + Read Me a Story button + states
  widgets/quiz_card.dart        # Data-driven quiz renderer
  widgets/shake_widget.dart     # Reusable shake animation
  widgets/buddy_avatar.dart     # CustomPainter buddy (no image assets => lighter app)
  screens/home_screen.dart      # Composition root + confetti
```

State management: **Provider**, with two narrowly-scoped `ChangeNotifier`s
(`NarrationProvider`, `QuizProvider`) instead of one big store, so a TTS
state change doesn't rebuild quiz widgets and vice versa.

## Audio -> quiz transition

`NarrationProvider` exposes an explicit `NarrationStatus` enum
(`idle / loading / playing / finished / error`) rather than booleans, so the
UI can never be in an ambiguous state (e.g. "loading and error" at once).
`StoryCard` watches this enum; when it flips to `finished`, it calls
`onFinished()` exactly once via `addPostFrameCallback` (avoids calling
`setState`/`notifyListeners` mid-build). `HomeScreen` wires that callback to
`QuizProvider.reveal()`, which flips `QuizPhase` from `hidden` to `revealed`.
An `AnimatedSwitcher` with a fade + slide transition handles the actual
reveal animation, so the quiz "smoothly" appears rather than popping in.

## Data-driven quiz rendering

`QuizCard` never references option text or count directly — it does
`List.generate(quiz.options.length, ...)` and builds one `_OptionButton`
per entry. Correctness is checked via `QuizModel.isCorrect()`, a
case-insensitive string compare against `answer`. Dropping in a JSON with 3
or 5 options, or completely different wording, requires no code change —
only `StoryService.fetchQuiz()` (the mock backend call) needs to point at
the new payload.

## Caching approach

Currently there's no remote audio, so there's nothing to cache on disk —
`flutter_tts` synthesizes on-device. If we integrated a remote TTS API
(e.g. ElevenLabs) per the bonus suggestion, the approach would be:
- Hash the story text to a cache key, store the resulting audio file under
  the app's cache directory (`path_provider`'s `getTemporaryDirectory()`),
  and check that cache before making a network call.
- Cap total cache size (e.g. LRU eviction past ~20MB) since target devices
  have ~3GB RAM and limited storage headroom.
- Pre-warm the cache for the single fixed story snippet at first launch
  (or ship it bundled as an asset) so the very first read doesn't require
  network at all.

## Audio loading & failure states

`readStory()` immediately sets `loading`, then calls `flutter_tts.speak()`
wrapped in a `timeout` and a `try/catch`. Three explicit outcomes:
- Engine returns success (`1`) → handlers flip status to `playing`, then
  `finished` on completion.
- Engine returns failure, times out, or throws → status becomes `error`
  with a kid-friendly message and a **Retry** button. The app never hangs:
  worst case is the 8s timeout resolving to the error state.
- Double taps while `loading`/`playing` are ignored so a child mashing the
  button can't desync the state machine.

## Performance profiling

What I'd measure with Flutter DevTools on a representative mid-range
device: the Performance/Timeline view during (a) the shake animation and
(b) the confetti burst, looking specifically at frame build/raster times
around 16ms.

Changes made with that budget in mind, before reaching for a profiler:
- `BuddyAvatar` is a single `CustomPainter` instead of an image asset or
  Lottie file — no image decoding cost, no extra package weight.
- `ShakeWidget` uses one `AnimationController` + `AnimatedBuilder` with a
  `Transform.translate`, which only repaints the shaken subtree, not the
  whole screen.
- `_OptionButton` and `QuizCard` use `context.watch` scoped to the
  `QuizProvider` only, so narration state changes don't trigger quiz
  rebuilds (verified by keeping each `ChangeNotifier` single-purpose).
- Confetti is capped at 24 particles and `shouldLoop: false`, and only
  plays once (guarded by `ConfettiControllerState.stopped`) instead of
  re-triggering on every rebuild.

*(For an actual submission, this section should be backed by a real
before/after DevTools frame-timing screenshot — flagging that this version
was authored without a connected physical/emulated device to profile on.)*

## Staying lightweight on mid-range Android

- No bundled image/Lottie assets for the buddy — vector-drawn at runtime.
- Native on-device TTS (no extra audio decoding pipeline, no large model
  downloads).
- Minimal dependency footprint: `provider`, `flutter_tts`, `confetti` — all
  small, no heavy state-management or animation frameworks.
- Single-screen app, no route stack / nested navigators to keep in memory.

## AI usage & judgment

Used AI assistance to scaffold the provider/widget structure and the shake
animation's `TweenSequence` curve. One suggestion I rejected: the initial
draft used a single monolithic `AppState` ChangeNotifier holding both
narration and quiz state. I split it into `NarrationProvider` and
`QuizProvider` instead, since a shared notifier means *any* narration tick
(even just status polling) would rebuild quiz option buttons — wasteful on
a 3GB-RAM device and contrary to the brief's "avoid unnecessary widget
rebuilds" requirement.

What didn't work initially: relying solely on `flutter_tts`'s completion
handler to drive the quiz reveal caused a rebuild-during-build exception
when the handler fired synchronously on some platforms. Resolved by
deferring the reveal call through `WidgetsBinding.instance.addPostFrameCallback`.

## Running

```bash
flutter pub get
flutter run
```
