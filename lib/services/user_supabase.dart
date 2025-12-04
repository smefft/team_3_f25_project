import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/attempt.dart';
import 'list_service.dart';

class SupabaseUserDB {
  final supabase = Supabase.instance.client;


  Future<int> insertUser(AppUser user) async {
    final response = await supabase
        .from('users')
        .insert({
      'name': user.name,
      'email': user.email,
      'password': user.password,
      'role': user.role,
      'classCode': user.classCode,
    })
        .select()
        .single();

    return response['id'] as int;
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<AppUser?> login(String email, String password) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('email', email)
        .eq('password', password)
        .maybeSingle();

    if (data == null) return null;
    return AppUser.fromMap(data);
  }

  Future<bool> classCodeExists(String code) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('role', 'teacher')
        .eq('classCode', code);

    return data.isNotEmpty;
  }

  Future<List<AppUser>> getStudentsByClassCode(String classCode) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('role', 'student')
        .eq('classCode', classCode);

    return data.map<AppUser>((row) => AppUser.fromMap(row)).toList();
  }

  Future<AppUser?> getUser(int uid) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;
    return AppUser.fromMap(data);
  }


  Future<int> insertAttempt(Attempt attempt) async {
    final response = await supabase
        .from('attempts')
        .insert(attempt.toMap())
        .select()
        .single();

    return response['id'] as int;
  }

  Future<Set<String>> getAllCorrectWords(int uid) async {
    final data = await supabase
        .from('attempts')
        .select()
        .eq('uid', uid)
        .eq('score', 1);

    return data.map<String>((a) => a['wordText'] as String).toSet();
  }

  Future<double> getStudentProgress(int uid, int currentListId) async {
    final allWordsInList = await WordService.getWords(currentListId);
    final listLength = allWordsInList.length;

    if (listLength == 0) return 0.0;

    final attempts = await supabase
        .from('attempts')
        .select()
        .eq('uid', uid)
        .eq('score', 1)
        .eq('listId', currentListId);

    final mastered = attempts.map<String>((a) => a['wordText'] as String).toSet();

    return mastered.length / listLength;
  }

  Future<List<Map<String, dynamic>>> getMissedWordsByStudent(int uid) async {
    final result = await supabase.rpc('get_missed_words_by_student', params: {'user_id': uid});
    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> getClassMissedWords(String classCode) async {
    final result = await supabase.rpc('get_class_missed_words', params: {'class_code': classCode});
    return List<Map<String, dynamic>>.from(result);
  }

  Future<String?> getMostMissedWord(int uid) async {
    final result = await supabase
        .rpc('get_most_missed_word', params: {'user_id': uid});

    if (result.isEmpty) return "No Words Missed";
    return result.first['wordText'] as String?;
  }




  Future<void> clearAllUsers() async {
    await supabase.from('users').delete();
    print('All users deleted from Supabase!');
  }
}