import 'package:flutter/material.dart';
import '../models/activity_record.dart';
import '../services/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../config/app_config.dart';

const List<String> _activityEmojis = [
  '🏃',
  '🚶',
  '🚴',
  '🏋️',
  '🧍‍♂️',
  '🧎‍♂️',
  '🎾',
  '🏊',
  '🧘',
  '🤸',
  '🥊',
  '🎿',
  '🏄',
  '🏌️',
  '🧗',
  '🎯',
  '💪',
  '⛹️',
  '🎽',
  '🥋',
  '🤼',
  '🤾',
  '🤽',
  '🏂',
  '🪂',
  '🚣',
  '🏆',
  '🛌',
  '🔥',
  '💨',
  '🌟',
  '❤️',
  '🦵',
  '🦶',
  '🏅',
  '🧗♀️',
  '🤿',
  '⛷️',
  '🛷',
  '🏍️',
  '🚴♀️',
  '🚵',
  '🏃‍♀️',
  '🚶‍♀️',
  '🏊‍♂️',
  '🚣‍♀️',
  '🏌️‍♀️',
  '🤾‍♂️',
  '🤺',
];

List<String> _translatedBodyPositions(AppLocalizations l10n) => [
  l10n.positionThorax,
  l10n.positionAbdomen,
  l10n.positionBack,
  l10n.positionHead,
  l10n.positionLeftShoulder,
  l10n.positionRightShoulder,
  l10n.positionLeftArm,
  l10n.positionRightArm,
  l10n.positionLeftForearm,
  l10n.positionRightForearm,
  l10n.positionLeftWrist,
  l10n.positionRightWrist,
  l10n.positionLeftThigh,
  l10n.positionRightThigh,
  l10n.positionLeftShin,
  l10n.positionRightShin,
  l10n.positionLeftCalf,
  l10n.positionRightCalf,
  l10n.positionLeftAnkle,
  l10n.positionRightAnkle,
  l10n.positionLeftFoot,
  l10n.positionRightFoot,
];

/// Generate sensor device list dynamically based on NUMBER_OF_SENSORS
List<Map<String, String>> _getSensorDevices() {
  final devices = <Map<String, String>>[
    {'value': 'smartphone', 'label': 'Smartphone', 'emoji': '📱'},
  ];
  for (int i = 1; i <= NUMBER_OF_SENSORS; i++) {
    devices.add({'value': 'sensor$i', 'label': 'Sensor $i', 'emoji': '🔵'});
  }
  return devices;
}

class _SensorEntryData {
  final TextEditingController nameController;
  String sensorDevice;

  _SensorEntryData({String name = '', this.sensorDevice = 'sensor1'})
    : nameController = TextEditingController(text: name);

  factory _SensorEntryData.fromSensorPosition(SensorPosition pos) {
    return _SensorEntryData(
      name: pos.name,
      sensorDevice: pos.sensorDevice ?? 'sensor1',
    );
  }

  void dispose() {
    nameController.dispose();
  }
}

class ActivityConfigScreen extends StatefulWidget {
  final ActivityType? activityToEdit;

  const ActivityConfigScreen({super.key, this.activityToEdit});

  @override
  State<ActivityConfigScreen> createState() => _ActivityConfigScreenState();
}

class _ActivityConfigScreenState extends State<ActivityConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedEmoji = '🏃';
  final List<_SensorEntryData> _sensors = [];
  bool _isSaving = false;

  bool get _isEditing => widget.activityToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final a = widget.activityToEdit!;
      _nameController.text = a.name;
      _selectedEmoji = a.emoji ?? '🏃';
      for (final s in a.requiredSensors) {
        _sensors.add(_SensorEntryData.fromSensorPosition(s));
      }
    } else {
      _sensors.add(_SensorEntryData());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final s in _sensors) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).chooseEmoji,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _activityEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _activityEmojis[index];
                  return InkWell(
                    onTap: () => Navigator.pop(context, emoji),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: emoji == _selectedEmoji
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() => _selectedEmoji = result);
    }
  }

  void _addSensor() {
    setState(() {
      _sensors.add(_SensorEntryData());
    });
  }

  void _removeSensor(int index) {
    setState(() {
      _sensors[index].dispose();
      _sensors.removeAt(index);
    });
  }

  Future<void> _saveActivity() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sensors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).addAtLeastOneSensor),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final id = _isEditing
        ? widget.activityToEdit!.id
        : 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final requiredSensors = <SensorPosition>[];
    for (int i = 0; i < _sensors.length; i++) {
      final s = _sensors[i];
      final device = s.sensorDevice;
      final posName = s.nameController.text.trim();
      final deviceLabel = _getSensorDevices().firstWhere(
        (d) => d['value'] == device,
      )['label']!;
      requiredSensors.add(
        SensorPosition(
          id: '${device}_$i',
          name: posName,
          description: '$deviceLabel posicionado: $posName',
          sensorDevice: device,
        ),
      );
    }

    final activityType = ActivityType(
      id: id,
      name: _nameController.text.trim(),
      environment: 'custom',
      icon: Icons.category,
      emoji: _selectedEmoji,
      isCustom: true,
      requiredSensors: requiredSensors,
    );

    try {
      await DatabaseHelper.instance.saveCustomActivityType(activityType);
      if (mounted) {
        Navigator.pop(context, activityType);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorSaving('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editActivity : l10n.newActivityTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Emoji + Name ----
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.identification,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Emoji picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickEmoji,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _pickEmoji,
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(l10n.changeEmoji),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.activityName,
                        hintText: l10n.activityNameHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.enterActivityName;
                        }
                        if (v.trim().length < 2) {
                          return l10n.nameTooShort;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Sensors section ----
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.requiredSensors,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSensor,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_sensors.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.orange.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sensors_off,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noSensorAdded,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _addSensor,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addSensor),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_sensors.length, (index) {
                return _buildSensorCard(index);
              }),

            const SizedBox(height: 8),
            if (_sensors.isNotEmpty)
              OutlinedButton.icon(
                onPressed: _addSensor,
                icon: const Icon(Icons.add),
                label: Text(l10n.addAnotherSensor),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

            const SizedBox(height: 24),

            // ---- Save button ----
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveActivity,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isEditing ? l10n.saveChanges : l10n.createActivity,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(int index) {
    final sensor = _sensors[index];
    final l10n = AppLocalizations.of(context);
    final bodyPositions = _translatedBodyPositions(l10n);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${l10n.sensor} ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _removeSensor(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: l10n.removeSensor,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Device dropdown
            DropdownButtonFormField<String>(
              value: sensor.sensorDevice,
              decoration: InputDecoration(
                labelText: l10n.device,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.device_hub),
              ),
              items: _getSensorDevices().map((device) {
                return DropdownMenuItem(
                  value: device['value'],
                  child: Text(
                    '${device['emoji']}  ${device['label']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => sensor.sensorDevice = value);
                }
              },
            ),
            const SizedBox(height: 12),

            // Position text field
            TextFormField(
              controller: sensor.nameController,
              decoration: InputDecoration(
                labelText: l10n.position,
                hintText: l10n.positionHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.place_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.enterPosition;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Quick-select body position chips
            Text(
              '${l10n.quickPositions}:',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: bodyPositions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final pos = bodyPositions[i];
                  return ActionChip(
                    label: Text(pos, style: const TextStyle(fontSize: 12)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      setState(() {
                        sensor.nameController.text = pos;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
