import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';
import 'session_storage.dart';

class AuthRepository extends ChangeNotifier {
  final ApiClient api;
  final SessionStorage storage;

  bool initialized = false;
  bool isAuthenticated = false;
  bool isBusy = false;
  String? error;
  SessionInfo? session;

  AuthRepository({required this.api, required this.storage});

  Future<void> restoreSession() async {
    final token = await storage.readToken();
    if (token != null) {
      api.accessToken = token;
      try {
        session = SessionInfo.fromJson(await api.get('/v1/auth/session'));
        isAuthenticated = true;
      } on ApiException {
        await storage.clearToken();
        api.accessToken = null;
      }
    }
    initialized = true;
    notifyListeners();
  }

  Future<bool> signIn(String username, String password) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post(
        '/v1/auth/login',
        authenticated: false,
        body: {'username': username.trim(), 'password': password},
      );
      final token = json['access_token'] as String;
      api.accessToken = token;
      await storage.saveToken(token);
      session = SessionInfo.fromJson(json);
      isAuthenticated = true;
      return true;
    } on ApiException catch (exception) {
      error = exception.message;
      return false;
    } catch (_) {
      error =
          'Cannot reach DegreeLens. Check the backend address and try again.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await api.post('/v1/auth/logout');
    } catch (_) {
      // A local logout must still succeed if the server session already expired.
    }
    await storage.clearToken();
    api.accessToken = null;
    isAuthenticated = false;
    session = null;
    notifyListeners();
  }
}

class AcademicRepository extends ChangeNotifier {
  final ApiClient api;

  AdvisoryContext? context;
  List<CourseSummary> courses = const [];
  Transcript? transcript;
  final Map<String, CourseGrades> grades = {};
  bool loadingDashboard = false;
  final Set<String> loadingCourses = {};
  String? error;

  AcademicRepository({required this.api});

  Future<void> loadDashboard({bool force = false}) async {
    if (loadingDashboard) return;
    if (!force && context != null && courses.isNotEmpty && transcript != null) {
      return;
    }
    loadingDashboard = true;
    error = null;
    notifyListeners();
    try {
      context = AdvisoryContext.fromJson(
        await api.get('/v1/academic/context'),
      );
      final courseJson = await api.get('/v1/academic/courses');
      courses = List<String>.from(courseJson['courses'] as List? ?? const [])
          .map(CourseSummary.fromLabel)
          .toList();
      transcript = Transcript.fromJson(
        await api.get('/v1/academic/transcript'),
      );
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Academic data could not be loaded.';
    } finally {
      loadingDashboard = false;
      notifyListeners();
    }
  }

  Future<CourseGrades?> loadCourseGrades(
    CourseSummary course, {
    bool force = false,
  }) async {
    if (!force && grades.containsKey(course.code)) {
      return grades[course.code];
    }
    loadingCourses.add(course.code);
    error = null;
    notifyListeners();
    try {
      final result = CourseGrades.fromJson(
        await api.get(
          '/v1/academic/course-grades',
          query: {'course': course.code},
        ),
      );
      grades[course.code] = result;
      return result;
    } on ApiException catch (exception) {
      error = exception.message;
      return null;
    } catch (_) {
      error = 'Grades for ${course.code} could not be loaded.';
      return null;
    } finally {
      loadingCourses.remove(course.code);
      notifyListeners();
    }
  }

  Future<void> clearPortalCache() async {
    await api.post('/v1/academic/cache/clear');
    context = null;
    courses = const [];
    transcript = null;
    grades.clear();
    notifyListeners();
  }

  void clearLocal() {
    context = null;
    courses = const [];
    transcript = null;
    grades.clear();
    error = null;
    notifyListeners();
  }
}

class AdvisorRepository extends ChangeNotifier {
  final ApiClient api;

  final List<ChatMessage> messages = [];
  bool isSending = false;
  String? error;

  AdvisorRepository({required this.api});

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isSending) return;
    messages.add(
      ChatMessage(
        isUser: true,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    isSending = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post('/v1/chat', body: {'message': trimmed});
      messages.add(
        ChatMessage(
          isUser: false,
          text: json['answer'] as String? ?? 'No response was returned.',
          createdAt: DateTime.now(),
          sources: List<String>.from(json['sources'] as List? ?? const []),
          tools: (json['tools'] as List? ?? const [])
              .map((item) =>
                  ToolActivity.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList(),
        ),
      );
    } on ApiException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'The advisor could not be reached.';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> reset() async {
    try {
      await api.post('/v1/chat/reset');
    } finally {
      messages.clear();
      error = null;
      notifyListeners();
    }
  }
}
