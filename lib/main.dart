import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/firebase_service.dart';
import 'package:project/Description.dart';

// ✅ Localization
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:project/l10n/app_localizations.dart';

// ✅ Locale controller
import 'package:project/services/locale_controller.dart';

// ✅ Firebase auth + firestore (for reading saved language)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Your AI models init
import 'package:project/services/ai_models.dart';

// ✅ Supabase
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Splash screen (create this file as shared earlier)
import 'package:project/splash/splash_screen.dart';

// -------------------- IMMERSIVE OBSERVER --------------------
class ImmersiveObserver extends NavigatorObserver with WidgetsBindingObserver {
  ImmersiveObserver() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _applyImmersive() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyImmersive();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyImmersive();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _applyImmersive();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyImmersive();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

// -------------------- GLOBAL SAFEAREA WRAPPER --------------------
class GlobalSafeArea extends StatelessWidget {
  final Widget child;
  const GlobalSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      top: false,
      child: child,
    );
  }
}

// -------------------- LOAD USER LANGUAGE FROM FIRESTORE --------------------
Future<void> _loadUserLanguageIfLoggedIn() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('user_settings')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data();
    final code = (data?['languageCode'] ?? 'en') as String;

    // ✅ Apply instantly
    LocaleController.setLocale(code);
  } catch (_) {
    // ignore
  }
}

// ✅ Apply language whenever user logs in again (fixes logout/login reset)
void _listenAuthAndApplyLanguage() {
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      await _loadUserLanguageIfLoggedIn();
    }
  });
}

// -------------------- MAIN --------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Supabase (Storage + Edge Functions)
  await Supabase.initialize(
    url: 'https://tutioytqvbukrveotayv.supabase.co',
    anonKey: '6326a648f4b3aa145cdc37ff73664c06b329f60073cc276101e1d026ee478e9c',
  );

  // 🔥 Initialize Firebase
  await FirebaseService.init();

  // ✅ Initialize AI model ONCE (tissue detector)
  await tissueDetector.init();

  // ✅ Immersive Mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // ✅ If user already logged in, load saved language (Urdu stays Urdu)
  await _loadUserLanguageIfLoggedIn();

  // ✅ If user logs in later, apply saved language too
  _listenAuthAndApplyLanguage();

  runApp(const MyApp());
}

// -------------------- APP --------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final ImmersiveObserver _immersiveObserver = ImmersiveObserver();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.locale,
      builder: (context, appLocale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BreastScan AI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xffFF67CE),
            ),
          ),

          // ✅ app locale
          locale: appLocale,

          // ✅ Localization Setup
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ur'),
          ],

          // ✅ Immersive observer
          navigatorObservers: [_immersiveObserver],

          // ✅ Force LTR always
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: GlobalSafeArea(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },

          // ✅ Starting Screen (Animated Splash -> Description)
          home: const SplashScreen(
            next: Description(),
          ),
        );
      },
    );
  }
}