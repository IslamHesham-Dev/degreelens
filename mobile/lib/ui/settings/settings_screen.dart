import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/environment.dart';
import '../../data/repositories.dart';
import '../core/lens_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    final auth = context.watch<AuthRepository>();
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
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const PageHeading(
                eyebrow: 'Control centre',
                title: 'Private by design.',
                subtitle:
                    'Manage the assumptions, session, and cached academic data behind DegreeLens.',
              ),
              const SizedBox(height: 24),
              LensCard(
                child: Column(
                  children: [
                    _AdvisorySemesterSelector(
                      academic: academic,
                      fallbackSeason:
                          auth.session?.currentSeason ?? 'Winter 2024',
                    ),
                    const Divider(height: 25),
                    _SettingRow(
                      icon: Icons.school_rounded,
                      title: 'Advisor transcript reference',
                      value: academic.context?.transcriptYear ??
                          auth.session?.advisoryYear ??
                          '2024-2025',
                    ),
                    const Divider(height: 25),
                    const _SettingRow(
                      icon: Icons.visibility_outlined,
                      title: 'Academic data source',
                      value: 'GIU Student Portal',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LensCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data controls',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cached data reduces repeated requests to GIU’s slow portal.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await academic.clearPortalCache();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Portal cache cleared.'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Clear portal cache'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.read<AdvisorRepository>().reset(),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Reset advisor conversation'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              LensCard(
                color: LensColors.ink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: LensColors.aqua),
                    const SizedBox(height: 14),
                    const Text(
                      'Your GIU password is never sent to the AI.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The app stores only a short-lived DegreeLens session token in secure device storage.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .62),
                        height: 1.45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: LensColors.rose,
                ),
                onPressed: auth.isBusy
                    ? null
                    : () async {
                        await context.read<AdvisorRepository>().reset();
                        academic.clearLocal();
                        await auth.logout();
                      },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out and close portal session'),
              ),
              const SizedBox(height: 22),
              Text(
                'API · ${Environment.apiBaseUrl}',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvisorySemesterSelector extends StatelessWidget {
  final AcademicRepository academic;
  final String fallbackSeason;

  const _AdvisorySemesterSelector({
    required this.academic,
    required this.fallbackSeason,
  });

  @override
  Widget build(BuildContext context) {
    final current = academic.context?.currentSeason ?? fallbackSeason;
    final options = <String>{current, ...academic.seasons}.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: LensColors.indigo,
              size: 20,
            ),
            SizedBox(width: 9),
            Text(
              'Advisory semester',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: current,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        content: Text(academic.error ??
                            'Advisory semester changed to $season. '
                                'The advisor conversation was reset.'),
                      ),
                    );
                  } else if (academic.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(academic.error!)),
                    );
                  }
                },
        ),
        const SizedBox(height: 9),
        const Text(
          'This controls the courses and grades treated as current by the advisor.',
          style: TextStyle(
            color: LensColors.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: LensColors.indigo.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: LensColors.indigo, size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
