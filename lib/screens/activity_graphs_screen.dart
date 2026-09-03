import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/activity_record.dart';
import '../l10n/app_localizations.dart';

class ActivityGraphsScreen extends StatefulWidget {
  final ActivityRecord record;

  const ActivityGraphsScreen({super.key, required this.record});

  @override
  State<ActivityGraphsScreen> createState() => _ActivityGraphsScreenState();
}

class _ActivityGraphsScreenState extends State<ActivityGraphsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedSensor = 'sensor1';
  late TabController _tabController;

  // ── Wearable helpers ──────────────────────────────────────────────────────

  List<String> get _availableSensors {
    if (widget.record.dataPoints.isEmpty) return [];
    return widget.record.dataPoints.first.sensors.keys.toList();
  }

  // ── Phone-sensor helpers ──────────────────────────────────────────────────

  bool get _hasPhoneSensorData =>
      widget.record.dataPoints.any((dp) => dp.phoneSensors != null);

  bool _phoneFieldHasData(String field) =>
      _getPhoneDataForField(field).isNotEmpty;

  List<FlSpot> _getPhoneDataForField(String field) {
    final spots = <FlSpot>[];
    double time = 0;
    for (final dp in widget.record.dataPoints) {
      final ps = dp.phoneSensors;
      if (ps != null) {
        double? v;
        switch (field) {
          case 'accelX':
            v = ps.accelX;
            break;
          case 'accelY':
            v = ps.accelY;
            break;
          case 'accelZ':
            v = ps.accelZ;
            break;
          case 'gyroX':
            v = ps.gyroX;
            break;
          case 'gyroY':
            v = ps.gyroY;
            break;
          case 'gyroZ':
            v = ps.gyroZ;
            break;
          case 'magX':
            v = ps.magX;
            break;
          case 'magY':
            v = ps.magY;
            break;
          case 'magZ':
            v = ps.magZ;
            break;
          case 'gpsSpeed':
            v = ps.gpsSpeed != null ? ps.gpsSpeed! * 3.6 : null; // m/s → km/h
            break;
          case 'altitude':
            v = ps.altitude;
            break;
          case 'pressure':
            v = ps.barometricPressure;
            break;
        }
        if (v != null && v.isFinite) spots.add(FlSpot(time, v));
        time += 0.1;
      }
    }
    return spots;
  }

  // ── GPS helpers ───────────────────────────────────────────────────────────

  List<LatLng> get _gpsPoints {
    final pts = <LatLng>[];
    for (final dp in widget.record.dataPoints) {
      final ps = dp.phoneSensors;
      if (ps != null &&
          ps.latitude != null &&
          ps.longitude != null &&
          ps.latitude!.isFinite &&
          ps.longitude!.isFinite) {
        pts.add(LatLng(ps.latitude!, ps.longitude!));
      }
    }
    return pts;
  }

  bool get _hasGpsData => _gpsPoints.isNotEmpty;

  double _totalDistanceKm(List<LatLng> pts) {
    double total = 0;
    const dist = Distance();
    for (int i = 1; i < pts.length; i++) {
      total += dist.as(LengthUnit.Kilometer, pts[i - 1], pts[i]);
    }
    return total;
  }

  LatLngBounds? _bounds(List<LatLng> pts) {
    if (pts.isEmpty) return null;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    // Degenerate bounds (all points identical or collinear) cause CameraFit
    // to compute an infinite zoom, triggering a NaN/Infinity toInt() crash.
    if (maxLat == minLat || maxLng == minLng) return null;
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
  }

  // ── Wearable chart data ───────────────────────────────────────────────────

  List<FlSpot> _getDataForAxis(String axis) {
    final spots = <FlSpot>[];
    double time = 0;
    for (final dp in widget.record.dataPoints) {
      final sensor = dp.sensors[_selectedSensor];
      if (sensor != null) {
        double v;
        switch (axis) {
          case 'accelX':
            v = sensor.accelX;
            break;
          case 'accelY':
            v = sensor.accelY;
            break;
          case 'accelZ':
            v = sensor.accelZ;
            break;
          case 'gyroX':
            v = sensor.gyroX;
            break;
          case 'gyroY':
            v = sensor.gyroY;
            break;
          case 'gyroZ':
            v = sensor.gyroZ;
            break;
          case 'roll':
            v = sensor.roll;
            break;
          case 'pitch':
            v = sensor.pitch;
            break;
          case 'yaw':
            v = sensor.yaw;
            break;
          default:
            v = 0;
        }
        spots.add(FlSpot(time, v));
        time += 0.1;
      }
    }
    return spots;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (_availableSensors.isNotEmpty) {
      _selectedSensor = _availableSensors.first;
    }
    int tabCount = 0;
    if (_availableSensors.isNotEmpty) tabCount++;
    if (_hasPhoneSensorData) tabCount++;
    if (_hasGpsData) tabCount++;
    if (tabCount == 0) tabCount = 1;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = <Tab>[];
    final views = <Widget>[];

    if (_availableSensors.isNotEmpty) {
      tabs.add(Tab(icon: const Icon(Icons.watch), text: l10n.wearable));
      views.add(_buildWearableTab());
    }
    if (_hasPhoneSensorData) {
      tabs.add(Tab(icon: const Icon(Icons.smartphone), text: l10n.smartphone));
      views.add(_buildPhoneTab());
    }
    if (_hasGpsData) {
      tabs.add(Tab(icon: const Icon(Icons.map), text: l10n.gpsMapTab));
      views.add(_buildMapTab());
    }
    if (tabs.isEmpty) {
      tabs.add(Tab(text: l10n.chartsTab));
      views.add(Center(child: Text(l10n.noData)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activityGraphs),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: views,
      ),
    );
  }

  // ── Wearable Tab ──────────────────────────────────────────────────────────

  Widget _buildWearableTab() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectSensor,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSensors.map((sensor) {
                      final isSelected = sensor == _selectedSensor;
                      return ChoiceChip(
                        label: Text(sensor.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedSensor = sensor);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _chartSection(
            l10n.accelerationG,
            _buildLineChart(
              [
                _getDataForAxis('accelX'),
                _getDataForAxis('accelY'),
                _getDataForAxis('accelZ'),
              ],
              ['X', 'Y', 'Z'],
              [Colors.red, Colors.green, Colors.blue],
              minY: -16,
              maxY: 16,
            ),
          ),
          const SizedBox(height: 24),
          _chartSection(
            l10n.angularVelocity,
            _buildLineChart(
              [
                _getDataForAxis('gyroX'),
                _getDataForAxis('gyroY'),
                _getDataForAxis('gyroZ'),
              ],
              ['X', 'Y', 'Z'],
              [Colors.red, Colors.green, Colors.blue],
              minY: -2000,
              maxY: 2000,
            ),
          ),
          const SizedBox(height: 24),
          _chartSection(
            l10n.eulerAngles,
            _buildLineChart(
              [
                _getDataForAxis('roll'),
                _getDataForAxis('pitch'),
                _getDataForAxis('yaw'),
              ],
              ['Roll', 'Pitch', 'Yaw'],
              [Colors.red, Colors.green, Colors.blue],
              minY: -180,
              maxY: 180,
            ),
          ),
        ],
      ),
    );
  }

  // ── Smartphone Tab ────────────────────────────────────────────────────────

  Widget _buildPhoneTab() {
    final l10n = AppLocalizations.of(context);
    final sections = <Widget>[];

    void maybeAddTriAxes(String title, List<String> fields, List<Color> colors,
        double minY, double maxY) {
      if (fields.any(_phoneFieldHasData)) {
        sections.add(_chartSection(
          title,
          _buildLineChart(
            fields.map(_getPhoneDataForField).toList(),
            ['X', 'Y', 'Z'],
            colors,
            minY: minY,
            maxY: maxY,
          ),
        ));
        sections.add(const SizedBox(height: 24));
      }
    }

    void maybeAddSingle(
        String title, String field, Color color, double minY, double maxY) {
      if (_phoneFieldHasData(field)) {
        final data = _getPhoneDataForField(field);
        sections.add(_chartSection(
          title,
          _buildLineChart(
            [data],
            [title],
            [color],
            minY: minY,
            maxY: maxY,
          ),
        ));
        sections.add(const SizedBox(height: 24));
      }
    }

    maybeAddTriAxes(
      l10n.phoneAcceleration,
      ['accelX', 'accelY', 'accelZ'],
      [Colors.red, Colors.green, Colors.blue],
      -20,
      20,
    );
    maybeAddTriAxes(
      l10n.phoneGyroscope,
      ['gyroX', 'gyroY', 'gyroZ'],
      [Colors.red, Colors.green, Colors.blue],
      -10,
      10,
    );
    maybeAddTriAxes(
      l10n.magnetometer,
      ['magX', 'magY', 'magZ'],
      [Colors.red, Colors.green, Colors.blue],
      -100,
      100,
    );

    if (_phoneFieldHasData('gpsSpeed')) {
      final data = _getPhoneDataForField('gpsSpeed');
      maybeAddSingle(l10n.gpsSpeedLabel, 'gpsSpeed', Colors.orange, 0,
          _maxValue(data) * 1.2 + 1);
    }
    if (_phoneFieldHasData('altitude')) {
      final data = _getPhoneDataForField('altitude');
      maybeAddSingle(
          l10n.gpsAltitude,
          'altitude',
          Colors.teal,
          _minValue(data) - 5,
          _maxValue(data) + 5);
    }
    if (_phoneFieldHasData('pressure')) {
      final data = _getPhoneDataForField('pressure');
      maybeAddSingle(
          l10n.barometricPressure,
          'pressure',
          Colors.purple,
          _minValue(data) - 2,
          _maxValue(data) + 2);
    }

    if (sections.isEmpty) {
      return Center(
        child: Text(
          l10n.noPhoneSensorTabData,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  // ── GPS Map Tab ───────────────────────────────────────────────────────────

  Widget _buildMapTab() {
    final pts = _gpsPoints;
    final bounds = _bounds(pts);
    final distKm = _totalDistanceKm(pts);

    final speedData = _getPhoneDataForField('gpsSpeed');
    final avgSpeed = speedData.isEmpty
        ? null
        : speedData.map((s) => s.y).reduce((a, b) => a + b) / speedData.length;

    final altData = _getPhoneDataForField('altitude');
    final maxAlt =
        altData.isEmpty ? null : altData.map((s) => s.y).reduce(math.max);
    final minAlt =
        altData.isEmpty ? null : altData.map((s) => s.y).reduce(math.min);

    final mapOptions = MapOptions(
      initialCameraFit: bounds != null
          ? CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(40),
            )
          : null,
      initialCenter:
          pts.isNotEmpty ? pts[pts.length ~/ 2] : const LatLng(0, 0),
      initialZoom: 15,
    );

    return Column(
      children: [
        _buildGpsStatsBar(distKm, avgSpeed, maxAlt, minAlt),
        Expanded(
          child: FlutterMap(
            options: mapOptions,
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aiwearable',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: pts,
                    strokeWidth: 4,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (pts.isNotEmpty)
                    Marker(
                      point: pts.first,
                      width: 36,
                      height: 36,
                      child: _mapMarker(Colors.green, Icons.play_arrow),
                    ),
                  if (pts.length > 1)
                    Marker(
                      point: pts.last,
                      width: 36,
                      height: 36,
                      child: _mapMarker(Colors.red, Icons.flag),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (altData.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              AppLocalizations.of(context).altitudeProfile,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 110,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: _buildAltitudeProfile(altData),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGpsStatsBar(
      double distKm, double? avgSpeed, double? maxAlt, double? minAlt) {
    final l10n = AppLocalizations.of(context);
    final items = <_StatItem>[
      _StatItem(
          label: l10n.distanceLabel,
          value: '${distKm.toStringAsFixed(2)} km',
          icon: Icons.straighten,
          color: Colors.blue),
      if (avgSpeed != null)
        _StatItem(
            label: l10n.avgSpeedLabel,
            value: '${avgSpeed.toStringAsFixed(1)} km/h',
            icon: Icons.speed,
            color: Colors.orange),
      if (maxAlt != null && minAlt != null)
        _StatItem(
            label: l10n.altitudeGain,
            value: '${(maxAlt - minAlt).toStringAsFixed(0)} m',
            icon: Icons.terrain,
            color: Colors.teal),
    ];

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map(_buildStatChip).toList(),
      ),
    );
  }

  Widget _buildStatChip(_StatItem stat) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stat.icon, size: 14, color: stat.color),
            const SizedBox(width: 4),
            Text(
              stat.value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: stat.color),
            ),
          ],
        ),
        Text(stat.label,
            style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _mapMarker(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildAltitudeProfile(List<FlSpot> spots) {
    final minY = spots.map((s) => s.y).reduce(math.min) - 5;
    final maxY = spots.map((s) => s.y).reduce(math.max) + 5;
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withValues(alpha: 0.25),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}m',
                  style: const TextStyle(fontSize: 9)),
            ),
          ),
          bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY).abs() > 0
              ? (maxY - minY).abs() / 3
              : 1,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _chartSection(String title, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(height: 200, child: chart),
      ],
    );
  }

  double _maxValue(List<FlSpot> spots) =>
      spots.isEmpty ? 1 : spots.map((s) => s.y).reduce(math.max);

  double _minValue(List<FlSpot> spots) =>
      spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(math.min);

  Widget _buildLineChart(
    List<List<FlSpot>> dataSeries,
    List<String> labels,
    List<Color> colors, {
    double minY = -180,
    double maxY = 180,
  }) {
    if (dataSeries.isEmpty || dataSeries.every((s) => s.isEmpty)) {
      return Center(
        child: Text(AppLocalizations.of(context).noData,
            style: const TextStyle(color: Colors.grey)),
      );
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: List.generate(dataSeries.length, (i) {
          if (dataSeries[i].isEmpty) return LineChartBarData(spots: const []);
          return LineChartBarData(
            spots: dataSeries[i],
            isCurved: true,
            color: colors[i],
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}s',
                  style: const TextStyle(fontSize: 9)),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

// ── Helper type ───────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
}
