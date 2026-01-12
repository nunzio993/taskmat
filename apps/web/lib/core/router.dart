import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/landing/landing_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/tasks/task_list_page.dart';
import '../features/tasks/create_task_page.dart';
import '../features/helper/find_work_page.dart';
import '../features/helper/my_jobs_page.dart';
import '../features/messages/messages_page.dart';
import '../features/profile/profile_page.dart';
import '../features/settings/settings_page.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // Public routes
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      
      // Authenticated routes with shell
      ShellRoute(
        builder: (context, state, child) {
          return DashboardShell(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TaskListPage(),
          ),
          GoRoute(
            path: '/create-task',
            builder: (context, state) => const CreateTaskPage(),
          ),
          GoRoute(
            path: '/find-work',
            builder: (context, state) => const FindWorkPage(),
          ),
          GoRoute(
            path: '/my-jobs',
            builder: (context, state) => const MyJobsPage(),
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}
