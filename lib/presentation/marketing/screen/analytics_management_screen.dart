import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kkpchatapp/config/theme/app_colors.dart';
import 'package:kkpchatapp/config/theme/app_text_styles.dart';
import 'package:kkpchatapp/data/models/activity_model.dart';
import 'package:kkpchatapp/l10n/generated/app_localizations.dart';
import 'package:kkpchatapp/logic/agent/analytics_management_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AnalyticsManagementScreen extends StatelessWidget {
  const AnalyticsManagementScreen({super.key});

  String _formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('hh:mm a').format(date);
  String _formatDateTime(DateTime date) => DateFormat('dd MMM yyyy, hh:mm a').format(date);

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  Future<void> _downloadAsExcel(
    BuildContext context,
    List<Activity> activities,
  ) async {
    final provider = context.read<AnalyticsManagementProvider>();
    provider.setDownloading(true);

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Analytics'];

      sheet.appendRow([
        TextCellValue('Name'),
        TextCellValue('Email'),
        TextCellValue('Feature'),
        TextCellValue('Date'),
        TextCellValue('Time'),
      ]);

      for (final activity in activities) {
        sheet.appendRow([
          TextCellValue(activity.username),
          TextCellValue(activity.userEmail),
          TextCellValue(activity.featureUsed),
          TextCellValue(_formatDate(activity.timestamp)),
          TextCellValue(_formatTime(activity.timestamp)),
        ]);
      }

      final bytes = excel.save();
      final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/analytics_$formattedDate.xlsx');
      await file.writeAsBytes(bytes!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File generated: ${file.path}')),
        );
      }

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the file')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel generation error: $e')),
        );
      }
    } finally {
      provider.setDownloading(false);
    }
  }

  Future<void> _showDownloadDialog(
    BuildContext context,
    List<Activity> activities,
    AppLocalizations locale,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(locale.confirmDownloadExcel),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(locale.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _downloadAsExcel(context, activities);
              },
              child: Text(locale.confirm),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    AnalyticsManagementProvider provider,
    AppLocalizations locale,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(locale.confirmDeleteAllActivities),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(locale.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await provider.deleteAllData();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? locale.allDataDeletedSuccessfully : locale.failedToDeleteAllData,
                    ),
                  ),
                );
              },
              child: Text(locale.confirm),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return ChangeNotifierProvider(
      create: (_) => AnalyticsManagementProvider(),
      child: Consumer<AnalyticsManagementProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(locale.analyticsManagement),
              backgroundColor: AppColors.background,
              actions: [
                IconButton(
                  onPressed: provider.isDownloading
                      ? null
                      : () => _showDownloadDialog(context, provider.activities, locale),
                  icon: provider.isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                ),
              ],
            ),
            body:
                SafeArea(bottom: Platform.isAndroid, child: _buildBody(context, provider, locale)),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AnalyticsManagementProvider provider,
    AppLocalizations locale,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.black12_400,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: provider.fetchActivities,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(locale.noActivitiesFound),
            const SizedBox(height: 10),
            TextButton(
              onPressed: provider.fetchActivities,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: _SummaryCard(
            totalActivities: provider.totalActivities,
            uniqueUsers: provider.uniqueUsersCount,
            latestActivity: provider.latestActivityTime,
            formatter: _formatDateTime,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.fetchActivities,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: provider.activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final activity = provider.activities[index];
                return _ActivityCard(
                  activity: activity,
                  dateText: _formatDate(activity.timestamp),
                  timeText: _formatTime(activity.timestamp),
                  timeAgo: _timeAgo(activity.timestamp),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IconButton(
            onPressed:
                provider.isDeleting ? null : () => _showDeleteDialog(context, provider, locale),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(56, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: provider.isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_forever, size: 26),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalActivities;
  final int uniqueUsers;
  final DateTime? latestActivity;
  final String Function(DateTime date) formatter;

  const _SummaryCard({
    required this.totalActivities,
    required this.uniqueUsers,
    required this.latestActivity,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.greyB2BACD.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricTile(label: 'Activities', value: '$totalActivities'),
          _MetricTile(label: 'Users', value: '$uniqueUsers'),
          _MetricTile(
            label: 'Latest',
            value: latestActivity == null ? '-' : formatter(latestActivity!),
            isSmall: true,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isSmall;

  const _MetricTile({
    required this.label,
    required this.value,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.black12_400.copyWith(color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: AppTextStyles.black14_600.copyWith(fontSize: isSmall ? 11 : 14),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final String dateText;
  final String timeText;
  final String timeAgo;

  const _ActivityCard({
    required this.activity,
    required this.dateText,
    required this.timeText,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final userName = activity.username;
    final userEmail = activity.userEmail.isNotEmpty ? activity.userEmail : 'No email';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: const Color(0xFFDCFCE7),
                  child: Text(initial, style: AppTextStyles.black14_600),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: AppTextStyles.black14_600),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: AppTextStyles.black12_400.copyWith(color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateText, style: AppTextStyles.black12_400.copyWith(color: Colors.grey)),
                    Text(timeText, style: AppTextStyles.black12_400.copyWith(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity.featureUsed.toUpperCase(),
                    style: AppTextStyles.black12_400.copyWith(
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: AppTextStyles.black12_400.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
