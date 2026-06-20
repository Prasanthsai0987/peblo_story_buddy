import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/narration_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PebloStoryBuddyApp());
}

class PebloStoryBuddyApp extends StatelessWidget {
  const PebloStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NarrationProvider(),
      child: MaterialApp(
        title: 'Peblo Story Buddy',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorSchemeSeed: const Color(0xFFFF6B6B),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
