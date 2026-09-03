import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'phone_sensors_screen.dart';
import '../config/app_config.dart';
import '../models/activity_record.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        final l10n = AppLocalizations.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Generate sensor cards dynamically based on NUMBER_OF_SENSORS
            for (int i = 1; i <= NUMBER_OF_SENSORS; i++) ...[
              _buildSensorCard(
                context,
                provider,
                sensorNumber: i,
                label: '${l10n.sensor} $i',
                state: provider.getSensorState(i),
                l10n: l10n,
                onDisconnect: () async {
                  await provider.disconnectSensor(i);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.sensorDisconnected(i))),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Language Section
            Consumer<LocaleProvider>(
              builder: (context, localeProvider, _) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      l10n.language,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(l10n.languageDescription),
                    trailing: DropdownButton<String>(
                      value: localeProvider.isEnglish ? 'en' : 'pt_BR',
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'pt_BR',
                          child: Text('Português'),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          localeProvider.setLocale(value);
                        }
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Phone Sensors Section
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.phone_android,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  l10n.smartphoneSensors,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Builder(
                  builder: (_) {
                    final settings = provider.phoneSensorSettings;
                    if (!settings.anyEnabled) {
                      return Text(l10n.noSensorEnabled);
                    }
                    final active = <String>[];
                    if (settings.accelerometerEnabled) active.add(l10n.accelerometer);
                    if (settings.gyroscopeEnabled) active.add(l10n.gyroscope);
                    if (settings.magnetometerEnabled) active.add(l10n.magnetometer);
                    if (settings.gpsEnabled) active.add(l10n.gps);
                    if (settings.barometerEnabled) active.add(l10n.barometer);
                    return Text(active.join(' · '));
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PhoneSensorsScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Trash Section
            const TrashSection(),

            const SizedBox(height: 16),

            // About Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.about,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(l10n.application, 'AI Wearable Sensor'),
                    const SizedBox(height: 8),
                    _buildInfoRow(l10n.version, '1.0.0'),
                    const SizedBox(height: 8),
                    _buildInfoRow(l10n.sensor, 'WT9011DCL-BT50'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensorCard(
    BuildContext context,
    SensorProvider provider, {
    required int sensorNumber,
    required String label,
    required state,
    required AppLocalizations l10n,
    required Future<void> Function() onDisconnect,
  }) {
    final connected = state.status == 'Conectado';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: connected ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.status,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (state.deviceName != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(l10n.device, state.deviceName!),
            ],
            if (connected) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.battery,
                      style: const TextStyle(color: Colors.grey)),
                  state.batteryLevel != null
                      ? Row(
                          children: [
                            Icon(
                              _batteryIcon(state.batteryLevel!),
                              size: 18,
                              color: _batteryColor(state.batteryLevel!),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${state.batteryLevel}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _batteryColor(state.batteryLevel!),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 60,
                              child: LinearProgressIndicator(
                                value: state.batteryLevel! / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: AlwaysStoppedAnimation(
                                  _batteryColor(state.batteryLevel!),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          '--',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                ],
              ),
            ],
            if (connected) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: onDisconnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.disconnect),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _batteryIcon(int level) {
    if (level >= 80) return Icons.battery_full;
    if (level >= 60) return Icons.battery_5_bar;
    if (level >= 40) return Icons.battery_4_bar;
    if (level >= 20) return Icons.battery_3_bar;
    if (level >= 10) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _batteryColor(int level) {
    if (level >= 60) return Colors.green;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }
}

class TrashSection extends StatefulWidget {
  const TrashSection({super.key});

  @override
  State<TrashSection> createState() => _TrashSectionState();
}

class _TrashSectionState extends State<TrashSection> {
  bool _expanded = false;
  String? _expandedItemId;

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final l10n = AppLocalizations.of(context);
        final items = provider.trashItems;

        return Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  l10n.trash,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: items.isEmpty
                    ? Text(l10n.trashEmpty)
                    : Text('${items.length} ${l10n.itemsInTrash}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (items.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            _expanded = !_expanded;
                          });
                        },
                        tooltip: _expanded ? 'Collapse' : 'Expand',
                      ),
                    if (items.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: () => _confirmClearTrash(context, l10n, provider),
                        tooltip: l10n.clearTrash,
                      ),
                  ],
                ),
              ),
              if (_expanded && items.isNotEmpty)
                ...items.map((item) => _buildTrashItem(
                  context,
                  item,
                  l10n,
                  provider,
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrashItem(
    BuildContext context,
    Map<String, dynamic> item,
    AppLocalizations l10n,
    SensorProvider provider,
  ) {
    final activityMap = jsonDecode(item['activityJson'] as String) as Map<String, dynamic>;
    final record = ActivityRecord.fromJson(activityMap);
    final deletedAt = DateTime.parse(item['deletedAt'] as String);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isExpanded = _expandedItemId == item['id'];

    return Column(
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: () {
            setState(() {
              _expandedItemId = isExpanded ? null : item['id'] as String;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record.emoji ?? ''} ${record.activityName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.deletedAt}: ${dateFormat.format(deletedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.restore, size: 18),
                  label: Text(l10n.restore),
                  onPressed: () async {
                    await provider.restoreFromTrash(item['id'] as String);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.restoredSuccessfully)),
                    );
                  },
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: Text(l10n.deleteLabel),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _confirmDeleteSingle(context, l10n, provider, item),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _confirmClearTrash(
    BuildContext context,
    AppLocalizations l10n,
    SensorProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearTrash),
        content: Text(l10n.clearTrashConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.clearTrash),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.clearTrash();
      if (!mounted) return;
      setState(() {
        _expanded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trashClearedSuccessfully)),
      );
    }
  }

  Future<void> _confirmDeleteSingle(
    BuildContext context,
    AppLocalizations l10n,
    SensorProvider provider,
    Map<String, dynamic> item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteLabel),
        content: Text(l10n.clearTrashConfirmSingle),
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

    if (confirmed == true) {
      await provider.permanentlyDeleteFromTrash(item['id'] as String);
    }
  }
}

