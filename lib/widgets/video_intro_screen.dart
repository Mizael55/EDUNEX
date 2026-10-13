import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_colors.dart';

class VideoIntroScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const VideoIntroScreen({super.key, required this.onFinished});

  @override
  State<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends State<VideoIntroScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasTriggeredCompletion = false;
  bool _isMuted = true; // Iniciamos silenciado para garantizar autoplay en web
  Timer? _safetyTimeoutTimer;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _startSafetyTimer();
    _initAndPlayVideo();
  }

  /// Timer de seguridad: Si en 4 segundos el video no inicializa por cualquier razón
  /// (políticas de navegador, codec, etc.), pasa directamente al Login para nunca trabarse.
  void _startSafetyTimer() {
    _safetyTimeoutTimer = Timer(const Duration(seconds: 4), () {
      if (!_isInitialized && !_hasTriggeredCompletion) {
        debugPrint('Timeout al cargar video: pasando al login');
        _completeIntro();
      }
    });
  }

  Future<void> _initAndPlayVideo() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/edunex.mp4',
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _controller = controller;

      await controller.initialize();
      _safetyTimeoutTimer?.cancel();

      if (!mounted) return;

      controller.addListener(_checkVideoProgress);
      await controller.setLooping(false);

      // En la web los navegadores exigen que el video esté silenciado para autorizar el autoplay
      if (kIsWeb) {
        await controller.setVolume(0.0);
        _isMuted = true;
      } else {
        try {
          await controller.setVolume(1.0);
          _isMuted = false;
        } catch (_) {
          await controller.setVolume(0.0);
          _isMuted = true;
        }
      }

      await controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Temporizador de duración exacta para asegurar transición cuando termine
        final duration = controller.value.duration;
        if (duration > Duration.zero) {
          _durationTimer = Timer(
            duration + const Duration(milliseconds: 200),
            () => _completeIntro(),
          );
        }
      }
    } catch (e) {
      debugPrint('No se pudo reproducir el video, pasando al login: $e');
      _completeIntro();
    }
  }

  void _checkVideoProgress() {
    if (!mounted || _hasTriggeredCompletion || _controller == null) return;

    final value = _controller!.value;

    // Detectar cuando el video finaliza
    if (value.isCompleted ||
        (value.duration > Duration.zero &&
            value.position >= value.duration - const Duration(milliseconds: 250))) {
      _completeIntro();
    }
  }

  void _completeIntro() {
    if (_hasTriggeredCompletion) return;
    _hasTriggeredCompletion = true;

    _safetyTimeoutTimer?.cancel();
    _durationTimer?.cancel();

    if (_controller != null) {
      _controller!.removeListener(_checkVideoProgress);
      _controller!.pause();
    }

    if (mounted) {
      widget.onFinished();
    }
  }

  void _toggleMute() async {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
    });
    try {
      await _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    } catch (e) {
      debugPrint('Error al cambiar volumen: $e');
    }
  }

  @override
  void dispose() {
    _safetyTimeoutTimer?.cancel();
    _durationTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_checkVideoProgress);
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo cinematográfico
          Container(
            color: AppColors.navyDark,
          ),

          // Video centrado y adaptativo
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio > 0
                    ? _controller!.value.aspectRatio
                    : (16 / 9),
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyanLight),
              ),
            ),

          // Barra superior: Logo texto y Botón "Saltar"
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge EDUNEX
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: AppColors.cyanLight,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'EDUNEX CRM',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón para saltar directamente al login si el usuario lo desea
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        foregroundColor: AppColors.navyPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _completeIntro,
                      icon: const Text(
                        'Saltar intro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      label: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barra inferior: progreso y control de audio
          if (_isInitialized && _controller != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      // Botón para activar/desactivar audio
                      InkWell(
                        onTap: _toggleMute,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isMuted ? 'Activar sonido' : 'Silenciar',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Barra de progreso del video
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: false,
                            colors: const VideoProgressColors(
                              playedColor: AppColors.electricBlue,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
