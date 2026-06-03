import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/error_screen.dart';
import 'services/deep_link_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/success_screen.dart';
import 'screens/validation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(() {
    // ignore: avoid_print
    print('[App] API base URL: ${AppConstants.baseUrl}');
    return true;
  }());

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style the system UI overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatefulWidget {
  const AttendanceApp({super.key});

  @override
  State<AttendanceApp> createState() => _AttendanceAppState();
}

class _AttendanceAppState extends State<AttendanceApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.instance.init(_onDeepLink);
    });
  }

  @override
  void dispose() {
    DeepLinkService.instance.dispose();
    super.dispose();
  }

  void _onDeepLink(String token) {
    final navContext = _navigatorKey.currentContext;
    if (navContext == null) return;

    final authProvider = navContext.read<AuthProvider>();
    handleDeepLinkToken(
      navContext,
      token,
      isAuthenticated: authProvider.isAuthenticated,
      hasStudentProfile: authProvider.user?.studentProfile != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr', 'FR'),
            supportedLocales: const [Locale('fr', 'FR')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ── Themes ──────────────────────────────────────────────────
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // ── Initial route ────────────────────────────────────────────
            initialRoute: AppConstants.routeSplash,

            // ── All routes via onGenerateRoute ───────────────────────────
            onGenerateRoute: (settings) {
              final builder = _routeBuilders[settings.name];
              if (builder != null) {
                return _FadeSlidePageRoute(
                  builder: builder,
                  settings: settings,
                );
              }
              // Fallback for unknown routes
              return _FadeSlidePageRoute(
                builder: (_) => const HomeScreen(),
                settings: settings,
              );
            },
          );
        },
      ),
    );
  }
}

/// Central map of named routes to their builder functions.
final Map<String, WidgetBuilder> _routeBuilders = {
  AppConstants.routeSplash: (_) => const SplashScreen(),
  AppConstants.routeLogin: (_) => const LoginScreen(),
  AppConstants.routeHome: (_) => const HomeScreen(),
  AppConstants.routeScanner: (_) => const QrScannerScreen(),
  AppConstants.routeValidation: (_) => const ValidationScreen(),
  AppConstants.routeSuccess: (_) => const SuccessScreen(),
  AppConstants.routeError: (_) => const ErrorScreen(),
};

// ─── Custom Page Route ────────────────────────────────────────────────────────

/// A [PageRouteBuilder] that fades and slides the new page up slightly,
/// giving a smooth and modern transition feel throughout the app.
class _FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  _FadeSlidePageRoute({
    required this.builder,
    required RouteSettings settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeIn),
            );
            final slideTween = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOut));

            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
        );
}
