import 'package:chatbot_tutor/dialoguepage.dart';
import 'package:chatbot_tutor/home.dart';
import 'package:chatbot_tutor/lmvocabspage.dart';
import 'package:chatbot_tutor/lmverbpage.dart.dart';
import 'package:chatbot_tutor/openendedpage.dart';
import 'package:chatbot_tutor/provider/messagesprovider.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

void main() {
  //flutter run --no-sound-null-safety

  runApp(
    ChangeNotifierProvider(
      create: (context) => MessagesNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the FirstScreen widget.
        '/': (context) => const Homepage(),
        '/firstmode': (context) => OpenEndedPage(),
        '/secondmode': (context) => VerbModePage(),
        '/thirdmode': (context) => VocabModePage(),
        '/fourthmode': (context) => DialoguePage(),
      },
    );
  }
}
