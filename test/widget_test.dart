// Basic smoke test for the Peblo Story Buddy app.
//
// It just verifies the app builds and the core UI elements are present
// after the initial frame (the quiz JSON loads, the buddy renders, and
// the "Read Me a Story" button shows up).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peblo_story_buddy/main.dart';

void main() {
  testWidgets('App loads and shows the Read Me a Story button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PebloStoryBuddyApp());

    // Initial frame shows a loading spinner while the mock "backend"
    // quiz fetch resolves.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the async quiz fetch (StoryService.fetchQuiz) complete.
    await tester.pumpAndSettle();

    // Title and CTA button should now be visible.
    expect(find.text('Story Time with Pip!'), findsOneWidget);
    expect(find.text('Read Me a Story'), findsOneWidget);
  });
}