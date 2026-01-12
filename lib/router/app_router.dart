import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/timer_page.dart';
import '../pages/profile_page.dart';
import '../pages/stats_page.dart';
import '../pages/settings_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/parent/parent_dashboard.dart';
import '../pages/child/child_dashboard.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';

final router = GoRouter(
  initialLocation: '/login', // Start at login
  redirect: (context, state) {
    // Basic auth guard
    final user = authService.currentUser;
    final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (user == null && !isAuthRoute) {
      return '/login';
    }

    if (user != null && isAuthRoute) {
      return user.role == UserRole.parent ? '/parent-dashboard' : '/child-dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/timer',
      name: 'timer',
      builder: (context, state) {
        final task = state.extra as StudyTask?;
        return TimerPage(task: task);
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/stats',
      name: 'stats',
      builder: (context, state) => const StatsPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    
    // Auth routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/parent-dashboard',
      name: 'parent-dashboard',
      builder: (context, state) => const ParentDashboard(),
    ),
    GoRoute(
      path: '/child-dashboard',
      name: 'child-dashboard',
      builder: (context, state) => const ChildDashboard(),
    ),
  ],
);
