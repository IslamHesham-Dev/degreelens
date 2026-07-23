import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/repositories.dart';
import '../ui/advisor/advisor_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/core/app_shell.dart';
import '../ui/courses/course_details_screen.dart';
import '../ui/courses/courses_screen.dart';
import '../ui/overview/overview_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/transcript/transcript_screen.dart';
import 'theme.dart';

class DegreeLensApp extends StatefulWidget {
  const DegreeLensApp({super.key});

  @override
  State<DegreeLensApp> createState() => _DegreeLensAppState();
}

class _DegreeLensAppState extends State<DegreeLensApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthRepository>();
    _router = GoRouter(
      initialLocation: auth.isAuthenticated ? '/overview' : '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final atLogin = state.matchedLocation == '/login';
        if (!auth.isAuthenticated && !atLogin) return '/login';
        if (auth.isAuthenticated && atLogin) return '/overview';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/overview',
                  builder: (context, state) => const OverviewScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/courses',
                  builder: (context, state) => const CoursesScreen(),
                  routes: [
                    GoRoute(
                      path: ':code',
                      builder: (context, state) {
                        final extra = state.extra;
                        final course = extra is CourseSummary
                            ? extra
                            : CourseSummary.fromLabel(
                                state.pathParameters['code'] ?? 'Course',
                              );
                        return CourseDetailsScreen(course: course);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/advisor',
                  builder: (context, state) => const AdvisorScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/transcript',
                  builder: (context, state) => const TranscriptScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DegreeLens',
      debugShowCheckedModeBanner: false,
      theme: DegreeLensTheme.light(),
      routerConfig: _router,
    );
  }
}
