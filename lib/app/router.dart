import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/firebase_providers.dart';
import '../core/services/preferences.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/challenges/presentation/challenges_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/leaderboard/presentation/leaderboard_widgets.dart';
import '../features/marketplace/presentation/marketplace_screen.dart';
import '../features/marketplace/presentation/purchase_history_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/referral_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/qr_scanner/presentation/scanner_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/smart_bins/presentation/bins_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/transactions/presentation/my_qr_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/transactions/presentation/transfer_screen.dart';
import 'setup_required_screen.dart';

/// Route paths in one place.
abstract final class Routes {
  static const splash = '/splash';
  static const setupRequired = '/setup-required';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgot = '/forgot-password';
  static const setup = '/setup';
  static const home = '/home';
  static const rewards = '/rewards';
  static const bins = '/bins';
  static const profile = '/profile';

  static const _publicAuth = {signIn, signUp, forgot};
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Bridges Riverpod state changes to GoRouter's `refreshListenable`.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(authUserProvider, (_, __) => refresh.ping());
  ref.listen(onboardedProvider, (_, __) => refresh.ping());
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final boot = ref.read(bootProvider);
    if (!boot.isReady) {
      return loc == Routes.setupRequired ? null : Routes.setupRequired;
    }
    if (loc == Routes.setupRequired) return Routes.home;

    final auth = ref.read(authUserProvider);
    if (auth.isLoading && !auth.hasValue) {
      return loc == Routes.splash ? null : Routes.splash;
    }
    final signedIn = auth.valueOrNull != null;
    final onboarded = ref.read(onboardedProvider);
    final inAuthArea = Routes._publicAuth.contains(loc) ||
        loc == Routes.onboarding ||
        loc == Routes.splash;

    if (!signedIn) {
      if (!onboarded) {
        return Routes._publicAuth.contains(loc) || loc == Routes.onboarding
            ? null
            : Routes.onboarding;
      }
      return Routes._publicAuth.contains(loc) ? null : Routes.signIn;
    }
    // A fresh sign-up always lands on profile setup (also avoids a race with
    // the auth-state redirect firing before the sign-up screen navigates).
    if (loc == Routes.signUp) return Routes.setup;
    if (inAuthArea) return Routes.home;
    return null;
  }

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: Routes.setupRequired,
        builder: (_, __) => const SetupRequiredScreen(),
      ),
      GoRoute(
          path: Routes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, __) => const SignUpScreen()),
      GoRoute(
          path: Routes.forgot,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: Routes.setup,
        builder: (_, __) => const EditProfileScreen(isSetup: true),
      ),

      // Bottom-navigation tabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.home, builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.rewards,
                builder: (_, __) => const MarketplaceScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.bins, builder: (_, __) => const BinsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: Routes.profile,
                builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // Full-screen routes above the tab bar.
      GoRoute(path: '/scan', builder: (_, __) => const ScannerScreen()),
      GoRoute(
        path: '/transfer',
        builder: (_, state) =>
            TransferScreen(recipientUid: state.uri.queryParameters['to']),
      ),
      GoRoute(path: '/my-qr', builder: (_, __) => const MyQrScreen()),
      GoRoute(
          path: '/transactions',
          builder: (_, __) => const TransactionsScreen()),
      GoRoute(path: '/stats', builder: (_, __) => const StatisticsScreen()),
      GoRoute(
          path: '/challenges', builder: (_, __) => const ChallengesScreen()),
      GoRoute(
          path: '/achievements',
          builder: (_, __) => const AchievementsScreen()),
      GoRoute(
          path: '/leaderboard',
          builder: (_, __) => const LeaderboardScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/purchases',
          builder: (_, __) => const PurchaseHistoryScreen()),
      GoRoute(path: '/referral', builder: (_, __) => const ReferralScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, __) => const NotificationPrefsScreen(),
      ),
      GoRoute(
          path: '/settings/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(
          path: '/settings/about', builder: (_, __) => const AboutScreen()),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Icon(Icons.error_outline_rounded, size: 48)),
    ),
  );
});
