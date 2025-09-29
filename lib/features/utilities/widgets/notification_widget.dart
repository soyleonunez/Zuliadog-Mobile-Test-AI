import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/notification_service.dart';
import '../../home.dart' as home;

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await NotificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Botón principal de notificaciones
        GestureDetector(
          onTap: () {
            setState(() {
              _isDropdownOpen = !_isDropdownOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: home.AppColors.neutral100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: home.AppColors.neutral200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.notification,
                  color: _notifications.isNotEmpty
                      ? home.AppColors.primary500
                      : home.AppColors.neutral500,
                  size: 20,
                ),
                if (_notifications.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: home.AppColors.danger500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_notifications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Dropdown de notificaciones
        if (_isDropdownOpen)
          Positioned(
            top: 60,
            right: 0,
            child: Container(
              width: 350,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: home.AppColors.neutral200,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header del dropdown
                  _buildDropdownHeader(),

                  // Lista de notificaciones
                  Flexible(
                    child: _buildNotificationsList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: home.AppColors.primary500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Iconsax.notification,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notificaciones',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDropdownOpen = false;
              });
            },
            child: const Icon(
              Iconsax.close_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Iconsax.notification_bing,
              color: home.AppColors.neutral400,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                color: home.AppColors.neutral600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Todas las tareas están al día',
              style: TextStyle(
                color: home.AppColors.neutral400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _getNotificationColor(notification.priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getNotificationColor(notification.priority).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.priority),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: home.AppColors.neutral900,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.description,
              style: TextStyle(
                color: home.AppColors.neutral600,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Iconsax.clock,
                  color: home.AppColors.neutral400,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(notification.scheduledTime),
                  style: TextStyle(
                    color: home.AppColors.neutral500,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.priority),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    notification.priority.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          NotificationService.handleNotificationAction(notification, context);
          setState(() {
            _isDropdownOpen = false;
          });
        },
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'complete':
                _completeNotification(notification);
                break;
              case 'dismiss':
                _dismissNotification(notification);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(Iconsax.tick_circle, size: 16),
                  SizedBox(width: 8),
                  Text('Completar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'dismiss',
              child: Row(
                children: [
                  Icon(Iconsax.close_circle, size: 16),
                  SizedBox(width: 8),
                  Text('Descartar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return home.AppColors.success500;
      case NotificationPriority.normal:
        return home.AppColors.primary500;
      case NotificationPriority.high:
        return home.AppColors.warning500;
      case NotificationPriority.urgent:
        return home.AppColors.danger500;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.medication:
        return Iconsax.health;
      case NotificationType.feeding:
        return Iconsax.cup;
      case NotificationType.exercise:
        return Iconsax.activity;
      case NotificationType.monitoring:
        return Iconsax.eye;
      case NotificationType.treatment:
        return Iconsax.health;
      case NotificationType.examination:
        return Iconsax.document_text;
      case NotificationType.vaccination:
        return Iconsax.shield_tick;
      case NotificationType.surgery:
        return Iconsax.scissor;
      case NotificationType.consultation:
        return Iconsax.message_question;
      case NotificationType.followUp:
        return Iconsax.refresh;
      case NotificationType.labTest:
        return Iconsax.health;
      case NotificationType.imaging:
        return Iconsax.camera;
      case NotificationType.therapy:
        return Iconsax.heart;
      case NotificationType.grooming:
        return Iconsax.scissor_1;
      case NotificationType.boarding:
        return Iconsax.home;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);

    if (difference.inDays > 0) {
      return 'En ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'En ${difference.inMinutes} minutos';
    } else {
      return 'Ahora';
    }
  }

  Future<void> _completeNotification(NotificationItem notification) async {
    try {
      await NotificationService.markAsCompleted(notification.id);
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación completada'),
            backgroundColor: home.AppColors.success500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completando notificación'),
            backgroundColor: home.AppColors.danger500,
          ),
        );
      }
    }
  }

  Future<void> _dismissNotification(NotificationItem notification) async {
    try {
      await NotificationService.markAsRead(notification.id);
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación descartada'),
            backgroundColor: home.AppColors.neutral500,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error descartando notificación'),
            backgroundColor: home.AppColors.danger500,
          ),
        );
      }
    }
  }
}
