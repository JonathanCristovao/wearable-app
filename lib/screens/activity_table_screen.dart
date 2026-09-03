import 'package:flutter/material.dart';
import '../models/activity_record.dart';
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';

/// Shows every data point of an activity as a table, mirroring the columns
/// that are exported to CSV.
class ActivityTableScreen extends StatefulWidget {
  final ActivityRecord record;

  const ActivityTableScreen({super.key, required this.record});

  @override
  State<ActivityTableScreen> createState() => _ActivityTableScreenState();
}

class _ActivityTableScreenState extends State<ActivityTableScreen> {
  static const double _cellWidth = 130;
  static const double _rowHeight = 36;

  final ScrollController _horizontalController = ScrollController();

  late final List<String> _headers;
  late final List<List<String>> _rows;

  @override
  void initState() {
    super.initState();
    _headers = _buildHeaders();
    _rows = _buildRows();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  /// Builds the same header as the CSV export.
  List<String> _buildHeaders() {
    final headers = <String>[
      'user-id',
      'user-name',
      'timestamp',
      'activity_name',
      'activity_type',
      'activity_environment',
      'f-level',
    ];

    for (int i = 1; i <= NUMBER_OF_SENSORS; i++) {
      headers.addAll([
        'sensor${i}_accelX',
        'sensor${i}_accelY',
        'sensor${i}_accelZ',
        'sensor${i}_gyroX',
        'sensor${i}_gyroY',
        'sensor${i}_gyroZ',
        'sensor${i}_roll',
        'sensor${i}_pitch',
        'sensor${i}_yaw',
        'sensor${i}_quatW',
        'sensor${i}_quatX',
        'sensor${i}_quatY',
        'sensor${i}_quatZ',
      ]);
    }

    headers.addAll([
      'phone_accelX',
      'phone_accelY',
      'phone_accelZ',
      'phone_gyroX',
      'phone_gyroY',
      'phone_gyroZ',
      'phone_magX',
      'phone_magY',
      'phone_magZ',
    ]);

    return headers;
  }

  /// Builds the data rows, mirroring the CSV export.
  List<List<String>> _buildRows() {
    final rows = <List<String>>[];
    final record = widget.record;

    DateTime currentTime = record.startTime;
    final dataInterval = Duration(milliseconds: DATA_COLLECTION_INTERVAL_MS);

    for (final dataPoint in record.dataPoints) {
      final row = <String>[
        record.userId ?? '',
        record.userName ?? '',
        currentTime.toIso8601String(),
        record.activityName,
        record.type,
        record.environment,
        dataPoint.fatigueLevel?.toString() ?? '',
      ];
      currentTime = currentTime.add(dataInterval);

      for (int i = 1; i <= NUMBER_OF_SENSORS; i++) {
        final sensor = dataPoint.sensors['sensor$i'];
        if (sensor != null) {
          row.addAll([
            _fmt(sensor.accelX),
            _fmt(sensor.accelY),
            _fmt(sensor.accelZ),
            _fmt(sensor.gyroX),
            _fmt(sensor.gyroY),
            _fmt(sensor.gyroZ),
            _fmt(sensor.roll),
            _fmt(sensor.pitch),
            _fmt(sensor.yaw),
            _fmt(sensor.quaternionW),
            _fmt(sensor.quaternionX),
            _fmt(sensor.quaternionY),
            _fmt(sensor.quaternionZ),
          ]);
        } else {
          row.addAll(List.filled(13, ''));
        }
      }

      final phone = dataPoint.phoneSensors;
      if (phone != null) {
        row.addAll([
          _fmt(phone.accelX),
          _fmt(phone.accelY),
          _fmt(phone.accelZ),
          _fmt(phone.gyroX),
          _fmt(phone.gyroY),
          _fmt(phone.gyroZ),
          _fmt(phone.magX),
          _fmt(phone.magY),
          _fmt(phone.magZ),
        ]);
      } else {
        row.addAll(List.filled(9, ''));
      }

      rows.add(row);
    }

    return rows;
  }

  String _fmt(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(3);
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = _cellWidth * _headers.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).dataTable),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)
                  .columnsRows(_headers.length, _rows.length),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(height: 1),
          // Header and data rows scroll together, vertically and horizontally.
          // Rows are built lazily (ListView.builder) to avoid jank with large
          // data sets.
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: ListView.builder(
                  itemCount: _rows.isEmpty ? 2 : _rows.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeaderRow();
                    if (_rows.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(AppLocalizations.of(context).noDataToDisplay),
                      );
                    }
                    return _buildDataRow(_rows[index - 1], index - 1);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        for (final header in _headers)
          Container(
            width: _cellWidth,
            height: _rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF37474F),
              border: Border(
                right: BorderSide(color: Colors.black12),
                bottom: BorderSide(color: Colors.black12),
              ),
            ),
            child: Text(
              header,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildDataRow(List<String> row, int index) {
    final isAlternate = index.isOdd;
    return Row(
      children: [
        for (final value in row)
          Container(
            width: _cellWidth,
            height: _rowHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: isAlternate ? const Color(0xFFECEFF1) : Colors.white,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
