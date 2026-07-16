import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/applications/presentation/screens/applicant_details_screen.dart';
import '../../features/applications/presentation/screens/applicants_screen.dart';
import '../../features/applications/presentation/screens/apply_screen.dart';
import '../../features/applications/presentation/screens/my_applications_screen.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/conversations_screen.dart';
import '../../features/dashboard/presentation/screens/startup_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/student_home_screen.dart';
import '../../features/analytics/presentation/startup_analytics_screen.dart';
import '../../features/internships/presentation/screens/explore_screen.dart';
import '../../features/internships/presentation/screens/internship_details_screen.dart';
import '../../features/internships/presentation/screens/internship_form_screen.dart';
import '../../features/internships/presentation/screens/manage_internships_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/onboarding_providers.dart';
import '../../features/internships/presentation/providers/internship_providers.dart';
import '../../features/internships/domain/entities/internship.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/screens/edit_startup_profile_screen.dart';
import '../../features/profile/presentation/screens/edit_student_profile_screen.dart';
import '../../features/profile/presentation/screens/startup_profile_screen.dart';
import '../../features/profile/presentation/screens/student_profile_screen.dart';
import '../../features/profile/presentation/screens/verification_screen.dart';
import '../widgets/offline_banner.dart';
import 'route_names.dart';

/// Role-aware router. All access control lives in [_redirect]:
///  * unauthenticated users can only reach onboarding/auth routes,
///  * unverified emails are parked on /verify-email,
///  * students cannot open startup routes and vice versa.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/student/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: RouteNames.verifyEmail,
        builder: (_, __) => const VerifyEmailScreen(),
      ),

      // ---------- Student shell ----------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => _ShellScaffold(
          shell: shell,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.search_rounded), label: 'Explore'),
            NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: 'Applications'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile')
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/home',
              name: RouteNames.studentHome,
              builder: (_, __) => const StudentHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/explore',
              name: RouteNames.explore,
              builder: (_, __) => const ExploreScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/applications',
              name: RouteNames.myApplications,
              builder: (_, __) => const MyApplicationsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/student/profile',
              name: RouteNames.studentProfile,
              builder: (_, __) => const StudentProfileScreen(),
            ),
          ]),
        ],
      ),

      // ---------- Startup shell ----------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => _ShellScaffold(
          shell: shell,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.work_outline_rounded),
                selectedIcon: Icon(Icons.work_rounded),
                label: 'Internships'),
            NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Applicants'),
            NavigationDestination(
                icon: Icon(Icons.business_outlined),
                selectedIcon: Icon(Icons.business_rounded),
                label: 'Profile'),
          ],
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/startup/dashboard',
              name: RouteNames.startupDashboard,
              builder: (_, __) => const StartupDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/startup/internships',
              name: RouteNames.manageInternships,
              builder: (_, __) => const ManageInternshipsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/startup/applicants',
              name: RouteNames.applicants,
              builder: (_, __) => const ApplicantsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/startup/profile',
              name: RouteNames.startupProfile,
              builder: (_, __) => const StartupProfileScreen(),
            ),
          ]),
        ],
      ),

      // ---------- Detail / shared routes ----------
      GoRoute(
        path: '/internships/new',
        name: RouteNames.internshipForm,
        builder: (_, state) =>
            InternshipFormScreen(internshipId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/internships/:id',
        name: RouteNames.internshipDetails,
        builder: (_, state) =>
            InternshipDetailsScreen(internshipId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/internships/:id/apply',
        name: RouteNames.applyInternship,
        builder: (_, state) =>
            ApplyScreen(internshipId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/applications/:id',
        name: RouteNames.applicationDetails,
        builder: (_, state) =>
            ApplicantDetailsScreen(applicationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile/edit-student',
        name: RouteNames.editStudentProfile,
        builder: (_, __) => const EditStudentProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit-startup',
        name: RouteNames.editStartupProfile,
        builder: (_, __) => const EditStartupProfileScreen(),
      ),
      GoRoute(
        path: '/profile/verification',
        name: RouteNames.verification,
        builder: (_, __) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        name: RouteNames.bookmarks,
        builder: (_, __) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/conversations',
        name: RouteNames.conversations,
        builder: (_, __) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/conversations/:id',
        name: RouteNames.chat,
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['id']!,
          peerName: state.uri.queryParameters['peer'] ?? 'Chat',
        ),
      ),
      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/startup/analytics',
        name: RouteNames.startupAnalytics,
        builder: (_, __) => const StartupAnalyticsScreen(),
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      // Notify the router and refresh internship providers so feeds rebuild
      // immediately after sign-in / sign-out, avoiding stale empty states
      // that sometimes require a manual page refresh on web.
      notifyListeners();
      try {
        _ref.invalidate(internshipFeedProvider(InternshipFilter()));
        _ref.invalidate(myInternshipsProvider);
      } catch (_) {}
    });
    _ref.listen(onboardingSeenProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authStateProvider);
    final seenOnboarding = _ref.read(onboardingSeenProvider);
    final loc = state.matchedLocation;

    final isAuthRoute = loc == '/login' ||
        loc == '/register' ||
        loc == '/forgot-password' ||
        loc == '/onboarding';

    if (auth.isLoading) return null; // splash handled by shell fallback

    final user = auth.value;
    if (user == null) {
      if (!seenOnboarding && loc != '/onboarding') return '/onboarding';
      return isAuthRoute ? null : '/login';
    }
    if (!user.emailVerified) {
      return loc == '/verify-email' ? null : '/verify-email';
    }

    final home =
        user.isStartup ? '/startup/dashboard' : '/student/home';
    if (isAuthRoute || loc == '/verify-email') return home;

    // Role guard: keep each role inside its own area.
    if (user.role == UserRole.student && loc.startsWith('/startup')) {
      return home;
    }
    if (user.role == UserRole.startup && loc.startsWith('/student')) {
      return home;
    }
    return null;
  }
}

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.shell, required this.destinations});

  final StatefulNavigationShell shell;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OfflineBanner(child: shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        destinations: destinations,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
