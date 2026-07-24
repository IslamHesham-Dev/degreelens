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

  Future<bool> signIn(
    String username,
    String password,
    int enrollmentYear,
  ) async {
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      final json = await api.post(
        '/v1/auth/login',
        authenticated: false,
        body: {
          'username': username.trim(),
          'password': password,
          'enrollment_year': enrollmentYear,
        },
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
          'Cannot reach CareerLoop. Check the backend address and try again.';
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
  List<String> seasons = const [];
  List<String> transcriptYears = const [];
  String? selectedTranscriptYear;
  List<CourseSummary> courses = const [];
  Transcript? transcript;
  final Map<String, CourseGrades> grades = {};
  bool loadingDashboard = false;
  bool loadingTranscript = false;
  bool updatingAdvisorySemester = false;
  final Set<String> loadingCourses = {};
  String? error;

  AcademicRepository({required this.api});

  Future<void> loadDashboard({bool force = false}) async {
    if (loadingDashboard) return;
    if (!force &&
        context != null &&
        seasons.isNotEmpty &&
        transcriptYears.isNotEmpty &&
        courses.isNotEmpty &&
        transcript != null) {
      return;
    }
    loadingDashboard = true;
    error = null;
    notifyListeners();
    try {
      context = AdvisoryContext.fromJson(
        await api.get('/v1/academic/context'),
      );
      final seasonJson = await api.get('/v1/academic/seasons');
      seasons = List<String>.from(
        seasonJson['seasons'] as List? ?? const [],
      );
      final yearJson = await api.get('/v1/academic/transcript-years');
      transcriptYears = List<String>.from(
        yearJson['years'] as List? ?? const [],
      );
      selectedTranscriptYear ??= context!.transcriptYear;
      if (!transcriptYears.contains(selectedTranscriptYear) &&
          transcriptYears.isNotEmpty) {
        selectedTranscriptYear = transcriptYears.first;
      }
      final courseJson = await api.get(
        '/v1/academic/courses',
        query: {'season': context!.currentSeason},
      );
      courses = List<String>.from(courseJson['courses'] as List? ?? const [])
          .map(CourseSummary.fromLabel)
          .toList();
      transcript = Transcript.fromJson(
        await api.get(
          '/v1/academic/transcript',
          query: {'year': selectedTranscriptYear},
        ),
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

  Future<bool> selectAdvisorySemester(String season) async {
    if (updatingAdvisorySemester) return false;
    if (context?.currentSeason == season) return true;
    var contextChanged = false;
    updatingAdvisorySemester = true;
    error = null;
    notifyListeners();
    try {
      context = AdvisoryContext.fromJson(
        await api.post(
          '/v1/academic/advisory-semester',
          body: {'current_season': season},
        ),
      );
      contextChanged = true;
      courses = const [];
      grades.clear();
      final courseJson = await api.get(
        '/v1/academic/courses',
        query: {'season': context!.currentSeason},
      );
      courses = List<String>.from(courseJson['courses'] as List? ?? const [])
          .map(CourseSummary.fromLabel)
          .toList();
      return true;
    } on ApiException catch (exception) {
      if (exception.statusCode == 404 || exception.statusCode == 405) {
        error = 'The deployed backend is an older version. Redeploy the '
            'CareerLoop API, then try changing the semester again.';
      } else {
        error = exception.message;
      }
      return contextChanged;
    } catch (_) {
      error = contextChanged
          ? 'The semester changed, but its courses could not be loaded yet.'
          : 'The advisory semester could not be changed.';
      return contextChanged;
    } finally {
      updatingAdvisorySemester = false;
      notifyListeners();
    }
  }

  Future<bool> loadTranscriptYear(String year) async {
    if (loadingTranscript) return false;
    if (transcript?.year == year) {
      selectedTranscriptYear = year;
      notifyListeners();
      return true;
    }
    final previousYear = selectedTranscriptYear;
    loadingTranscript = true;
    selectedTranscriptYear = year;
    error = null;
    notifyListeners();
    try {
      transcript = Transcript.fromJson(
        await api.get(
          '/v1/academic/transcript',
          query: {'year': year},
        ),
      );
      selectedTranscriptYear = transcript!.year;
      return true;
    } on ApiException catch (exception) {
      selectedTranscriptYear = previousYear;
      error = exception.message;
      return false;
    } catch (_) {
      selectedTranscriptYear = previousYear;
      error = 'Transcript year $year could not be loaded.';
      return false;
    } finally {
      loadingTranscript = false;
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
    seasons = const [];
    transcriptYears = const [];
    selectedTranscriptYear = null;
    courses = const [];
    transcript = null;
    grades.clear();
    notifyListeners();
  }

  void clearLocal() {
    context = null;
    seasons = const [];
    transcriptYears = const [];
    selectedTranscriptYear = null;
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

  void clearLocal() {
    messages.clear();
    error = null;
    notifyListeners();
  }
}
