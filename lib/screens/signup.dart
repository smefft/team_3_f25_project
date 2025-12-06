import 'package:flutter/material.dart';
import 'package:team_3_f25_project/services/list_service.dart';
import '../models/user.dart';
import 'package:uuid/uuid.dart';
import '../services/user_supabase.dart';

class SignupScreen extends StatefulWidget {
  final String? classCode;
  const SignupScreen({super.key, this.classCode});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  TextEditingController? _classCodeController;

  @override
  void initState() {
    super.initState();
    setState(() {
      if (widget.classCode != null) {
        _classCodeController = TextEditingController.fromValue(
          TextEditingValue(text: widget.classCode!),
        );
      } else {
        _classCodeController = TextEditingController();
      }
    });
  }

  String _role = 'student';
  String? _error;

  String generateClassCode() {
    var uuid = Uuid().v4();
    return uuid.substring(0, 6).toUpperCase();
  }

  void _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    String classCode;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = "All fields are required.");
      return;
    }

    final db = SupabaseUserDB();

    final existing = await db.getUserByEmail(email);
    if (existing != null) {
      setState(() => _error = "Email already registered.");
      return;
    }

    if (password.length < 8) {
      setState(() => _error = "Password must be at least 8 characters.");
      return;
    }

    if (_role == 'teacher') {
      if (!email.contains('@')) {
        setState(() => _error = "Teachers must enter a valid email.");
        return;
      }
      classCode = generateClassCode();
    } else {
      classCode = _classCodeController!.text.trim();
      if (classCode.isEmpty) {
        setState(() => _error = "Students must enter a class code.");
        return;
      }
      if (!await db.classCodeExists(classCode)) {
        setState(() => _error = "Invalid class code.");
        return;
      }
    }

    final newUser = AppUser(
      name: name,
      email: email,
      password: password,
      role: _role,
      classCode: classCode,
    );

    final id = await db.insertUser(newUser);
    if (id <= 0) {
      setState(() => _error = "Signup failed.");
      return;
    }

    if (_role == "student") {
      int firstListId = await WordService.getTopPriority();
      int id = await db.addUserListId(email, firstListId);
      if (id <= 0) setState(() => _error = "Adding user list ID failed");
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const Icon(Icons.menu_book, size: 100, color: Colors.blueAccent),

              const SizedBox(height: 20),

              const Text(
                "Create ReadRight Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),

              const SizedBox(height: 40),

              // ROLE DROPDOWN
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  labelText: "Role",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text("Student")),
                  DropdownMenuItem(value: 'teacher', child: Text("Teacher")),
                ],
                onChanged: (value) => setState(() => _role = value!),
              ),

              const SizedBox(height: 20),

              // NAME
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: _role == "student" ? "Student ID" : "Email",
                  prefixIcon: Icon(
                    _role == "teacher" ? Icons.email : Icons.badge,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              if (_role == 'student')
                TextField(
                  controller: _classCodeController,
                  decoration: InputDecoration(
                    labelText: "Class Code",
                    prefixIcon: const Icon(Icons.class_),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
