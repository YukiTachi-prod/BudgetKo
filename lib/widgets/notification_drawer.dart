import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_wallet_models.dart';
import '../providers/group_wallet_provider.dart';
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
                            final isDeleteVote =
                                notification.actionType ==
                                    AppNotification
                                        .actionGroupWalletDeleteVote &&
                                notification.actionPayload != null;
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
                                  if (isDeleteVote)
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final groupWallet = context
                                            .read<GroupWalletProvider>();
                                        final result = await groupWallet
                                            .initiateOrConfirmDeleteVote(
                                              notification.actionPayload!,
                                            );
                                        provider.closeNotification(
                                          notification.id,
                                        );
                                        provider.syncGroupWalletDeleteVotes(
                                          groupWallet,
                                        );
                                        if (ctx.mounted) Navigator.pop(ctx);
                                        if (result ==
                                            VoteDeleteResult.deleted) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Group wallet removed (2/3 majority reached).',
                                              ),
                                            ),
                                          );
                                        } else if (result ==
                                            VoteDeleteResult.voted) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Removal vote confirmed. Waiting for 2/3 majority.',
                                              ),
                                            ),
                                          );
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                groupWallet.connectionError ??
                                                    'Could not record vote.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Confirm Removal'),
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
