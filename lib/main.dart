import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'widgets/video_intro_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EdunexApp());
}

class EdunexApp extends StatelessWidget {
  const EdunexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDUNEX - CRM Escolar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navyPrimary,
          primary: AppColors.navyPrimary,
          secondary: AppColors.electricBlue,
          tertiary: AppColors.accentGreen,
          surface: AppColors.surfaceWhite,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        fontFamily: null,
      ),
      home: const EdunexRootFlow(),
    );
  }
}

/// Controla el flujo principal: Video introductorio -> Pantalla de Login
class EdunexRootFlow extends StatefulWidget {
  const EdunexRootFlow({super.key});

  @override
  State<EdunexRootFlow> createState() => _EdunexRootFlowState();
}

class _EdunexRootFlowState extends State<EdunexRootFlow> {
  // Inicia mostrando el video de presentación
  bool _showVideo = true;

  void _onVideoFinished() {
    setState(() {
      _showVideo = false;
    });
  }

  void _onReplayVideo() {
    setState(() {
      _showVideo = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _showVideo
          ? VideoIntroScreen(
              key: const ValueKey('VideoIntroScreen'),
              onFinished: _onVideoFinished,
            )
          : LoginScreen(
              key: const ValueKey('LoginScreen'),
              onReplayVideo: _onReplayVideo,
            ),
    );
  }
}
