import 'package:flutter/material.dart';
import '../models/activity_record.dart';
import '../services/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'activity_check_screen.dart';
import 'activity_config_screen.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<ActivityType> _customActivities = [];
  bool _isLoadingCustom = true;

  @override
  void initState() {
    super.initState();
    _loadCustomActivities();
  }

  Future<void> _loadCustomActivities() async {
    final activities = await DatabaseHelper.instance.getAllCustomActivityTypes();
    if (mounted) {
      setState(() {
        _customActivities = activities;
        _isLoadingCustom = false;
      });
    }
  }

  Future<void> _openConfigScreen([ActivityType? toEdit]) async {
    final result = await Navigator.push<ActivityType>(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityConfigScreen(activityToEdit: toEdit),
      ),
    );
    if (result != null) {
      _loadCustomActivities();
    }
  }

  Future<void> _duplicateCustomActivity(ActivityType activity) async {
    final duplicated = ActivityType(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: '${activity.name}-copy',
      environment: activity.environment,
      icon: activity.icon,
      emoji: activity.emoji,
      isCustom: true,
      requiredSensors: activity.requiredSensors,
    );
    await DatabaseHelper.instance.saveCustomActivityType(duplicated);
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.activityCreated(duplicated.name))),
      );
    }
    _loadCustomActivities();
  }

  Future<void> _deleteCustomActivity(ActivityType activity) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteActivity),
        content: Text(
          l10n.deleteActivityConfirm(activity.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.instance.deleteCustomActivityType(activity.id);
      _loadCustomActivities();
    }
  }

  static final List<ActivityType> _builtinActivities = [
    ActivityType(
      id: 'walking_outdoor',
      name: 'Caminhada Outdoor',
      environment: 'outdoor',
      icon: Icons.directions_walk,
      requiredSensors: [
        SensorPosition(
          id: 'left_thigh',
          name: 'Coxa Esquerda',
          description: 'Sensor posicionado na parte superior da coxa esquerda',
        ),
        SensorPosition(
          id: 'right_thigh',
          name: 'Coxa Direita',
          description: 'Sensor posicionado na parte superior da coxa direita',
        ),
        SensorPosition(
          id: 'left_shin',
          name: 'Canela Esquerda',
          description: 'Sensor posicionado na parte inferior da perna esquerda',
        ),
        SensorPosition(
          id: 'right_shin',
          name: 'Canela Direita',
          description: 'Sensor posicionado na parte inferior da perna direita',
        ),
      ],
    ),
    ActivityType(
      id: 'running_indoor',
      name: 'Corrida Indoor',
      environment: 'indoor',
      icon: Icons.directions_run,
      requiredSensors: [
        SensorPosition(
          id: 'left_thigh',
          name: 'Coxa Esquerda',
          description: 'Sensor posicionado na parte superior da coxa esquerda',
        ),
        SensorPosition(
          id: 'right_thigh',
          name: 'Coxa Direita',
          description: 'Sensor posicionado na parte superior da coxa direita',
        ),
        SensorPosition(
          id: 'left_shin',
          name: 'Canela Esquerda',
          description: 'Sensor posicionado na parte inferior da perna esquerda',
        ),
        SensorPosition(
          id: 'right_shin',
          name: 'Canela Direita',
          description: 'Sensor posicionado na parte inferior da perna direita',
        ),
      ],
    ),
    ActivityType(
      id: 'cycling_indoor',
      name: 'Bicicleta Indoor',
      environment: 'indoor',
      icon: Icons.directions_bike,
      requiredSensors: [
        SensorPosition(
          id: 'left_thigh',
          name: 'Coxa Esquerda',
          description: 'Sensor posicionado na parte superior da coxa esquerda',
        ),
        SensorPosition(
          id: 'right_thigh',
          name: 'Coxa Direita',
          description: 'Sensor posicionado na parte superior da coxa direita',
        ),
        SensorPosition(
          id: 'left_shin',
          name: 'Canela Esquerda',
          description: 'Sensor posicionado na parte inferior da perna esquerda',
        ),
        SensorPosition(
          id: 'right_shin',
          name: 'Canela Direita',
          description: 'Sensor posicionado na parte inferior da perna direita',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activities),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.chooseActivity,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectActivityType,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // ---- Built-in activities ----
          Text(
            l10n.standardActivities,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._builtinActivities.map(
            (activity) => _buildActivityCard(context, activity),
          ),
          const SizedBox(height: 8),

          // ---- Custom activities ----
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.myActivities,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openConfigScreen(),
                icon: const Icon(Icons.add),
                label: Text(l10n.newActivity),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingCustom)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_customActivities.isEmpty)
            _buildAddActivityCard(context)
          else ...[
            ..._customActivities.map(
              (activity) => _buildCustomActivityCard(context, activity),
            ),
            const SizedBox(height: 8),
            _buildAddActivityCard(context),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAddActivityCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 1.5,
          // ignore: deprecated_member_use
        ),
      ),
      child: InkWell(
        onTap: () => _openConfigScreen(),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.configureNewActivity,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createCustomActivity,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, ActivityType activity) {
    final l10n = AppLocalizations.of(context);
    Color cardColor;
    Color iconColor;

    if (activity.id.contains('walking')) {
      cardColor = Colors.green.shade50;
      iconColor = Colors.green;
    } else if (activity.id.contains('running')) {
      cardColor = Colors.orange.shade50;
      iconColor = Colors.orange;
    } else {
      cardColor = Colors.blue.shade50;
      iconColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityCheckScreen(activity: activity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cardColor,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(activity.icon, size: 32, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activity.requiredSensors.length} ${l10n.sensors}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                activity.environment == 'indoor'
                    ? Icons.home
                    : Icons.outdoor_grill,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomActivityCard(BuildContext context, ActivityType activity) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityCheckScreen(activity: activity),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  activity.emoji ?? '🏃',
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSensorSummary(activity, l10n),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openConfigScreen(activity);
                  } else if (value == 'duplicate') {
                    _duplicateCustomActivity(activity);
                  } else if (value == 'delete') {
                    _deleteCustomActivity(activity);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        const Icon(Icons.copy_outlined),
                        const SizedBox(width: 8),
                        Text(l10n.duplicate),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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

  String _buildSensorSummary(ActivityType activity, AppLocalizations l10n) {
    if (activity.requiredSensors.isEmpty) return l10n.noSensorsConfigured;
    final count = activity.requiredSensors.length;
    final positions = activity.requiredSensors
        .map((s) => s.name)
        .take(2)
        .join(', ');
    final suffix = count > 2 ? ' +${count - 2}' : '';
    return '$count ${l10n.sensor}${count > 1 ? 's' : ''}: $positions$suffix';
  }
}

