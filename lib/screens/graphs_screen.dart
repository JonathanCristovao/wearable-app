import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/sensor_data.dart';
import '../models/phone_sensor_data.dart';
import '../services/bluetooth_service.dart';
import '../providers/sensor_provider.dart';
import '../l10n/app_localizations.dart';
import '../config/app_config.dart';

class GraphsScreen extends StatefulWidget {
  const GraphsScreen({super.key});

  @override
  State<GraphsScreen> createState() => _GraphsScreenState();
}

class _GraphsScreenState extends State<GraphsScreen> {
  // Data buffers for charts (keep last 100 points)
  final List<FlSpot> _accelXData = [];
  final List<FlSpot> _accelYData = [];
  final List<FlSpot> _accelZData = [];

  final List<FlSpot> _gyroXData = [];
  final List<FlSpot> _gyroYData = [];
  final List<FlSpot> _gyroZData = [];

  final List<FlSpot> _rollData = [];
  final List<FlSpot> _pitchData = [];
  final List<FlSpot> _yawData = [];

  double _timeCounter = 0;
  static const int _maxDataPoints = 100;
  static const double _timeIncrement = 0.1;

  // Selected sensor: 1-4 = BLE, 0 = smartphone
  int _selectedSensor = 1;
  StreamSubscription<SensorData>? _dataSubscription;
  StreamSubscription<PhoneSensorData>? _phoneDataSubscription;

  // Phone sensor buffers
  final List<FlSpot> _phoneAccelXData = [];
  final List<FlSpot> _phoneAccelYData = [];
  final List<FlSpot> _phoneAccelZData = [];
  final List<FlSpot> _phoneGyroXData = [];
  final List<FlSpot> _phoneGyroYData = [];
  final List<FlSpot> _phoneGyroZData = [];
  final List<FlSpot> _phoneMagXData = [];
  final List<FlSpot> _phoneMagYData = [];
  final List<FlSpot> _phoneMagZData = [];
  final List<FlSpot> _phoneGpsSpeedData = [];
  final List<FlSpot> _phoneBaroData = [];
  double _phoneTimeCounter = 0;

