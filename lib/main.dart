import 'package:flutter/material.dart';
import 'package:page/auth/authentication_gate.dart';
import 'package:page/theme/theme_data.dart';
import 'package:page/theme/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: 'https://hilkusrmkszlkttwgpso.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpbGt1c3Jta3N6bGt0dHdncHNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA1NjI0OTksImV4cCI6MjA1NjEzODQ5OX0.T9s-UiT8-FDVBD6Oy5l0icSzbD5Dmyu1rlexWgMbNaU',
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        // Provide ThemeProvider with initial ThemeData
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(ThemeModes().lightMode),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diary App',
      theme: ThemeModes().lightMode,
      darkTheme: ThemeModes().darkMode,
      themeMode: themeProvider.themeMode,
      home: const AuthenticationGate(),
      routes: {'/auth': (context) => const AuthenticationGate()},
    );
  }
}
