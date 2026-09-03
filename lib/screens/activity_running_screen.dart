import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_record.dart';
import '../models/phone_sensor_data.dart';
import '../providers/sensor_provider.dart';
import '../services/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'activity_summary_screen.dart';
import '../config/app_config.dart';

class ActivityRunningScreen extends StatefulWidget {
  final ActivityType activity;

  const ActivityRunningScreen({super.key, required this.activity});

  @override
  State<ActivityRunningScreen> createState() => _ActivityRunningScreenState();
}

class _ActivityRunningScreenState extends State<ActivityRunningScreen> {
  late DateTime _startTime;
  Duration _elapsed = Duration.zero;
  Duration _pausedElapsed = Duration.zero;
  Timer? _timer;
  bool _isPaused = false;
  final List<ActivityDataPoint> _dataPoints = [];
  Timer? _dataCollectionTimer;

  // Checkpoint state
  late String _currentActivityName;
  late String _currentActivityType;
  late String _currentActivityEnvironment;
  String? _currentActivityEmoji;
  late IconData _currentActivityIcon;
  bool _justCheckpointed = false;

  /// BLE slot numbers (1–4) required by this activity.
  late final Set<int> _requiredBleSlots;

  /// Whether this activity requires the smartphone sensor.
  late final bool _requiresSmartphone;

