import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademicRepository>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicRepository>();
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final needle = _search.text.trim().toLowerCase();
    final visible = academic.courses
        .where((course) =>
            needle.isEmpty ||
            course.code.toLowerCase().contains(needle) ||
            course.title.toLowerCase().contains(needle))
        .toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
        children: [
          PageHeading(
            eyebrow: academic.context?.currentSeason ?? 'Winter 2024',
            title: 'Course library',
            subtitle:
                'Explore exact portal records, then bring any course into the advisor.',
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by code or course name',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: keyboardVisible
                  ? IconButton(
                      tooltip: 'Hide keyboard',
                      onPressed: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      icon: const Icon(Icons.keyboard_hide_rounded),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          if (academic.loadingDashboard && academic.courses.isEmpty)
            const LensLoading(label: 'Loading semester courses…')
          else if (academic.error != null && academic.courses.isEmpty)
            LensError(
              message: academic.error!,
              onRetry: () => academic.loadDashboard(force: true),
            )
          else if (visible.isEmpty)
            const LensCard(
              child: Center(child: Text('No course matches that search.')),
            )
          else
            ...visible.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CourseCard(
                      course: entry.value,
                      index: entry.key,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseSummary course;
  final int index;

  const _CourseCard({required this.course, required this.index});

  @override
  Widget build(BuildContext context) {
    const accents = [
      LensColors.indigo,
      LensColors.aqua,
      LensColors.violet,
      LensColors.amber,
    ];
    final accent = accents[index % accents.length];
    return LensCard(
      onTap: () => context.push('/courses/${course.code}', extra: course),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 72,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      course.code,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_outward_rounded, size: 18, color: accent),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  course.track,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
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
