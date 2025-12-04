import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:team_3_f25_project/models/wordlist.dart';
import 'package:team_3_f25_project/services/list_service.dart';
import 'package:team_3_f25_project/widgets/custom_app_bar.dart';
import 'package:team_3_f25_project/widgets/record_button.dart';
import 'package:team_3_f25_project/widgets/word_card.dart';
import 'package:team_3_f25_project/models/attempt.dart';
import 'package:team_3_f25_project/screens/instant_feedback_screen.dart';
import 'package:team_3_f25_project/screens/celebration_screen.dart';
import 'package:record/record.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../services/user_supabase.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_3_f25_project/data/homophones.dart';
final db = SupabaseUserDB();
class WordPracticeScreen extends StatefulWidget {
  WordPracticeScreen({super.key});

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  // variables to keep track of progress
  SharedPreferences? prefs;
  int? userId;
  int? currentListId;
  List<WordList>? completeWordList;
  List<String>? wordsToPractice;
  int nextIndex = 0;

  String get currentWord {
    if (wordsToPractice == null || wordsToPractice!.isEmpty) return '';
    return wordsToPractice![nextIndex];
  }

  WordList get currentWordObject {
    return completeWordList!.firstWhere((word) => word.word == currentWord);
  }

  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // variables for recording / listening
  final _speechToText = SpeechToText();
  final _recorder = AudioRecorder();
  int correctlyPronounced = 0;
  String recordingPath = "";
  bool _speechEnabled = false;
  bool _isListening = false;

  // timer variables
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  static const Duration kMax = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _loadUserAndWords();
    _initSpeech();
  }

  Future<void> _loadUserAndWords() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      // gets shared preferences to load user data and see user progress
      prefs = await SharedPreferences.getInstance();
      userId = prefs!.getInt('userId');

      // get list of words to practice
      currentListId = prefs!.getInt('currentListId$userId');
      completeWordList = await WordService.getWords(currentListId!);

      // initialize list of only word strings
      wordsToPractice = completeWordList!.map((entry) => entry.word).toList();

      // find and remove words user has gotten correct in the past
      Set<String> correctWords = await db.getAllCorrectWords(userId!);
      wordsToPractice!.removeWhere((word) => correctWords.contains(word));

      // used for progress tracking
      correctlyPronounced = completeWordList!.length - wordsToPractice!.length;

      // async management
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _nextWord(bool correct) {
    setState(() {
      if (correct) {
        nextIndex = nextIndex % wordsToPractice!.length;
      } else {
        nextIndex = nextIndex + 1 % wordsToPractice!.length;
      }
    });
  }

  void _removeWordFromList() {
    if (wordsToPractice!.isNotEmpty) {
      wordsToPractice!.remove(currentWord);
    }
  }

  void _finishList() {
    int nextListId = currentListId! + 1 % 5;
    prefs!.setInt('currentListId$userId', nextListId);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CelebrationScreen(nextListId: nextListId),
      ),
    );
  }

  void _startListening() async {
    // start speech to text
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_US', // Specify the locale
      listenFor: kMax, // How long to listen
      pauseFor: const Duration(seconds: 2), // How long to wait for pause
    );

    // start recording
    final config = RecordConfig(
      encoder: AudioEncoder.aacLc, // -> .m4a
      sampleRate: 44100,
      bitRate: 128000,
    );
    recordingPath = await _nextPath();
    await _recorder.start(config, path: recordingPath);

    setState(() {
      _isListening = true;
      _elapsed = Duration.zero;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      final next = _elapsed + const Duration(milliseconds: 200);
      if (next >= kMax) {
        _stopListening();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TimeOutScreen()),
        );
      } else {
        setState(() {
          _elapsed = next;
        });
      }
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    await _recorder.stop();
    _timer?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  bool _isCorrect(String recognizedWord) {
    // if speech to text already matched, no need for further checking
    if (recognizedWord.toLowerCase() == currentWord.toLowerCase()) {
      return true;
    }

    // if not, check for homophones
    return Homophones().isHomophone(recognizedWord, currentWord);
  }

  void _onSpeechResult(
    SpeechRecognitionResult? result, {
    bool timedOut = false,
  }) {
    if (timedOut) {
      print("Timed out");
      _stopListening();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              InstantFeedback(success: false, wordObject: currentWordObject),
        ),
      );
    } else if (result!.finalResult) {
      _stopListening();
      bool correct = _isCorrect(result.recognizedWords);

      userId ??= -1;
      // add attempt to database
      db.insertAttempt(
        Attempt(
          uid: userId!,
          wordText: currentWord,
          listId: currentListId,
          score: correct ? 1 : 0,
          createdAt: DateTime.now(),
          feedback: correct ? "Great job" : "Try again",
          recordingPath: recordingPath,
          duration: _elapsed,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              InstantFeedback(success: correct, wordObject: currentWordObject),
        ),
      ).then((_) {
        if (correct) {
          correctlyPronounced++;
          _removeWordFromList();
        }
        if (correctlyPronounced == completeWordList!.length ||
            wordsToPractice!.isEmpty) {
          _finishList();
        } else {
          _nextWord(correct);
        }
      });
    }
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  Future<String> _nextPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/readright_$currentWord$ts.m4a';
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueGrey),
      );
    }

    // Error state
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadUserAndWords,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state - no words to practice
    if (wordsToPractice == null || wordsToPractice!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'No words to practice!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('You\'ve mastered all words in this list!'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _finishList,
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        spacing: 10.0,
        children: [
          LinearProgressIndicator(
            value:
                correctlyPronounced /
                (correctlyPronounced + wordsToPractice!.length),
            color: Colors.green,
            backgroundColor: Colors.grey.shade300,
          ),
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: Text(
              'Progress: $correctlyPronounced / ${completeWordList!.length}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          WordCard(
            wordText: currentWord,
            patternLabel: "Pattern label",
            sampleSentence: "Sample sentence",
          ),
          RecordButton(
            isRecording: _isListening,
            onTap: _speechEnabled
                ? () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  }
                : null,
          ),
          const SizedBox(height: 15.0),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: 250,
              // 250 is also the width of the record button
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(15.0)),
                border: Border.all(color: Colors.orange, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.stop_rounded, size: 50, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: customAppBar(context: context, title: "Word Practice Screen"),
      body: _buildBody(),
    );
  }
}
