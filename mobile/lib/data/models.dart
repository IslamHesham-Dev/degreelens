class SessionInfo {
  final String currentSeason;
  final String advisoryYear;
  final int expiresInSeconds;

  const SessionInfo({
    required this.currentSeason,
    required this.advisoryYear,
    required this.expiresInSeconds,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
        currentSeason: json['current_season'] as String? ?? 'Winter 2024',
        advisoryYear: json['advisory_year'] as String? ?? '2024-2025',
        expiresInSeconds: json['expires_in_seconds'] as int? ?? 0,
      );
}

class AdvisoryContext {
  final String currentSeason;
  final String transcriptYear;
  final List<String> dataSources;
  final List<String> excludedSources;

  const AdvisoryContext({
    required this.currentSeason,
    required this.transcriptYear,
    required this.dataSources,
    required this.excludedSources,
  });

  factory AdvisoryContext.fromJson(Map<String, dynamic> json) =>
      AdvisoryContext(
        currentSeason:
            json['simulated_current_season'] as String? ?? 'Winter 2024',
        transcriptYear: json['transcript_year'] as String? ?? '2024-2025',
        dataSources:
            List<String>.from(json['data_sources'] as List? ?? const []),
        excludedSources:
            List<String>.from(json['excluded_sources'] as List? ?? const []),
      );
}

class CourseSummary {
  final String label;
  final String code;
  final String title;
  final String track;

  const CourseSummary({
    required this.label,
    required this.code,
    required this.title,
    required this.track,
  });

  factory CourseSummary.fromLabel(String label) {
    final match = RegExp(r'\b[A-Z]{2,6}\d{3}\b').firstMatch(label);
    final code = match?.group(0) ?? 'COURSE';
    final afterCode = match == null
        ? label
        : label
            .substring(match.end)
            .trim()
            .replaceFirst(RegExp(r'^[-–]\s*'), '');
    final beforeCode =
        match == null ? '' : label.substring(0, match.start).trim();
    final track = beforeCode
        .split(' - ')
        .where((part) => part.trim().isNotEmpty)
        .lastOrNull;
    return CourseSummary(
      label: label,
      code: code,
      title: afterCode.isEmpty ? label : afterCode,
      track: track ?? 'GIU',
    );
  }
}

class Assessment {
  final String assessment;
  final String element;
  final String grade;
  final String evaluator;

  const Assessment({
    required this.assessment,
    required this.element,
    required this.grade,
    required this.evaluator,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        assessment: json['assessment'] as String? ?? '',
        element: json['element'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        evaluator: json['evaluator'] as String? ?? '',
      );

  double? get ratio {
    final match =
        RegExp(r'(-?\d+(?:\.\d+)?)\s*/\s*(-?\d+(?:\.\d+)?)').firstMatch(grade);
    if (match == null) return null;
    final earned = double.tryParse(match.group(1)!);
    final maximum = double.tryParse(match.group(2)!);
    if (earned == null || maximum == null || maximum == 0) return null;
    return (earned / maximum).clamp(0, 1);
  }
}

class CourseGrades {
  final String season;
  final String course;
  final List<Assessment> assessments;
  final Map<String, String> midtermResults;

  const CourseGrades({
    required this.season,
    required this.course,
    required this.assessments,
    required this.midtermResults,
  });

  factory CourseGrades.fromJson(Map<String, dynamic> json) => CourseGrades(
        season: json['season'] as String? ?? '',
        course: json['course'] as String? ?? '',
        assessments: (json['assessments'] as List? ?? const [])
            .map((item) =>
                Assessment.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        midtermResults: Map<String, String>.from(
          (json['midterm_results'] as Map? ?? const {})
              .map((key, value) => MapEntry('$key', '$value')),
        ),
      );

  double? get averageRatio {
    final values =
        assessments.map((item) => item.ratio).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

class TranscriptCourse {
  final String semester;
  final String course;
  final String grade;
  final String numeric;
  final String hours;
  final String group;

  const TranscriptCourse({
    required this.semester,
    required this.course,
    required this.grade,
    required this.numeric,
    required this.hours,
    required this.group,
  });

  factory TranscriptCourse.fromJson(Map<String, dynamic> json) =>
      TranscriptCourse(
        semester: json['semester'] as String? ?? '',
        course: json['course'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        numeric: json['numeric'] as String? ?? '',
        hours: json['hours'] as String? ?? '',
        group: json['group'] as String? ?? '',
      );
}

class Transcript {
  final String year;
  final String? cumulativeGpa;
  final List<TranscriptCourse> courses;

  const Transcript({
    required this.year,
    required this.cumulativeGpa,
    required this.courses,
  });

  factory Transcript.fromJson(Map<String, dynamic> json) => Transcript(
        year: json['year'] as String? ?? '',
        cumulativeGpa: json['cumulative_gpa'] as String?,
        courses: (json['courses'] as List? ?? const [])
            .map((item) => TranscriptCourse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
      );

  Map<String, List<TranscriptCourse>> get bySemester {
    final grouped = <String, List<TranscriptCourse>>{};
    for (final course in courses) {
      grouped.putIfAbsent(course.semester, () => []).add(course);
    }
    return grouped;
  }
}

class ToolActivity {
  final String name;
  final String status;

  const ToolActivity({required this.name, required this.status});

  factory ToolActivity.fromJson(Map<String, dynamic> json) => ToolActivity(
        name: json['name'] as String? ?? 'portal_tool',
        status: json['status'] as String? ?? 'completed',
      );
}

class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime createdAt;
  final List<String> sources;
  final List<ToolActivity> tools;

  const ChatMessage({
    required this.isUser,
    required this.text,
    required this.createdAt,
    this.sources = const [],
    this.tools = const [],
  });
}

extension _LastOrNull<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
