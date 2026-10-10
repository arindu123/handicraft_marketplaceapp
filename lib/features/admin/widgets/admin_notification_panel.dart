import 'package:flutter/material.dart';

import '../../../shared/data/marketplace_repository.dart';
import '../models/admin_demo_store.dart';
import 'admin_widgets.dart';

class AdminNotificationPanel extends StatelessWidget {
  const AdminNotificationPanel({super.key, required this.store});
  final AdminDemoStore store;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '${store.unreadNotifications} unread',
        style: const TextStyle(color: AdminStyle.muted),
      ),
      const SizedBox(height: 12),
      if (store.notifications.isEmpty)
        const AdminEmptyState('No notifications for your enabled categories.'),
      for (final notice in store.notifications)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AdminStyle.navy,
                  ),
                ),
                Text(notice.body),
                SelectableText('Reference: ${notice.targetId}'),
                if (notice.date != null)
                  Text(
                    notice.date!.toLocal().toString().split('.').first,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminStyle.muted,
                    ),
                  ),
                if (!store.readNoticeIds.contains(notice.id))
                  TextButton(
                    onPressed: () async {
                      try {
                        await store.markNoticeRead(notice);
                      } catch (error) {
                          if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(marketplaceError(error))),
                          );
                          }
                      }
                    },
                    child: const Text(
                      'Mark as read',
                      style: TextStyle(color: AdminStyle.clay),
                    ),
                  )
                else
                  const Text(
                    'Read',
                    style: TextStyle(fontSize: 12, color: AdminStyle.muted),
                  ),
              ],
            ),
          ),
        ),
    ],
  );
}
