import 'package:flutter/material.dart';
import 'package:team_3_f25_project/screens/signup.dart';
import 'package:team_3_f25_project/screens/wordlist_selection.dart';
import 'package:team_3_f25_project/services/list_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_3_f25_project/screens/login.dart';
import '../models/user.dart';
import 'missed_word.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../services/user_supabase.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String classCode = "";
  List<Student> students = [];
  bool loadingStudents = true;
  Map<int, double> progressMap = {};
  String searchQuery = "";
  String sortOption = "name_asc";
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _loadClassCode();
  }

  Future<void> _loadProgress() async {
    final db = SupabaseUserDB();
    Map<int, double> temp = {};

    for (var s in students) {
      double p = await db.getStudentProgress(s.id!, s.currentListId);
      temp[s.id!] = p;
    }

    setState(() {
      progressMap = temp;
    });
  }

  Future<void> _loadClassCode() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs = prefs!;
      classCode = prefs!.getString('classCode') ?? "N/A";
    });
    _loadStudents(classCode);
  }

  Future<void> _loadStudents(String code) async {
    final db = SupabaseUserDB();
    final list = await db.getStudentsByClassCode(code);
    List<Student> studentList = [];
    for (int i = 0; i < list.length; i++) {
      AppUser user = list[i];
      // TODO fix later
      int currentListId = 1;
      String currentList = await WordService.getCategory(currentListId);
      studentList.add(
        Student(
          id: user.id,
          classCode: classCode,
          email: user.email,
          name: user.name,
          password: user.password,
          role: user.role,
          currentList: currentList,
          currentListId: currentListId,
        ),
      );
    }

    setState(() {
      students = studentList;
      loadingStudents = false;
    });
    _loadProgress();
  }

  Future<void> _logout(BuildContext context) async {
    await prefs!.remove('email');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  double calculateAverage() {
    if (progressMap.isEmpty) return 0;

    double total = 0;
    for (var value in progressMap.values) {
      total += value;
    }

    return total / progressMap.length;
  }

  List<Student> getFilteredAndSortedStudents() {
    List<Student> filtered = students.where((s) {
      return s.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      double pA = progressMap[a.id] ?? 0;
      double pB = progressMap[b.id] ?? 0;

      switch (sortOption) {
        case "name_asc":
          return a.name.compareTo(b.name);
        case "name_desc":
          return b.name.compareTo(a.name);
        case "progress_desc":
          return pB.compareTo(pA);
        case "progress_asc":
          return pA.compareTo(pB); //
      }
      return 0;
    });

    return filtered;
  }

  //This function is the export function to export student progress to CSV
  //CSV include email, name, progress, and most missed word
  Future<void> _exportCSV() async {
    final db = SupabaseUserDB();

    List<List<dynamic>> rows = [
      ["Student Email", "Student Name", "Progress (%)", "Most Missed Word"],
    ];

    for (var student in students) {
      //Get student progress and most missed word
      final progress = (progressMap[student.id] ?? 0.0) * 100;
      final mostMissed = await db.getMostMissedWord(student.id!) ?? "None";

      rows.add([
        student.email,
        student.name,
        progress.toStringAsFixed(0),
        mostMissed,
      ]);
    }

    // Convert to list to csv
    String csvData = const ListToCsvConverter().convert(rows);

    // Save to device
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/class_${classCode}_student_report.csv");

    await file.writeAsString(csvData);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("CSV exported to: ${file.path}")));

    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _logout(context),
        ),
        title: Text(
          'Class $classCode',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Class Average Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.blue.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Class Average Progress",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${(calculateAverage() * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text(
                        "Word Lists",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WordlistSelectionScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text(
                        "Export CSV",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _exportCSV,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Missed Words and Add Student Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.error_outline),
                      label: const Text(
                        "Missed Words",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MissedWordsScreen(
                              uid: null,
                              classCode: classCode,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.person_add),
                      label: const Text(
                        "Add Student",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(classCode: classCode),
                          ),
                        ).then((_) {
                          setState(() {
                            _loadStudents(classCode);
                          });
                        });
                        // TODO: Implement add student functionality
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Students Section Header
              const Text(
                "Students",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  labelText: "Search students...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.blueAccent,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Sort Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Sort By",
                  prefixIcon: const Icon(Icons.sort, color: Colors.blueAccent),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
                value: sortOption,
                items: const [
                  DropdownMenuItem(
                    value: "name_asc",
                    child: Text("Name (A → Z)"),
                  ),
                  DropdownMenuItem(
                    value: "name_desc",
                    child: Text("Name (Z → A)"),
                  ),
                  DropdownMenuItem(
                    value: "progress_desc",
                    child: Text("Progress (High → Low)"),
                  ),
                  DropdownMenuItem(
                    value: "progress_asc",
                    child: Text("Progress (Low → High)"),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    sortOption = val!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Students List
              if (loadingStudents)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (getFilteredAndSortedStudents().isEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No students found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: getFilteredAndSortedStudents().length,
                  itemBuilder: (context, index) {
                    final student = getFilteredAndSortedStudents()[index];
                    final progress = progressMap[student.id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.shade100,
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              student.currentList,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.grey.shade200,
                                      color: progress >= 0.7
                                          ? Colors.green
                                          : progress >= 0.4
                                          ? Colors.orange
                                          : Colors.red,
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "${(progress * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.blueAccent,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MissedWordsScreen(
                                uid: student.id!,
                                studentName: student.name,
                                classCode: classCode,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