  @override
  void initState() {
    super.initState();

    // Listen to sensor data updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeSensorData();
    });
  }

  void _subscribeSensorData() {
    _dataSubscription?.cancel();
    _phoneDataSubscription?.cancel();

    if (_selectedSensor == 0) {
      // Phone sensor
      final provider = Provider.of<SensorProvider>(context, listen: false);
      _phoneDataSubscription = provider.phoneSensorDataStream.listen((data) {
        if (mounted) {
          setState(() {
            _addPhoneDataPoint(data);
          });
        }
      });
      return;
    }

    // BLE sensors - get stream dynamically
    final bluetoothService = BluetoothService();

    Stream<SensorData> sensorStream = bluetoothService.getSensorDataStream(_selectedSensor);

    _dataSubscription = sensorStream.listen((data) {
      if (mounted) {
        setState(() {
          _addDataPoint(data);
        });
      }
    });
  }

  void _onSensorChanged(int sensor) {
    setState(() {
      _selectedSensor = sensor;
      _clearData();
      _timeCounter = 0;
      _phoneTimeCounter = 0;
    });
    _subscribeSensorData();
  }

  void _clearData() {
    _accelXData.clear();
    _accelYData.clear();
    _accelZData.clear();
    _gyroXData.clear();
    _gyroYData.clear();
    _gyroZData.clear();
    _rollData.clear();
    _pitchData.clear();
    _yawData.clear();
    _phoneAccelXData.clear();
    _phoneAccelYData.clear();
    _phoneAccelZData.clear();
    _phoneGyroXData.clear();
    _phoneGyroYData.clear();
    _phoneGyroZData.clear();
    _phoneMagXData.clear();
    _phoneMagYData.clear();
    _phoneMagZData.clear();
    _phoneGpsSpeedData.clear();
    _phoneBaroData.clear();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    _phoneDataSubscription?.cancel();
    super.dispose();
  }

  void _addDataPoint(SensorData data) {
    _timeCounter += _timeIncrement;

    // Add new points
    _accelXData.add(FlSpot(_timeCounter, data.accelerationX));
    _accelYData.add(FlSpot(_timeCounter, data.accelerationY));
    _accelZData.add(FlSpot(_timeCounter, data.accelerationZ));

    _gyroXData.add(FlSpot(_timeCounter, data.angularVelocityX));
    _gyroYData.add(FlSpot(_timeCounter, data.angularVelocityY));
    _gyroZData.add(FlSpot(_timeCounter, data.angularVelocityZ));

    _rollData.add(FlSpot(_timeCounter, data.roll));
    _pitchData.add(FlSpot(_timeCounter, data.pitch));
    _yawData.add(FlSpot(_timeCounter, data.yaw));

    // Remove old points if exceeding max
    if (_accelXData.length > _maxDataPoints) {
      _accelXData.removeAt(0);
      _accelYData.removeAt(0);
      _accelZData.removeAt(0);
      _gyroXData.removeAt(0);
      _gyroYData.removeAt(0);
      _gyroZData.removeAt(0);
      _rollData.removeAt(0);
      _pitchData.removeAt(0);
      _yawData.removeAt(0);
    }
  }

  void _addPhoneDataPoint(PhoneSensorData data) {
    _phoneTimeCounter += _timeIncrement;

    void addIfNotNull(List<FlSpot> list, double? value) {
      list.add(FlSpot(_phoneTimeCounter, value ?? 0.0));
      if (list.length > _maxDataPoints) list.removeAt(0);
    }

    addIfNotNull(_phoneAccelXData, data.accelX);
    addIfNotNull(_phoneAccelYData, data.accelY);
    addIfNotNull(_phoneAccelZData, data.accelZ);
    addIfNotNull(_phoneGyroXData, data.gyroX);
    addIfNotNull(_phoneGyroYData, data.gyroY);
    addIfNotNull(_phoneGyroZData, data.gyroZ);
    addIfNotNull(_phoneMagXData, data.magX);
    addIfNotNull(_phoneMagYData, data.magY);
    addIfNotNull(_phoneMagZData, data.magZ);
    addIfNotNull(_phoneGpsSpeedData, data.gpsSpeed);
    addIfNotNull(_phoneBaroData, data.barometricPressure);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sensor selector
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
                  Consumer<SensorProvider>(
                    builder: (context, provider, _) {
                      return DropdownButton<int>(
                        value: _selectedSensor,
                        isExpanded: true,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        menuMaxHeight: 300,
                        items: [
                          for (final s in List.generate(NUMBER_OF_SENSORS, (i) => i + 1))
                            DropdownMenuItem(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(Icons.bluetooth, size: 20, color: Colors.blue[700]),
                                  const SizedBox(width: 12),
                                  Text('${l10n.sensor} $s'),
                                ],
                              ),
                            ),
                          if (provider.phoneSensorSettings.anyEnabled)
                            DropdownMenuItem(
                              value: 0,
                              child: Row(
                                children: [
                                  const Icon(Icons.phone_android, size: 20, color: Colors.indigo),
                                  const SizedBox(width: 12),
                                  Text(l10n.smartphone),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) _onSensorChanged(value);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Chart content
          if (_selectedSensor == 0) _buildPhoneCharts(l10n) else _buildBleCharts(l10n),
        ],
      ),
    );
  }

  Widget _buildBleCharts(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accelerationG,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: _buildLineChart(
            [_accelXData, _accelYData, _accelZData],
            ['X', 'Y', 'Z'],
            [Colors.red, Colors.green, Colors.blue],
            minY: -16,
            maxY: 16,
            emptyText: l10n.waitingData,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.angularVelocity,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: _buildLineChart(
            [_gyroXData, _gyroYData, _gyroZData],
            ['X', 'Y', 'Z'],
            [Colors.red, Colors.green, Colors.blue],
            minY: -2000,
            maxY: 2000,
            emptyText: l10n.waitingData,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.angles,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: _buildLineChart(
            [_rollData, _pitchData, _yawData],
            ['Roll', 'Pitch', 'Yaw'],
            [Colors.red, Colors.green, Colors.blue],
            minY: -180,
            maxY: 180,
            emptyText: l10n.waitingData,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneCharts(AppLocalizations l10n) {
    final provider = Provider.of<SensorProvider>(context);
    final settings = provider.phoneSensorSettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (settings.accelerometerEnabled) ...[
          Text(
            l10n.accelerometerMs2,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildLineChart(
              [_phoneAccelXData, _phoneAccelYData, _phoneAccelZData],
              ['X', 'Y', 'Z'],
              [Colors.red, Colors.green, Colors.blue],
              minY: -25,
              maxY: 25,
              emptyText: l10n.waitingData,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (settings.gyroscopeEnabled) ...[
          Text(
            l10n.gyroscopeRads,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildLineChart(
              [_phoneGyroXData, _phoneGyroYData, _phoneGyroZData],
              ['X', 'Y', 'Z'],
              [Colors.red, Colors.green, Colors.blue],
              minY: -15,
              maxY: 15,
              emptyText: l10n.waitingData,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (settings.magnetometerEnabled) ...[
          Text(
            l10n.magnetometerUt,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildLineChart(
              [_phoneMagXData, _phoneMagYData, _phoneMagZData],
              ['X', 'Y', 'Z'],
              [Colors.red, Colors.green, Colors.blue],
              minY: -100,
              maxY: 100,
              emptyText: l10n.waitingData,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (settings.gpsEnabled) ...[
          Text(
            l10n.gpsSpeed,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildLineChart(
              [_phoneGpsSpeedData],
              ['Vel'],
              [Colors.teal],
              minY: 0,
              maxY: 30,
              emptyText: l10n.waitingData,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (settings.barometerEnabled) ...[
          Text(
            l10n.barometerHpa,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _buildLineChart(
              [_phoneBaroData],
              ['hPa'],
              [Colors.orange],
              minY: 900,
              maxY: 1100,
              emptyText: l10n.waitingData,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (!settings.anyEnabled)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                '${l10n.noPhoneSensorEnabled}.\n${l10n.settings} > ${l10n.smartphoneSensors}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLineChart(
    List<List<FlSpot>> dataSeries,
    List<String> labels,
    List<Color> colors, {
    double minY = -180,
    double maxY = 180,
    String emptyText = 'Aguardando dados...',
  }) {
    if (dataSeries.isEmpty || dataSeries.every((series) => series.isEmpty)) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: List.generate(dataSeries.length, (index) {
          return LineChartBarData(
            spots: dataSeries[index],
            isCurved: true,
            color: colors[index],
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
