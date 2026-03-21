import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/witch_theme.dart';
import 'screens/chat_screen.dart';

class WitchatApp extends StatelessWidget {
  const WitchatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for dark theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0c090d),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'Witchat',
      debugShowCheckedModeBanner: false,
      theme: WitchTheme.dark,
      home: const ChatScreen(),
    );
  }
}
