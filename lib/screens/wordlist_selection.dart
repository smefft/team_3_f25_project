import 'package:flutter/material.dart';
import 'package:team_3_f25_project/screens/wordlist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_3_f25_project/screens/login.dart';
import 'package:team_3_f25_project/services/list_service.dart';

// --- Color Definitions ---
const Color kPrimaryColor = Colors.blueAccent;
const Color kLightBackgroundColor = Color(
  0xFFE3F2FD,
); // Equivalent to Colors.blueAccent[50] or a very light blue
const Color kEncouragementColor =
    Colors.lightBlue; // Used for instructions container

class WordlistSelectionScreen extends StatefulWidget {
  const WordlistSelectionScreen({super.key});

  @override
  State<WordlistSelectionScreen> createState() => _WordlistSelectionState();
}

class _WordlistSelectionState extends State<WordlistSelectionScreen> {
  List<Map<String, dynamic>> wordlists = [];

  // --- Utility Functions (Omitted for brevity, kept same logic) ---

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _loadWordLists() async {
    // NOTE: Assuming WordService is functional and Word objects have a 'word' property
    final listIds = await WordService.getListIds();
    final lists = <Map<String, dynamic>>[];

    for (var id in listIds) {
      final category = await WordService.getCategory(id);
      final words = await WordService.getWords(id);
      // NOTE: Using a safe check for word priority
      final priority =
          words.isNotEmpty &&
              words.first != null &&
              words.first.priority != null
          ? words.first.priority
          : 100;
      lists.add({
        'id': id,
        'category': category,
        'words': words,
        'priority': priority,
      });
    }

    // Sort by priority
    lists.sort((a, b) => a['priority'].compareTo(b['priority']));
    if (mounted) {
      setState(() => wordlists = lists);
    }
  }

  Future<void> _updatePriorities() async {
    for (int i = 0; i < wordlists.length; i++) {
      final listId = wordlists[i]['id'];
      await WordService.updateListPriority(listId, i + 1);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWordLists();
  }

  // --- The Refactored Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Classroom Word Lists",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: wordlists.isEmpty
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // **Priority Instructions**
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kEncouragementColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kEncouragementColor, width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swipe_up, color: kPrimaryColor),
                        SizedBox(width: 8),
                        Expanded(
                          // Use Expanded to prevent text overflow
                          child: Text(
                            "Drag and drop lists to set the study order (Top = highest priority)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onReorder: (oldIndex, newIndex) async {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = wordlists.removeAt(oldIndex);
                        wordlists.insert(newIndex, item);
                      });
                      await _updatePriorities();
                    },
                    children: [
                      for (int i = 0; i < wordlists.length; i++)
                        _buildWordlistCard(wordlists[i], i + 1),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Custom Widget for a single list item
  Widget _buildWordlistCard(Map<String, dynamic> list, int priority) {
    Color cardColor = priority == 1
        ? Colors.white
        : Colors.white; // Simple white card

    return Card(
      key: ValueKey(list['id']),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: priority == 1
            ? const BorderSide(color: kPrimaryColor, width: 2)
            : BorderSide.none, // Highlight top priority
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // **Priority Number**
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$priority',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        // **List Title and Preview**
        title: Row(
          children: [
            Flexible(
              // Use Flexible to ensure the category title doesn't overflow
              child: Text(
                list['category'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5), // Darker blue for text
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            // **Fixing the Overflow Here** by limiting words and ensuring proper truncation
            'Words: ${list['words'].take(5).map((w) => w.word).join(', ')}' +
                (list['words'].length > 5 ? '...' : ''),
            overflow:
                TextOverflow.ellipsis, // Ensures text does not cause overflow
            maxLines: 1,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        // **Drag Handle**
        trailing: Icon(
          Icons.reorder_rounded,
          color: kPrimaryColor.withOpacity(0.7),
          size: 30,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgressScreen(listId: list['id']),
            ),
          );
        },
      ),
    );
  }
}
