import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_refresh_notifier.dart';
import '../utils/server_time.dart';

class NotificationItem {
  final String id;
  final String message;
  final DateTime? createdAt;
  bool read;

  NotificationItem({
    required this.id,
    required this.message,
    required this.createdAt,
    this.read = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      items = data.map<NotificationItem>((n) {
        return NotificationItem(
          id: n['notification_id'],
          message: n['message'],
          createdAt: parseServerTime(n['created_at']),
          read: n['read'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('NOTIF LOAD ERROR: $e');
    }
    setState(() {
      loading = false;
    });
  }

  Future markRead(NotificationItem item) async {
    try {
      await ApiService.markNotificationRead(item.id);
      setState(() {
        item.read = true;
      });
      AppRefreshNotifier.notify();
    } catch (e) {
      print('MARK READ ERROR: $e');
    }
  }

  Future deleteNotification(NotificationItem item) async {
    try {
      await ApiService.deleteNotification(item.id);
      setState(() {
        items.removeWhere((n) => n.id == item.id);
      });
      AppRefreshNotifier.notify();
    } catch (e) {
      print('DELETE NOTIF ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final n = items[index];
                    return ListTile(
                      leading: Icon(
                        n.read ? Icons.notifications_none : Icons.notifications,
                        color: n.read ? Colors.grey : Colors.blue,
                      ),
                      title: Text(n.message),
                      subtitle: Text(
                        n.createdAt != null
                            ? "${n.createdAt!.day}/${n.createdAt!.month}/${n.createdAt!.year} ${n.createdAt!.hour.toString().padLeft(2, '0')}:${n.createdAt!.minute.toString().padLeft(2, '0')}"
                            : "Unknown time",
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => deleteNotification(n),
                      ),
                      onTap: () {
                        if (!n.read) markRead(n);
                      },
                    );
                  },
                ),
    );
  }
}
