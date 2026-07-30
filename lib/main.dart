import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/app_provider.dart';
import 'providers/ai_provider_manager.dart';
import 'providers/presentation_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundary — catch unhandled Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  // Catch async errors that escape the zone
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher Error: $error');
    debugPrint('Stack: $stack');
    return true; // We handled it
  };

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => PresentationState()),
        ChangeNotifierProvider(create: (_) {
          final manager = AIProviderManager();
          manager.loadProviders();
          return manager;
        }),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'Ghita PPT Converter',
            debugShowCheckedModeBanner: false,
            themeMode: appProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepOrange,
                brightness: Brightness.light,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFE0E0E0),
                thickness: 1,
                space: 1,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                elevation: 4,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepOrange,
                brightness: Brightness.dark,
              ),
              cardTheme: const CardThemeData(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              dividerTheme: const DividerThemeData(
                color: Color(0xFF404040),
                thickness: 1,
                space: 1,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                elevation: 4,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
