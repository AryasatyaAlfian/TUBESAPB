import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_refresh.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with AutoRefreshMixin {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
    startAutoRefresh();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  @override
  Future<void> onAutoRefresh() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _api.getNotifications();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _items = res['data']['notifications'] ?? [];
        _error = '';
      } else if (!silent) {
        _error = res['message'] ?? 'Gagal';
      }
    });
  }

  Future<void> _markRead(String id) async {
    final res = await _api.markNotificationRead(id);
    if (res['success'] == true) _load();
  }

  Future<void> _markAll() async {
    final res = await _api.markAllNotificationsRead();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Selesai')));
    if (res['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: _items.isEmpty ? null : _markAll,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.infoLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Notifikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = _items[i];
          final data = n['data'] ?? {};
          final message = data['message'] ?? 'Notifikasi';
          final isUnread = n['read_at'] == null;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isUnread ? () => _markRead(n['id'].toString()) : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnread
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : (isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(n['created_at']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    return s.length >= 16 ? s.substring(0, 16).replaceAll('T', ' ') : s;
  }
}
