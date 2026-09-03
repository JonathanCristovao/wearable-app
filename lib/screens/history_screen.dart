import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_record.dart';
import '../models/user_profile.dart';
import '../providers/sensor_provider.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart';
import 'activity_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filterUserId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final provider = Provider.of<SensorProvider>(context, listen: false);
      _filterUserId = provider.selectedUser?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).history),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<SensorProvider>(
            builder: (context, provider, _) {
              final hasRecords = provider.activityRecords.isNotEmpty;
              return IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: AppLocalizations.of(context).saveAll,
                onPressed: hasRecords
                    ? () => _exportAll(context, provider)
                    : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = provider.users;
          final allRecords = provider.activityRecords;

          // If the filtered user no longer exists, reset to all
          if (_filterUserId != null &&
              !users.any((u) => u.id == _filterUserId)) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _filterUserId = null),
            );
          }

          final records = _filterUserId == null
              ? allRecords
              : allRecords.where((r) => r.userId == _filterUserId).toList();

          return Column(
            children: [
              if (users.isNotEmpty) _buildUserFilter(users),
              Expanded(
                child: records.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[records.length - 1 - index];
                          return _buildActivityCard(
                            context,
                            record,
                            provider.users,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserFilter(List<UserProfile> users) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(AppLocalizations.of(context).all),
                selected: _filterUserId == null,
                onSelected: (_) => setState(() => _filterUserId = null),
              ),
            ),
            ...users.map(
              (user) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: CircleAvatar(
                    radius: 10,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  label: Text(user.name),
                  selected: _filterUserId == user.id,
                  onSelected: (_) =>
                      setState(() => _filterUserId = user.id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noActivityRecorded,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _filterUserId != null
                ? AppLocalizations.of(context).userNoActivities
                : AppLocalizations.of(context).completeActivityToSeeHistory,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    ActivityRecord record,
    List<UserProfile> users,
  ) {
    final l10n = AppLocalizations.of(context);
    IconData? icon;
    Color color;
    final hasEmoji = record.emoji != null;

    if (hasEmoji) {
      icon = null;
      color = Colors.blue;
    } else if (record.type == 'walking') {
      icon = Icons.directions_walk;
      color = Colors.green;
    } else if (record.type == 'running') {
      icon = Icons.directions_run;
      color = Colors.orange;
    } else {
      icon = Icons.directions_bike;
      color = Colors.blue;
    }

    UserProfile? recordUser;
    if (record.userId != null) {
      try {
        recordUser = users.firstWhere((u) => u.id == record.userId);
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailScreen(record: record),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: hasEmoji
                    ? Text(record.emoji!, style: const TextStyle(fontSize: 28))
                    : Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.activityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          record.formattedDuration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(record.startTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.data_usage,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)
                              .dataPointsCount(record.dataPoints.length),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (_filterUserId == null && recordUser != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recordUser.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Colors.grey[400],
                ),
                onSelected: (value) {
                  if (value == 'details') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailScreen(record: record),
                      ),
                    );
                  } else if (value == 'upload') {
                    _uploadToFirebase(context, record);
                  } else if (value == 'delete') {
                    _confirmDelete(context, record);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(l10n.viewDetails),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'upload',
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(l10n.sendToFirebase),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.deleteActivityLabel,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadToFirebase(
    BuildContext context,
    ActivityRecord record,
  ) async {
    final l10n = AppLocalizations.of(context);
    final auth = AuthService();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(l10n.sendingToFirebase),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    try {
      await auth.signInAnonymously();

      final uid = auth.uid;
      if (uid == null) throw Exception('Usuário não autenticado.');

      final doc = FirebaseFirestore.instance
          .collection('activities')
          .doc(uid)
          .collection('records')
          .doc(record.id);

      await doc.set({
        'id': record.id,
        'type': record.type,
        'environment': record.environment,
        'activityName': record.activityName,
        'startTime': record.startTime.toIso8601String(),
        'endTime': record.endTime.toIso8601String(),
        'durationSeconds': record.duration.inSeconds,
        'dataPointsCount': record.dataPoints.length,
        if (record.userId != null) 'userId': record.userId,
        if (record.userName != null) 'userName': record.userName,
        if (record.emoji != null) 'emoji': record.emoji,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.activitySentSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSending('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ActivityRecord record,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteActivityLabel),
        content: Text(l10n.deleteActivityConfirmTitle(record.activityName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteLabel),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final provider = Provider.of<SensorProvider>(context, listen: false);
      await provider.deleteActivityRecord(record.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.movedToTrash)),
        );
      }
    }
  }

  Future<void> _exportAll(
    BuildContext context,
    SensorProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final records = provider.activityRecords;
    final users = provider.users;

    if (records.isEmpty) return;

    // Show progress indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(l10n.generatingZip),
            ],
          ),
          duration: const Duration(seconds: 60),
        ),
      );
    }

    try {
      await ExportService.exportAllActivities(
        records: records,
        users: users,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorExporting('$e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
