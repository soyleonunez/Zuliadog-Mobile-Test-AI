// lib/core/notifications.dart
import 'package:flutter/material.dart';

/// Sistema de notificaciones para la aplicación Zuliadog
class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Muestra una notificación de éxito
  static void showSuccess(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFF16A34A), // green-600
      textColor: Colors.white,
      icon: Icons.check_circle,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra una notificación de error
  static void showError(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFFDC2626), // red-600
      textColor: Colors.white,
      icon: Icons.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Muestra una notificación de advertencia
  static void showWarning(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFFD97706), // amber-600
      textColor: Colors.white,
      icon: Icons.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra una notificación de información
  static void showInfo(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFF2563EB), // blue-600
      textColor: Colors.white,
      icon: Icons.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Muestra una notificación de estado de historia
  static void showHistoryStatus(String message, bool isLocked) {
    _showSnackBar(
      message: message,
      backgroundColor: isLocked
          ? const Color(0xFFDC2626) // red-600
          : const Color(0xFF16A34A), // green-600
      textColor: Colors.white,
      icon: isLocked ? Icons.lock : Icons.lock_open,
      duration: const Duration(seconds: 2),
    );
  }

  /// Muestra una notificación de carga
  static void showLoading(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: const Color(0xFF6B7280), // gray-500
      textColor: Colors.white,
      icon: Icons.hourglass_empty,
      duration: const Duration(seconds: 1),
    );
  }

  /// Método privado para mostrar el SnackBar
  static void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Duration duration,
  }) {
    final context = _scaffoldKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Cerrar',
          textColor: textColor,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Obtiene la clave del ScaffoldMessenger para usar en MaterialApp
  static GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;
}

/// Widget para mostrar notificaciones de estado de historias
class HistoryStatusNotification extends StatelessWidget {
  final String message;
  final bool isLocked;
  final VoidCallback? onDismiss;

  const HistoryStatusNotification({
    super.key,
    required this.message,
    required this.isLocked,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked
            ? const Color(0xFFFEE2E2) // red-100
            : const Color(0xFFDCFCE7), // green-100
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLocked
              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
              : const Color(0xFF16A34A).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLocked ? Icons.lock : Icons.lock_open,
            color: isLocked
                ? const Color(0xFFDC2626) // red-700
                : const Color(0xFF16A34A), // green-700
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isLocked
                    ? const Color(0xFFDC2626) // red-700
                    : const Color(0xFF16A34A), // green-700
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              color: isLocked
                  ? const Color(0xFFDC2626) // red-700
                  : const Color(0xFF16A34A), // green-700
            ),
        ],
      ),
    );
  }
}
