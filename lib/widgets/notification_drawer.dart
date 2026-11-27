import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationDrawer extends StatelessWidget {
  const NotificationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final unreadCount = provider.unreadNotifications.length;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        provider.markAllAsRead();
                      },
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notifications.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final isRead = notification.isRead;
                        return ListTile(
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            notification.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(
                            Icons.notifications,
                            color: isRead
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                          ),
                          tileColor: isRead
                              ? null
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            tooltip: 'Close notification',
                            onPressed: () {
                              provider.closeNotification(notification.id);
                            },
                          ),
                          onTap: () {
                            provider.markAsRead(notification.id);
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(notification.title),
                                content: Text(notification.message),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      provider.closeNotification(
                                        notification.id,
                                      );
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            if (notifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () {
                    provider.clearAll();
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
