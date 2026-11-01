import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:main/ui/screens/home_page.dart';

void main() {
  runApp(const AgendaApp());
}

class AgendaApp extends StatelessWidget {
  const AgendaApp({super.key});

  static const _corPrincipal = Color(0xFF8E2348);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _corPrincipal),
        // Evita o clarão do efeito padrão de toque no navegador. O estado de toque é indicado apenas pelo efeito de foco.
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SemTransicaoDePagina(),
            TargetPlatform.fuchsia: _SemTransicaoDePagina(),
            TargetPlatform.iOS: _SemTransicaoDePagina(),
            TargetPlatform.linux: _SemTransicaoDePagina(),
            TargetPlatform.macOS: _SemTransicaoDePagina(),
            TargetPlatform.windows: _SemTransicaoDePagina(),
          },
        ),
      ),
      home: const HomePage(),
    );
  }
}

class _SemTransicaoDePagina extends PageTransitionsBuilder {
  const _SemTransicaoDePagina();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
