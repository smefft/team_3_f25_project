import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_3_f25_project/screens/login.dart';
import 'package:team_3_f25_project/screens/dashboard.dart';
import 'package:team_3_f25_project/screens/wordlist_screen.dart';
import 'package:team_3_f25_project/screens/word_practice_page.dart';
import 'package:team_3_f25_project/screens/signup.dart';
import 'services/attempts_repository.dart';
import 'models/progress_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_supabase.dart';
const supabaseUrl = 'https://gelfwoihoznpghcpfylf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlbGZ3b2lob3pucGdoY3BmeWxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTc3MTUsImV4cCI6MjA4MDM3MzcxNX0.y8yPV32YatDe5VBE-u6pzfU0SmL9l2BnlW1NpIlfgVU';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  final attemptsRepo = AttemptsRepository();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ProgressViewModel(attemptsRepo)..load(),
      child: const ReadRightApp(),
    ),
  );
}

class ReadRightApp extends StatefulWidget {
  const ReadRightApp({super.key});

  @override
  State<ReadRightApp> createState() => _ReadRightAppState();
}

class _ReadRightAppState extends State<ReadRightApp> {
  Widget _home = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('email');
      final userId = prefs.getInt('userId');
      int? currentListId = prefs.getInt('currentListId$userId');
      if (currentListId == null) {
        prefs.setInt('currentListId$userId', 1);
        currentListId = 1;
      }
      if (savedEmail != null) {
        final db = SupabaseUserDB();
        final user = await db.getUserByEmail(savedEmail);
        if (user != null) {
          setState(
            () => _home = user.role == 'teacher'
                ? const DashboardScreen()
                : ProgressScreen(listId: currentListId!),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
    setState(() => _home = const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReadRight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: false),
      home: _home,
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/wordlist_screen': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProgressScreen(listId: args['listId'] ?? 1);
        },
        '/practice': (context) => WordPracticeScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}
