import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../providers/post_provider.dart';
import 'post_detail_screen.dart';
import 'home_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await context.read<NotificationProvider>().loadNotifications();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} tuần trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  Future<void> _onNotificationTap(AppNotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      await context.read<NotificationProvider>().markAsRead(notification.id!);
    }

    //  Handle vaccine reminder - navigate and show popup
    if (notification.type == 'vaccine_reminder') {
      if (mounted) {
        // Pop back to home and navigate to vaccination tab
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Navigate to HomeScreen and pass vaccination ID to show popup
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              initialIndex: 2,
              vaccinationIdToShow: notification.vaccinationId,
            ),
          ),
        );
      }
      return;
    }
    // Handle post notifications (like/comment)
    final allPosts = context.read<PostProvider>().posts;
    try {
      final post = allPosts.firstWhere((p) => p.id == notification.postId);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bài viết không tồn tại hoặc đã bị xóa'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa tất cả thông báo'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa tất cả thông báo?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Xóa tất cả',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteAllNotifications();
    }
  }

  Future<void> _deleteAllNotifications() async {
    final provider = context.read<NotificationProvider>();
    final notifications = List.from(provider.notifications);

    for (var notification in notifications) {
      await provider.deleteNotification(notification.id!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${notifications.length} thông báo'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thông báo'),
        content: const Text('Bạn có chắc muốn xóa thông báo này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<NotificationProvider>().deleteNotification(notification.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thông báo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    provider.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã đánh dấu tất cả là đã đọc'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (value == 'delete_all') {
                    _showDeleteAllDialog();
                  }
                },
                itemBuilder: (context) => [
                  if (provider.unreadCount > 0)
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(
                            Icons.done_all,
                            size: 20,
                            color: Color(0xFFFF9966),
                          ),
                          SizedBox(width: 8),
                          Text('Đánh dấu tất cả đã đọc'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa tất cả thông báo'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thông báo nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thông báo sẽ xuất hiện khi có người\nthích hoặc bình luận bài viết của bạn\nhoặc khi có lịch tiêm sắp đến hạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationCard(notification, isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification, bool isDark) {
    return Dismissible(
      key: Key(notification.id!),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Xóa thông báo'),
            content: const Text('Bạn có chắc muốn xóa thông báo này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Xóa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        context.read<NotificationProvider>().deleteNotification(
          notification.id!,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa thông báo'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF3E0)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : const Color(0xFFFF9966).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          onTap: () => _onNotificationTap(notification),
          contentPadding: const EdgeInsets.all(12),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: notification.getIconColor(),

                child: notification.type == 'vaccine_reminder'
                    ? Icon(
                        notification.getIcon(),
                        color: Colors.white,
                        size: 28,
                      )
                    : (notification.fromUserAvatar != null
                          ? null
                          : Text(
                              notification.fromUserName
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                backgroundImage:
                    notification.type != 'vaccine_reminder' &&
                        notification.fromUserAvatar != null
                    ? NetworkImage(notification.fromUserAvatar!)
                    : null,
              ),
              if (notification.type != 'vaccine_reminder')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: notification.getIconColor(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      notification.getIcon(),
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            notification.getMessage(),
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.type == 'comment' &&
                  notification.commentContent != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '"${notification.commentContent}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _getTimeAgo(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9966),
                    shape: BoxShape.circle,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.grey[600],
                onPressed: () => _showDeleteDialog(notification),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
