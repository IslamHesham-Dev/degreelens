import 'package:degreelens/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts a GIU course code and title from its long portal label', () {
    final course = CourseSummary.fromLabel(
      'GIU-Cairo.Informatics and Computer Science - '
      'Software Engineering 5th - ICS501 Software Project I',
    );

    expect(course.code, 'ICS501');
    expect(course.title, 'Software Project I');
  });

  test('calculates an assessment ratio from an earned / maximum grade', () {
    const assessment = Assessment(
      assessment: 'Final Grade',
      element: 'Quiz',
      grade: '7 / 10',
      evaluator: 'Instructor',
    );

    expect(assessment.ratio, .7);
  });
}
