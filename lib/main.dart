import 'package:articly/data/services/auth_service.dart';
import 'package:articly/data/services/shared_preferences_service.dart';
import 'package:articly/domain/providers/user_provider.dart';
import 'package:articly/presentation/authentication/view_models/auth_page_model.dart';
import 'package:articly/presentation/authentication/view_models/verify_email_view_model.dart';
import 'package:articly/presentation/authentication/widgets/auth_page.dart';
import 'package:articly/presentation/authentication/widgets/verify_email_page.dart';
import 'package:articly/presentation/core/error_page.dart';
import 'package:articly/presentation/website_displaying/widgets/home_page.dart';
import 'package:articly/theme/app_theme.dart';
import 'package:articly/theme/theme_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen((record) {
    debugPrint(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });
}

void main() async {
  setupLogging();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  final prefs = await SharedPreferences.getInstance();
  final prefsService = SharedPreferencesService(prefs: prefs);

  final themeModel = ThemeModel(prefs: prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: prefsService),
        ChangeNotifierProvider.value(value: themeModel),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeModel = context.watch<ThemeModel>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeModel.themeMode,
      home: AuthGate(),
    );
  }
}

/// Decided what page to redirect the user to
class AuthGate extends StatelessWidget {
  AuthGate({super.key, AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  final log = Logger("AuthGate");

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
          // or show a skeleton screen
        }

        if (snapshot.hasError) {
          // return an error scaffold
          log.severe('An error occurred: ${snapshot.error.toString()}');
          return const ErrorPage(
            text:
                'An error occurred. Please try entering the app later. If this error continues, try to ${kIsWeb ? 'clear the site data off your browser' : 'clear the app data off your device'}.',
          );
        }

        if (!snapshot.hasData || user == null) {
          log.info('No user data. Moving to authentication page...');
          return AuthPage(viewModel: AuthPageModel(service: _authService));
        }

        // has data

        if (!user.emailVerified) {
          log.info(
            'The user\'s email is not verified, so moving him to the email verification page',
          );
          return VerifyEmailScreen(
            viewModel: VerifyEmailViewModel(authService: _authService),
          );
        }

        log.info('Moving to home page...');

        return const HomePage();
      },
    );
  }
}
