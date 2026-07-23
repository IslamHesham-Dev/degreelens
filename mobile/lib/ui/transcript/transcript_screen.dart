import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class TranscriptScreen extends StatefulWidget {
  const TranscriptScreen({super.key});

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final transcript = academic.transcript;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
        children: [
          const PageHeading(
            eyebrow: 'Academic record',
            title: 'Transcript',
            subtitle:
                'Select an academic year to inspect its courses and results.',
          ),
          const SizedBox(height: 18),
          _TranscriptYearPicker(academic: academic),
          if (academic.loadingTranscript) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (academic.error != null && transcript != null) ...[
            const SizedBox(height: 12),
            Text(
              academic.error!,
              style: const TextStyle(
                color: LensColors.rose,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 22),
          if (academic.loadingDashboard && transcript == null)
            const LensLoading(label: 'Loading transcript year…')
          else if (academic.error != null && transcript == null)
            LensError(
              message: academic.error!,
              onRetry: () => academic.loadDashboard(force: true),
            )
          else if (transcript != null) ...[
            _GpaHero(transcript: transcript),
            const SizedBox(height: 14),
            const _GradeScaleCard(),
            const SizedBox(height: 28),
            ...transcript.bySemester.entries.map(
              (entry) => _SemesterSection(
                semester: entry.key,
                courses: entry.value,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TranscriptYearPicker extends StatelessWidget {
  final AcademicRepository academic;

  const _TranscriptYearPicker({required this.academic});

  @override
  Widget build(BuildContext context) {
    final current = academic.selectedTranscriptYear ??
        academic.transcript?.year ??
        academic.context?.transcriptYear;
    final years = <String>{
      if (current != null) current,
      ...academic.transcriptYears,
    }.toList();

    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Academic year',
        prefixIcon: Icon(Icons.calendar_today_outlined),
      ),
      items: years
          .map(
            (year) => DropdownMenuItem(
              value: year,
              child: Text(year),
            ),
          )
          .toList(),
      onChanged: academic.loadingTranscript
          ? null
          : (year) {
              if (year != null) academic.loadTranscriptYear(year);
            },
    );
  }
}

class _GradeScaleCard extends StatelessWidget {
  const _GradeScaleCard();

  @override
  Widget build(BuildContext context) {
    return LensCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(
          Icons.rule_rounded,
          color: LensColors.indigo,
        ),
        title: const Text(
          'Grading scale',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: const Text(
          'Percentage → letter grade → GPA band',
          style: TextStyle(fontSize: 11.5),
        ),
        children: GiuGradeScale.bands
            .map(
              (band) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 7, 20, 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 76,
                      child: Text(
                        '${band.percentageRange}%',
                        style: const TextStyle(
                          color: LensColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        band.letter,
                        style: const TextStyle(
                          color: LensColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'GPA ${band.gpaRange}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: LensColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GpaHero extends StatelessWidget {
  final Transcript transcript;

  const _GpaHero({required this.transcript});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.indigo, LensColors.violet],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: LensColors.indigo.withValues(alpha: .25),
            blurRadius: 34,
            offset: const Offset(0, 17),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CUMULATIVE GPA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .62),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  transcript.cumulativeGpaWithGrade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${transcript.courses.length} courses in ${transcript.year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .15)),
            ),
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

class _SemesterSection extends StatelessWidget {
  final String semester;
  final List<TranscriptCourse> courses;

  const _SemesterSection({required this.semester, required this.courses});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  semester.isEmpty ? 'Semester' : semester,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${courses.length} courses',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LensCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: courses.asMap().entries.map((entry) {
                final course = entry.value;
                final displayedGrade =
                    course.displayGrade.isEmpty ? '—' : course.displayGrade;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _gradeColor(displayedGrade)
                                  .withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              displayedGrade,
                              style: TextStyle(
                                color: _gradeColor(displayedGrade),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.course,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${course.hours} hours · ${course.group}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (course.numeric.isNotEmpty)
                            Text(
                              course.gpaWithGrade,
                              style: const TextStyle(
                                color: LensColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (entry.key != courses.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _gradeColor(String grade) {
    final normalized = grade.toUpperCase();
    if (normalized.startsWith('A')) return LensColors.aqua;
    if (normalized.startsWith('B')) return LensColors.indigo;
    if (normalized.startsWith('C')) return LensColors.amber;
    return LensColors.rose;
  }
}
