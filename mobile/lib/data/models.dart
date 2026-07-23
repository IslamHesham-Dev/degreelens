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

  double? get numericGpa {
    final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(numeric);
    if (match == null) return null;
    return double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }

  GradeBand? get mappedGrade => GiuGradeScale.forGpa(numericGpa);

  String get displayGrade =>
      grade.isNotEmpty ? grade : mappedGrade?.letter ?? '';

  String get gpaWithGrade {
    if (numeric.isEmpty) return displayGrade;
    return displayGrade.isEmpty ? numeric : '$numeric ($displayGrade)';
  }
}

class GradeBand {
  final double minimum;
  final double maximum;
  final String letter;
  final String gpaRange;

  const GradeBand({
    required this.minimum,
    required this.maximum,
    required this.letter,
    required this.gpaRange,
  });

  String get percentageRange =>
      '${minimum.toStringAsFixed(minimum == minimum.roundToDouble() ? 0 : 1)}'
      '–'
      '${maximum.toStringAsFixed(maximum == maximum.roundToDouble() ? 0 : 1)}';
}

abstract final class GiuGradeScale {
  static const bands = <GradeBand>[
    GradeBand(
      minimum: 94,
      maximum: 100,
      letter: 'A+',
      gpaRange: '0.70–0.99',
    ),
    GradeBand(
      minimum: 90,
      maximum: 93.9,
      letter: 'A',
      gpaRange: '1.00–1.29',
    ),
    GradeBand(
      minimum: 86,
      maximum: 89.9,
      letter: 'A-',
      gpaRange: '1.30–1.69',
    ),
    GradeBand(
      minimum: 82,
      maximum: 85.9,
      letter: 'B+',
      gpaRange: '1.70–1.99',
    ),
    GradeBand(
      minimum: 78,
      maximum: 81.9,
      letter: 'B',
      gpaRange: '2.00–2.29',
    ),
    GradeBand(
      minimum: 74,
      maximum: 77.9,
      letter: 'B-',
      gpaRange: '2.30–2.69',
    ),
    GradeBand(
      minimum: 70,
      maximum: 73.9,
      letter: 'C+',
      gpaRange: '2.70–2.99',
    ),
    GradeBand(
      minimum: 65,
      maximum: 69.9,
      letter: 'C',
      gpaRange: '3.00–3.29',
    ),
    GradeBand(
      minimum: 60,
      maximum: 64.9,
      letter: 'C-',
      gpaRange: '3.30–3.69',
    ),
    GradeBand(
      minimum: 55,
      maximum: 59.9,
      letter: 'D+',
      gpaRange: '3.70–3.99',
    ),
    GradeBand(
      minimum: 50,
      maximum: 54.9,
      letter: 'D',
      gpaRange: '4.00–4.99',
    ),
    GradeBand(
      minimum: 0,
      maximum: 49.9,
      letter: 'F',
      gpaRange: '5.00–6.00',
    ),
  ];

  static GradeBand? forPercentage(double? percentage) {
    if (percentage == null || percentage < 0 || percentage > 100) return null;
    for (final band in bands) {
      if (percentage >= band.minimum) {
        return band;
      }
    }
    return null;
  }

  static GradeBand? forGpa(double? gpa) {
    if (gpa == null || gpa < .7 || gpa > 6) return null;
    for (final band in bands) {
      final bounds = band.gpaRange.split('–');
      final minimum = double.tryParse(bounds.first);
      final maximum = double.tryParse(bounds.last);
      if (minimum != null &&
          maximum != null &&
          gpa >= minimum &&
          gpa <= maximum) {
        return band;
      }
    }
    return null;
  }
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

  GradeBand? get cumulativeGrade {
    final match = RegExp(r'-?\d+(?:[.,]\d+)?').firstMatch(cumulativeGpa ?? '');
    if (match == null) return null;
    final value = double.tryParse(match.group(0)!.replaceAll(',', '.'));
    return GiuGradeScale.forGpa(value);
  }

  String get cumulativeGpaWithGrade {
    final value = cumulativeGpa;
    if (value == null || value.isEmpty) return 'Not displayed';
    final letter = cumulativeGrade?.letter;
    return letter == null ? value : '$value ($letter)';
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
