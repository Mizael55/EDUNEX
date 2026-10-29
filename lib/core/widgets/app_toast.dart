import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

enum ToastType { success, error, warning, info }

/// Sistema de alertas y notificaciones modernas (Toasts) flotantes en la parte
/// lateral superior derecha (Top-Right) de la pantalla.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static bool get _isInTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Muestra una alerta moderna en la esquina superior derecha
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 3800),
  }) {
    // Si ya existe una alerta activa, cancelamos su temporizador y la removemos limpiamente
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        title: title,
        type: type,
        duration: duration,
        onDismiss: () {
          _dismissTimer?.cancel();
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    if (!_isInTest) {
      _dismissTimer = Timer(duration, () {
        if (_currentEntry == entry) {
          entry.remove();
          _currentEntry = null;
        }
      });
    }
  }

  static void success(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'Operación Exitosa',
      type: ToastType.success,
      duration: duration ?? const Duration(milliseconds: 3800),
    );
  }

  static void error(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'Error del Sistema',
      type: ToastType.error,
      duration: duration ?? const Duration(milliseconds: 4500),
    );
  }

  static void warning(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'Aviso Importante',
      type: ToastType.warning,
      duration: duration ?? const Duration(milliseconds: 4200),
    );
  }

  static void info(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'Notificación EDUNEX',
      type: ToastType.info,
      duration: duration ?? const Duration(milliseconds: 3800),
    );
  }

  /// Cierra manualmente cualquier toast activo
  static void dismiss() {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.35, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _animController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    Color bgColor;
    Color borderColor;
    IconData icon;

    switch (widget.type) {
      case ToastType.success:
        primaryColor = const Color(0xFF059669);
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFFA7F3D0);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        primaryColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFECACA);
        icon = Icons.error_rounded;
        break;
      case ToastType.warning:
        primaryColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        icon = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        primaryColor = AppColors.navyPrimary;
        bgColor = const Color(0xFFEEF2FF);
        borderColor = const Color(0xFFC7D2FE);
        icon = Icons.verified_rounded;
        break;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500;
    final toastWidth = isCompact ? screenWidth - 32 : 390.0;

    return Positioned(
      top: 24,
      right: isCompact ? 16 : 24,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: toastWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icono con contenedor pastel
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              alignment: Alignment.center,
                              child: Icon(icon, color: primaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),

                            // Título y Mensaje
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.title != null && widget.title!.isNotEmpty) ...[
                                    Text(
                                      widget.title!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor == AppColors.navyPrimary
                                            ? AppColors.navyDark
                                            : primaryColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                  ],
                                  Text(
                                    widget.message,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF334155),
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Botón de cerrar
                            InkWell(
                              onTap: _handleDismiss,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Línea lateral de acento de estado
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
