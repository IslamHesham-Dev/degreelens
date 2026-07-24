import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
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
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => academic.loadDashboard(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(child: LensLogo(size: 39)),
                    IconButton.filledTonal(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 120),
              sliver: SliverList.list(
                children: [
                  const PageHeading(
                    eyebrow: 'Academic focus',
                    title: 'Your degree,\nin focus.',
                    subtitle:
                        'A calm view of where you stand and what deserves attention next.',
                  ),
                  const SizedBox(height: 18),
                  _AdvisorySemesterPicker(academic: academic),
                  const SizedBox(height: 24),
                  const _FocusHero(),
                  const SizedBox(height: 18),
                  if (academic.loadingDashboard &&
                      academic.context == null) ...[
                    const LensCard(child: LensLoading()),
                  ] else if (academic.error != null &&
                      academic.context == null) ...[
                    LensError(
                      message: academic.error!,
                      onRetry: () => academic.loadDashboard(force: true),
                    ),
                  ] else ...[
                    _Metrics(academic: academic),
                    const SizedBox(height: 26),
                    _SectionTitle(
                      title: 'Quick focus',
                      action: 'Open advisor',
                      onTap: () => context.go('/advisor'),
                    ),
                    const SizedBox(height: 12),
                    _PromptGrid(
                      onPrompt: (prompt) {
                        context.read<AdvisorRepository>().send(prompt);
                        context.go('/advisor');
                      },
                    ),
                    const SizedBox(height: 28),
                    _SectionTitle(
                      title: 'Current courses',
                    ),
                    const SizedBox(height: 12),
                    ...academic.courses.map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _CompactCourseCard(course: course),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisorySemesterPicker extends StatelessWidget {
  final AcademicRepository academic;

  const _AdvisorySemesterPicker({required this.academic});

  @override
  Widget build(BuildContext context) {
    final current = academic.context?.currentSeason ?? 'Winter 2024';
    final options = <String>{current, ...academic.seasons}.toList();
    return DropdownButtonFormField<String>(
      value: current,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Advisory semester',
        helperText: 'Controls dashboard courses and the AI advisor context.',
        prefixIcon: Icon(Icons.calendar_month_outlined),
      ),
      items: options
          .map(
            (season) => DropdownMenuItem(
              value: season,
              child: Text(
                season,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: academic.updatingAdvisorySemester
          ? null
          : (season) async {
              if (season == null || season == current) return;
              final changed = await academic.selectAdvisorySemester(season);
              if (!context.mounted) return;
              if (changed) {
                context.read<AdvisorRepository>().clearLocal();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      academic.error ??
                          'Now advising from $season. '
                              'The previous advisor conversation was reset.',
                    ),
                  ),
                );
              } else if (academic.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(academic.error!)),
                );
              }
            },
    );
  }
}

class _FocusHero extends StatelessWidget {
  const _FocusHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LensColors.ink, Color(0xFF28326B)],
        ),
        boxShadow: [
          BoxShadow(
            color: LensColors.indigo.withValues(alpha: .23),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Clarity before\nthe next move.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.08,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The selected historical semester is used as your current advisory context.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: LensColors.aqua, size: 18),
              const SizedBox(width: 8),
              Text(
                'Evidence-based academic guidance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .86),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  final AcademicRepository academic;

  const _Metrics({required this.academic});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              icon: Icons.auto_stories_rounded,
              value: '${academic.courses.length}',
              label: 'Courses',
              color: LensColors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Metric(
              icon: Icons.bubble_chart_rounded,
              value: academic.transcript?.cumulativeGpaWithGrade ?? '—',
              label: 'Cumulative GPA',
              color: LensColors.aqua,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LensCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null && onTap != null)
          TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

class _PromptGrid extends StatelessWidget {
  final ValueChanged<String> onPrompt;

  const _PromptGrid({required this.onPrompt});

  @override
  Widget build(BuildContext context) {
    const prompts = [
      (
        Icons.track_changes_rounded,
        'Find my weakest assessment',
        'Which assessment needs my attention most?'
      ),
      (
        Icons.event_note_rounded,
        'Plan my next week',
        'Build a one-week study plan from my available grades.'
      ),
    ];
    return Row(
      children: prompts
          .map(
            (prompt) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: prompt == prompts.first ? 6 : 0,
                  left: prompt == prompts.last ? 6 : 0,
                ),
                child: LensCard(
                  onTap: () => onPrompt(prompt.$3),
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 92,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(prompt.$1, color: LensColors.indigo),
                        const Spacer(),
                        Text(
                          prompt.$2,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CompactCourseCard extends StatelessWidget {
  final CourseSummary course;

  const _CompactCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return LensCard(
      onTap: () => context.push('/courses/${course.code}', extra: course),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LensColors.indigo.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              course.code
                  .replaceAll(RegExp(r'\d'), '')
                  .characters
                  .take(3)
                  .join(),
              style: const TextStyle(
                color: LensColors.indigo,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.code,
                    style: const TextStyle(
                        color: LensColors.indigo,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  course.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: LensColors.muted),
        ],
      ),
    );
  }
}
