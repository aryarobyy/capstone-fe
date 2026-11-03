import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/colorScheme.dart';
import '../providers/notification_provider.dart';

class NotificationView extends StatefulWidget {
  static const routeName = '/notifications';
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: provider.fetch,
        child: _body(provider),
      ),
    );
  }

  Widget _body(NotificationProvider provider) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.errorMessage != null && provider.items.isEmpty) {
      return _centered(provider.errorMessage!);
    }
    if (provider.items.isEmpty) return _centered('Belum ada notifikasi.');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final n = provider.items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => provider.markRead(n.id),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: n.isRead ? AppColors.cardBackground : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: CircleAvatar(
                    radius: 4,
                    backgroundColor: n.isRead ? Colors.transparent : AppColors.primary,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(n.body, style: const TextStyle(color: AppColors.textSecondary)),
                      if (n.createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _stamp(n.createdAt!),
                          style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ListView so pull-to-refresh also works on the empty and error states.
  Widget _centered(String text) => ListView(
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      );

  String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }
}