  @override
  void initState() {
    super.initState();
    // Derive required sensor sets from the activity definition.
    final bleSlots = <int>{};
    bool hasSmartphone = false;
    for (final s in widget.activity.requiredSensors) {
      final deviceName = s.sensorDevice;
      if (deviceName == 'smartphone') {
        hasSmartphone = true;
      } else if (deviceName != null && deviceName.startsWith('sensor')) {
        final slotNumber = int.tryParse(deviceName.substring(6));
        if (slotNumber != null && slotNumber >= 1 && slotNumber <= NUMBER_OF_SENSORS) {
          bleSlots.add(slotNumber);
        }
      }
    }
    _requiredBleSlots = bleSlots;
    _requiresSmartphone = hasSmartphone;

    // Initialize current activity from the passed widget
    _currentActivityName = widget.activity.name;
    _currentActivityType = widget.activity.isCustom
        ? widget.activity.name
        : widget.activity.id.split('_')[0];
    _currentActivityEnvironment = widget.activity.environment;
    _currentActivityEmoji = widget.activity.emoji;
    _currentActivityIcon = widget.activity.icon;

    _startTime = DateTime.now();
    _startTimer();
    _startDataCollection();
    // Start phone sensors only if this activity uses the smartphone.
    if (_requiresSmartphone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<SensorProvider>(
          context,
          listen: false,
        ).startPhoneSensorsForActivity();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dataCollectionTimer?.cancel();
    if (_requiresSmartphone) {
      Provider.of<SensorProvider>(context, listen: false).stopPhoneSensors();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsed = _pausedElapsed + DateTime.now().difference(_startTime);
        });
      }
    });
  }

  void _startDataCollection() {
    final provider = Provider.of<SensorProvider>(context, listen: false);

    _dataCollectionTimer = Timer.periodic(Duration(milliseconds: DATA_COLLECTION_INTERVAL_MS), (
      timer,
    ) {
      if (!_isPaused) {
        final sensors = <String, SensorSnapshot>{};

        // Dynamically collect data from all required BLE sensors
        for (final slotNumber in _requiredBleSlots) {
          final sensorData = provider.getSensorData(slotNumber);
          if (sensorData != null) {
            final slotId = 'sensor$slotNumber';
            sensors[slotId] = SensorSnapshot(
              accelX: sensorData.accelerationX,
              accelY: sensorData.accelerationY,
              accelZ: sensorData.accelerationZ,
              gyroX: sensorData.angularVelocityX,
              gyroY: sensorData.angularVelocityY,
              gyroZ: sensorData.angularVelocityZ,
              roll: sensorData.roll,
              pitch: sensorData.pitch,
              yaw: sensorData.yaw,
              quaternionW: sensorData.quaternionW,
              quaternionX: sensorData.quaternionX,
              quaternionY: sensorData.quaternionY,
              quaternionZ: sensorData.quaternionZ,
            );
          }
        }

        final phoneData =
            _requiresSmartphone ? provider.phoneSensorData : null;

        // Add a data point when there is at least one source of data.
        if (sensors.isNotEmpty || phoneData != null) {
          _dataPoints.add(
            ActivityDataPoint(
              timestamp: DateTime.now(),
              sensors: sensors,
              phoneSensors: phoneData,
            ),
          );
        }
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        // Pause: keep the elapsed shown on screen as the base for resume.
        _pausedElapsed = _elapsed;
      } else {
        // Resume: reset start time so the paused period is not counted.
        if (_justCheckpointed) {
          _elapsed = Duration.zero;
          _pausedElapsed = Duration.zero;
          _justCheckpointed = false;
        }
        _startTime = DateTime.now();
      }
    });
  }

  // ─── CHECKPOINT ──────────────────────────────────────────────────────

  void _showCheckpointModal() async {
    final builtInActivities = <_ActivityOption>[
      _ActivityOption(
        name: 'Caminhada Outdoor',
        type: 'walking',
        environment: 'outdoor',
        icon: Icons.directions_walk,
        emoji: null,
      ),
      _ActivityOption(
        name: 'Corrida Indoor',
        type: 'running',
        environment: 'indoor',
        icon: Icons.directions_run,
        emoji: null,
      ),
      _ActivityOption(
        name: 'Bicicleta Indoor',
        type: 'cycling',
        environment: 'indoor',
        icon: Icons.directions_bike,
        emoji: null,
      ),
    ];

    // Load custom activities from DB
    final customTypes = await DatabaseHelper.instance.getAllCustomActivityTypes();
    final customActivities = customTypes.map((ct) => _ActivityOption(
      name: ct.name,
      type: ct.name,
      environment: ct.environment,
      icon: Icons.category,
      emoji: ct.emoji,
    )).toList();

    final allOptions = [...builtInActivities, ...customActivities];

    if (!mounted) return;

    final selected = await showModalBottomSheet<_ActivityOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context).saveCheckpoint,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).selectActivityToSave,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: allOptions.length,
                    itemBuilder: (context, index) {
                      final option = allOptions[index];
                      final isCurrent = option.name == _currentActivityName;
                      return ListTile(
                        leading: option.emoji != null
                            ? Text(option.emoji!, style: const TextStyle(fontSize: 28))
                            : Icon(option.icon, size: 28, color: Theme.of(context).colorScheme.primary),
                        title: Text(
                          option.name,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: isCurrent
                            ? Text(
                                AppLocalizations.of(context).currentActivity,
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, option),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      _doCheckpoint(selected);
    }
  }

  Future<void> _doCheckpoint(_ActivityOption selected) async {
    // Pause data collection
    setState(() {
      _isPaused = true;
    });

    final provider = Provider.of<SensorProvider>(context, listen: false);

    // Build activity record from current segment
    final activityRecord = ActivityRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _currentActivityType,
      environment: _currentActivityEnvironment,
      startTime: _startTime,
      endTime: DateTime.now(),
      duration: _elapsed,
      dataPoints: List.from(_dataPoints),
      emoji: _currentActivityEmoji,
    );

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await provider.saveActivityRecord(activityRecord);

      if (mounted) {
        Navigator.pop(context); // close loading
      }

      // Reset for new segment
      setState(() {
        _currentActivityName = selected.name;
        _currentActivityType = selected.type;
        _currentActivityEnvironment = selected.environment;
        _currentActivityEmoji = selected.emoji;
        _currentActivityIcon = selected.icon;
        _startTime = DateTime.now();
        _elapsed = Duration.zero;
        _pausedElapsed = Duration.zero;
        _dataPoints.clear();
        _justCheckpointed = true;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkpointSaved(activityRecord.activityName)),
            backgroundColor: Colors.teal,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).errorSavingCheckpoint('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── FATIGUE LEVEL ────────────────────────────────────────────────────

  Future<void> _showFatigueLevelModal() async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fatigueLevel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.selectFatigueLevel),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var level = 0; level <= 4; level++)
                  ChoiceChip(
                    label: Text('$level'),
                    selected: false,
                    onSelected: (_) => Navigator.pop(context, level),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected == null) return;
    _applyFatigueLevel(selected);
  }

  void _applyFatigueLevel(int level) {
    var marked = 0;
    for (final point in _dataPoints) {
      // Only mark points not already marked (do not overwrite).
      if (point.fatigueLevel == null) {
        point.fatigueLevel = level;
        marked++;
      }
    }

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          marked > 0
              ? l10n.fatigueMarked(level, marked)
              : l10n.fatigueAlreadyMarked,
        ),
        backgroundColor: Colors.deepPurple,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── FINISH ──────────────────────────────────────────────────────────

  Future<void> _finishActivity() async {
    _timer?.cancel();
    _dataCollectionTimer?.cancel();

    final activityRecord = ActivityRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _currentActivityType,
      environment: _currentActivityEnvironment,
      startTime: _startTime,
      endTime: DateTime.now(),
      duration: _elapsed,
      dataPoints: _dataPoints,
      emoji: _currentActivityEmoji,
    );

    // Save to provider
    final provider = Provider.of<SensorProvider>(context, listen: false);

    // Show loading indicator while saving
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await provider.saveActivityRecord(activityRecord);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to summary
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActivitySummaryScreen(record: activityRecord),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).errorSavingActivity('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await _showExitDialog();
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentActivityName),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldExit = await _showExitDialog();
              if (shouldExit == true) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Column(
          children: [
            // Timer display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                children: [
                  if (_currentActivityEmoji != null)
                    Text(
                      _currentActivityEmoji!,
                      style: const TextStyle(fontSize: 48),
                    )
                  else
                    Icon(_currentActivityIcon, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  // Checkpoint / Fatigue level buttons (only visible when paused)
                  if (_isPaused)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showCheckpointModal,
                            icon: const Icon(Icons.bookmark_add, size: 20),
                            label: Text(l10n.checkpoint),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _showFatigueLevelModal,
                            icon: const Icon(Icons.battery_alert, size: 20),
                            label: Text(l10n.fatigueLevel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    _formatDuration(_elapsed),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isPaused ? l10n.paused.toUpperCase() : l10n.inProgress.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _isPaused ? Colors.orange : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Control buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? l10n.resume : l10n.pause),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _finishActivity,
                      icon: const Icon(Icons.stop),
                      label: Text(l10n.finish),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      l10n.dataPoints,
                      _dataPoints.length.toString(),
                      Icons.data_usage,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      l10n.activeSensors,
                      _dataPoints.isNotEmpty
                          ? (_dataPoints.last.sensors.length +
                                  (_requiresSmartphone &&
                                          _dataPoints.last.phoneSensors != null
                                      ? 1
                                      : 0))
                              .toString()
                          : '0',
                      Icons.sensors,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Real-time sensor visualization
            Expanded(
              child: Consumer<SensorProvider>(
                builder: (context, provider, child) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        l10n.realtimeSensors,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Generate sensor data cards dynamically
                      for (int i = 1; i <= NUMBER_OF_SENSORS; i++) ...[
                        if (provider.getSensorData(i) != null)
                          _buildSensorDataCard(
                              '${l10n.sensor} $i', provider.getSensorData(i)!),
                        const SizedBox(height: 12),
                      ],
                      if (_requiresSmartphone) ...[
                        provider.phoneSensorData != null
                            ? _buildPhoneSensorDataCard(
                                provider.phoneSensorData!,
                              )
                            : _buildWaitingCard(),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataCard(String label, dynamic sensorData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDataItem('Roll', sensorData.roll, Colors.red),
                ),
                Expanded(
                  child: _buildDataItem(
                    'Pitch',
                    sensorData.pitch,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDataItem('Yaw', sensorData.yaw, Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDataItem(
                    'Accel X',
                    sensorData.accelerationX,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    'Accel Y',
                    sensorData.accelerationY,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildDataItem(
                    'Accel Z',
                    sensorData.accelerationZ,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context).waitingPhoneData,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSensorDataCard(PhoneSensorData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smartphone, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).smartphone,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data.accelX != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDataItem(
                      'Acel X',
                      data.accelX ?? 0.0,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildDataItem(
                      'Acel Y',
                      data.accelY ?? 0.0,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildDataItem(
                      'Acel Z',
                      data.accelZ ?? 0.0,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (data.gyroX != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildDataItem(
                      'Giro X',
                      data.gyroX ?? 0.0,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildDataItem(
                      'Giro Y',
                      data.gyroY ?? 0.0,
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildDataItem(
                      'Giro Z',
                      data.gyroZ ?? 0.0,
                      Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<bool?> _showExitDialog() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitActivity),
        content: Text(
          l10n.exitActivityConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.exit),
          ),
        ],
      ),
    );
  }
}

/// Internal model for activity options in the checkpoint modal.
class _ActivityOption {
  final String name;
  final String type;
  final String environment;
  final IconData icon;
  final String? emoji;

  const _ActivityOption({
    required this.name,
    required this.type,
    required this.environment,
    required this.icon,
    this.emoji,
  });
}
