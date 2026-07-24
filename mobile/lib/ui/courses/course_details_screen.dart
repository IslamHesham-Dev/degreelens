import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseSummary course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadCourseGrades(widget.course);
    });
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final grades = academic.grades[widget.course.code];
    final loading = academic.loadingCourses.contains(widget.course.code);
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  GradientPill(
                    label: academic.context?.currentSeason ?? 'Winter 2024',
                    icon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                widget.course.code,
                style: const TextStyle(
                  color: LensColors.indigo,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.course.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(widget.course.track,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              if (loading && grades == null)
                const LensCard(
                  child:
                      LensLoading(label: 'Reading detailed grades from GIU…'),
                )
              else if (academic.error != null && grades == null)
                LensError(
                  message: academic.error!,
                  onRetry: () => academic.loadCourseGrades(
                    widget.course,
                    force: true,
                  ),
                )
              else if (grades != null) ...[
                _CoursePulse(grades: grades),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Assessment detail',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${grades.assessments.length} items',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (grades.assessments.isEmpty)
                  const LensCard(
                    child: Text(
                      'No detailed assessment rows were displayed by the portal.',
                    ),
                  )
                else
                  ...grades.assessments.map(
                    (assessment) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _AssessmentCard(assessment: assessment),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    context.read<AdvisorRepository>().send(
                          'Analyze ${widget.course.code}. Explain the grades, identify the weakest assessment, and make a practical improvement plan.',
                        );
                    context.go('/advisor');
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Ask CareerLoop about this course'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoursePulse extends StatelessWidget {
  final CourseGrades grades;

  const _CoursePulse({required this.grades});

  @override
  Widget build(BuildContext context) {
    final ratio = grades.averageRatio;
    final percentage = ratio == null ? '—' : '${(ratio * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LensColors.ink, Color(0xFF29336D)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio ?? 0,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: .09),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(LensColors.aqua),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    percentage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assessment pulse',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  ratio == null
                      ? 'Scores are shown exactly as GIU returned them.'
                      : ratio < .65
                          ? 'This course has room for a focused recovery plan.'
                          : 'Use the detailed rows to protect your strongest work.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final Assessment assessment;

  const _AssessmentCard({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final ratio = assessment.ratio;
    final color = ratio == null
        ? LensColors.indigo
        : ratio < .65
            ? LensColors.rose
            : ratio < .8
                ? LensColors.amber
                : LensColors.aqua;
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  assessment.element.isEmpty
                      ? assessment.assessment
                      : assessment.element,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                assessment.grade,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (assessment.assessment.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              assessment.assessment,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12),
            ),
          ],
          if (ratio != null) ...[
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: .11),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
