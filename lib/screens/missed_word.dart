import 'package:flutter/material.dart';
import '../services/user_supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_3_f25_project/screens/login.dart';
import 'package:audioplayers/audioplayers.dart';

class MissedWordsScreen extends StatefulWidget {
  final int? uid;
  final String classCode;
  final String? studentName;

  const MissedWordsScreen({
    super.key,
    this.uid,
    required this.classCode,
    this.studentName,
  });

  @override
  State<MissedWordsScreen> createState() => _MissedWordsScreenState();
}

class _MissedWordsScreenState extends State<MissedWordsScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = SupabaseUserDB();
    final future = widget.uid != null
        ? db.getMissedWordsByStudent(widget.uid!)
        : db.getClassMissedWords(widget.classCode);

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(
          widget.uid != null
              ? "${widget.studentName} Missed Words"
              : "Class Missed Words",
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent[50],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final missedWords = snapshot.data!;
          if (missedWords.isEmpty) {
            return Center(
              child: Text(
                widget.uid != null
                    ? "No missed words! ${widget.studentName} is doing a great job!"
                    : "No missed words for the class! Everyone is doing a great job!",
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            return ListView.builder(
              itemCount: missedWords.length,
              itemBuilder: (context, index) {
                final word = missedWords[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final player = AudioPlayer();
                          final path = word['lastRecording'];

                          if (path == null || path.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "No recording data available for the word",
                                ),
                              ),
                            );
                            return;
                          }
                          try {
                            await player.play(DeviceFileSource(path));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error Playing Audio: $e"),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: widget.uid != null
                                        ? Row(
                                            spacing: 20.0,
                                            children: [
                                              Icon(
                                                Icons.play_circle,
                                                size: 35,
                                                color: Colors.blueAccent,
                                              ),
                                              Text(
                                                word['wordText'],
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Text(
                                            word['wordText'],
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Attempts: ${word['attempts']}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
