import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/constants/app_colors.dart';
import 'core/services/api_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/residente/screens/residente_home_screen.dart';
import 'features/guardia/screens/guardia_home_screen.dart';
import 'features/administrador/screens/admin_home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  ApiService().init();
  runApp(const UrbanApp());
}

class UrbanApp extends StatelessWidget {
  const UrbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanApp',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        _EsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      locale: const Locale('es'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'Roboto',
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedLabelStyle: TextStyle(fontFamily: 'Roboto', fontSize: 11),
          unselectedLabelStyle: TextStyle(fontFamily: 'Roboto', fontSize: 11),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Roboto', fontSize: 11),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/registro': (_) => const RegisterScreen(),
        '/residente/home': (_) => const ResidenteHomeScreen(),
        '/guardia/home': (_) => const GuardiaHomeScreen(),
        '/admin/home': (_) => const AdminHomeScreen(),
      },
    );
  }
}

class _EsLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _EsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'es';

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      const _EsLocalizations();

  @override
  bool shouldReload(_EsLocalizationsDelegate old) => false;
}

class _EsLocalizations extends DefaultMaterialLocalizations {
  const _EsLocalizations();

  @override
  String get cancelButtonLabel => 'Cancelar';

  @override
  String get okButtonLabel => 'Aceptar';
}
