import 'package:flutter/material.dart';
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
      int currentListId = prefs!.getInt('currentListId${user.id}')!;
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
        backgroundColor: Colors.blueAccent[50],
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
        ),
        title: Text('Welcome to Class-$classCode'),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportCSV),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check, size: 32, color: Colors.blueAccent),

                    const SizedBox(height: 8),

                    const Text(
                      "Class Average",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "${(calculateAverage() * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WordlistSelectionScreen(),
                  ),
                ),
                child: const Text("Word Lists"),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: "Search students...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Sort By"),
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
              ),

              const SizedBox(height: 20),

              Text(
                "Students in Class $classCode",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              if (loadingStudents)
                const CircularProgressIndicator()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: getFilteredAndSortedStudents().length,
                  itemBuilder: (context, index) {
                    final student = getFilteredAndSortedStudents()[index];

                    final progress = (progressMap[student.id] ?? 0);

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(student.name),
                      isThreeLine: true,
                      subtitle: Text(
                        "${student.currentList}\nProgress: ${(progress * 100).toStringAsFixed(0)}%",
                      ),
                      trailing: SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.green,
                        ),
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
                    );
                  },
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MissedWordsScreen(uid: null, classCode: classCode),
                    ),
                  );
                },
                child: const Text("Class Overall Missed Words"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
