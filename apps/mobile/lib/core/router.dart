
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/navigation/presentation/splash_screen.dart';
import '../features/navigation/presentation/shell_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/tasks/presentation/my_tasks_screen.dart';
import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/tasks/presentation/task_details_screen.dart';
import '../features/home/presentation/chat_screen.dart';
import '../features/tasks/presentation/create_task_screen.dart';
import '../features/profile/presentation/helper/helper_registration_screen.dart';
import '../features/profile/presentation/saved_addresses_screen.dart';
import '../features/profile/presentation/payment_methods_screen.dart';
import '../features/profile/presentation/notification_settings_screen.dart';
import 'package:mobile/features/profile/presentation/help_center_screen.dart';
import '../features/profile/presentation/edit_personal_profile_screen.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final hasError = authState.hasError;
      final session = authState.valueOrNull;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/';

      if (isLoading || hasError) return null; // Stay on splash or current

      final isRegisterHelper = state.matchedLocation == '/register-helper';

      if (session == null) {
        return (isLoggingIn || isRegisterHelper) ? null : '/login';
      }

      // Logged in
      if (isLoggingIn || isSplash) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/my-tasks',
            builder: (context, state) => const MyTasksScreen(),
          ),
          GoRoute(
            path: '/my-jobs',
            builder: (context, state) => const MyJobsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/register-helper',
            builder: (context, state) => const HelperRegistrationScreen(),
          ),
          GoRoute(
            path: '/task',
            builder: (context, state) {
               final task = state.extra as dynamic; 
               return TaskDetailsScreen(task: task);
            },
          ),
          GoRoute(
            path: '/create-task',
            builder: (context, state) => const CreateTaskScreen(),
          ),
          GoRoute(path: '/profile/edit', builder: (context, state) => const EditPersonalProfileScreen()),
          GoRoute(path: '/profile/addresses', builder: (context, state) => const SavedAddressesScreen()),
          GoRoute(path: '/profile/payments', builder: (context, state) => const PaymentMethodsScreen()),
          GoRoute(path: '/profile/notifications', builder: (context, state) => const NotificationSettingsScreen()),
          GoRoute(path: '/profile/help', builder: (context, state) => const HelpCenterScreen()),
          GoRoute(
            path: '/chat',
            builder: (context, state) {
              final extras = state.extra as Map<String, dynamic>;
              return ChatScreen(
                taskId: extras['taskId'],
                helperId: extras['helperId'],
                title: extras['title'],
              );
            },
          ),
        ],
      ),
    ],
  );
}
