
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/navigation/presentation/splash_screen.dart';
import '../features/navigation/presentation/shell_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/tasks/presentation/my_tasks_screen.dart';
import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
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
import '../features/home/presentation/helper/find_work_screen.dart';
import '../features/profile/presentation/preferences_screen.dart';
import '../features/home/presentation/helper/helper_my_jobs_page.dart';
import '../features/profile/presentation/public_user_profile_screen.dart';

part 'router.g.dart';

/// Provider to check if user has seen the welcome screen
final hasSeenWelcomeProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_seen_welcome') ?? false;
});

@riverpod
GoRouter router(Ref ref) {
  // Watch authentication status
  final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
  final hasError = ref.watch(authProvider.select((s) => s.hasError));
  final isLoggedIn = ref.watch(authProvider.select((s) => s.valueOrNull != null));
  final userRole = ref.watch(authProvider.select((s) => s.valueOrNull?.role));
  
  // Watch welcome screen status
  final hasSeenWelcome = ref.watch(hasSeenWelcomeProvider).valueOrNull ?? false;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isWelcome = state.matchedLocation == '/welcome';
      final isSplash = state.matchedLocation == '/';

      if (isLoading || hasError) return null; // Stay on splash or current

      final isRegisterHelper = state.matchedLocation == '/register-helper';

      if (!isLoggedIn) {
        // First time users go to welcome screen
        if (!hasSeenWelcome && !isWelcome) {
          return '/welcome';
        }
        // Otherwise go to login
        return (isLoggingIn || isRegisterHelper || isWelcome) ? null : '/login';
      }

      // Logged in
      if (isLoggingIn || isSplash || isWelcome) {
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
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
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
            builder: (context, state) => const HelperMyJobsPage(),
          ),
          GoRoute(
            path: '/find-work',
            builder: (context, state) {
              final focusTaskIdStr = state.uri.queryParameters['focusTaskId'];
              final focusTaskId = focusTaskIdStr != null ? int.tryParse(focusTaskIdStr) : null;
              return FindWorkScreen(focusTaskId: focusTaskId);
            },
          ),
          GoRoute(
            path: '/preferences',
            builder: (context, state) => const PreferencesScreen(),
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
            path: '/task/:taskId',
            builder: (context, state) {
               final taskIdStr = state.pathParameters['taskId'];
               final taskId = int.tryParse(taskIdStr ?? '') ?? 0;
               return TaskDetailsScreenById(taskId: taskId);
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
            path: '/u/:userId',
            builder: (context, state) {
              final userIdStr = state.pathParameters['userId'];
              final userId = int.tryParse(userIdStr ?? '') ?? 0;
              return PublicUserProfileScreen(userId: userId);
            },
          ),
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

