import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/activity_record.dart';
import '../services/activity_analysis_service.dart';
import '../l10n/app_localizations.dart';

class ActivityAnalysisScreen extends StatefulWidget {
  final ActivityRecord record;

  const ActivityAnalysisScreen({super.key, required this.record});

  @override
  State<ActivityAnalysisScreen> createState() => _ActivityAnalysisScreenState();
}

class _ActivityAnalysisScreenState extends State<ActivityAnalysisScreen> {
  late ActivityAnalysis _analysis;
  String? _selectedSensor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  void _performAnalysis() {
    setState(() => _isLoading = true);

    // Perform analysis in a separate computation
    Future.microtask(() {
      final analysis = ActivityAnalysisService.analyzeActivity(widget.record);
      setState(() {
        _analysis = analysis;
        if (_analysis.sensorAnalyses.isNotEmpty) {
          _selectedSensor = _analysis.sensorAnalyses.keys.first;
        }
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).activityAnalysis),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis.sensorAnalyses.isEmpty &&
                  _analysis.phoneSensorAnalysis == null
          ? _buildEmptyState()
          : _buildAnalysisContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noDataForAnalysis,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity header
          _buildActivityHeader(),
          const SizedBox(height: 24),

          // Overall metrics
          Text(
            AppLocalizations.of(context).overallMetrics,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOverallMetricsSection(),
          const SizedBox(height: 32),

          // Sensor selector
          if (_analysis.sensorAnalyses.length > 1) ...[
            Text(
              AppLocalizations.of(context).selectSensor,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSensorSelector(),
            const SizedBox(height: 24),
          ],

          // Sensor analysis
          if (_selectedSensor != null) ...[
            _buildSensorAnalysisSection(
              _analysis.sensorAnalyses[_selectedSensor]!,
            ),
          ],

          // Phone sensor analysis
          if (_analysis.phoneSensorAnalysis != null) ...[
            const SizedBox(height: 32),
            const Divider(height: 32),
            Text(
              AppLocalizations.of(context).smartphone,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPhoneSensorAnalysisSection(_analysis.phoneSensorAnalysis!),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityHeader() {
    IconData icon;
    Color color;

    if (widget.record.type == 'walking') {
      icon = Icons.directions_walk;
      color = Colors.green;
    } else if (widget.record.type == 'running') {
      icon = Icons.directions_run;
      color = Colors.orange;
    } else {
      icon = Icons.directions_bike;
      color = Colors.blue;
    }

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              widget.record.activityName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.record.formattedDuration,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallMetricsSection() {
    final metrics = _analysis.overallMetrics;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                l10n.averageIntensity,
                metrics.averageIntensity.toStringAsFixed(2),
                metrics.intensityLevel,
                Icons.bolt,
                _getIntensityColor(metrics.averageIntensity),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.movementQuality,
                metrics.movementQuality,
                l10n.basedOnSmoothness,
                Icons.motion_photos_on,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                l10n.detectedPeaks,
                metrics.totalPeaks.toString(),
                l10n.intenseMovements,
                Icons.show_chart,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.dataQuality,
                '${(metrics.dataQuality * 100).toStringAsFixed(0)}%',
                l10n.validPoints,
                Icons.verified,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getIntensityColor(double intensity) {
    if (intensity < 1.5) {
      return Colors.green;
    } else if (intensity < 3.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _analysis.sensorAnalyses.keys.map((sensorId) {
            final isSelected = sensorId == _selectedSensor;
            return ChoiceChip(
              label: Text(sensorId.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedSensor = sensorId);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSensorAnalysisSection(SensorAnalysis analysis) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.sensor} ${analysis.sensorId.toUpperCase()}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Sensor metrics
        Row(
          children: [
            Expanded(
              child: _buildSensorMetricCard(
                l10n.intensity,
                analysis.movementIntensity.toStringAsFixed(2),
                Icons.speed,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorMetricCard(
                l10n.peaks,
                analysis.peaks.toString(),
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSensorMetricCard(
                l10n.smoothness,
                analysis.smoothness.toStringAsFixed(2),
                Icons.waves,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Acceleration analysis
        _buildVector3AnalysisCard(
          l10n.acceleration,
          analysis.acceleration,
          Icons.speed,
          Colors.blue,
        ),
        const SizedBox(height: 16),

        // Gyroscope analysis
        _buildVector3AnalysisCard(
          l10n.gyroscopeLabel,
          analysis.gyroscope,
          Icons.screen_rotation,
          Colors.green,
        ),
        const SizedBox(height: 16),

        // Orientation analysis
        _buildVector3AnalysisCard(
          l10n.orientation,
          analysis.orientation,
          Icons.explore,
          Colors.purple,
        ),
        const SizedBox(height: 24),

        // Distribution chart
        _buildDistributionChart(analysis),
      ],
    );
  }

  Widget _buildSensorMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVector3AnalysisCard(
    String title,
    Vector3Analysis analysis,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  analysis.unit,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatisticsTable(analysis),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTable(Vector3Analysis analysis) {
    final l10n = AppLocalizations.of(context);
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      border: TableBorder.all(color: Colors.grey[300]!, width: 1),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: const [
            _TableCell('', isHeader: true),
            _TableCell('X', isHeader: true),
            _TableCell('Y', isHeader: true),
            _TableCell('Z', isHeader: true),
            _TableCell('Mag', isHeader: true),
          ],
        ),
        _buildStatRow(
          l10n.min,
          analysis.x.min,
          analysis.y.min,
          analysis.z.min,
          analysis.magnitude.min,
        ),
        _buildStatRow(
          l10n.max,
          analysis.x.max,
          analysis.y.max,
          analysis.z.max,
          analysis.magnitude.max,
        ),
        _buildStatRow(
          l10n.avg,
          analysis.x.mean,
          analysis.y.mean,
          analysis.z.mean,
          analysis.magnitude.mean,
        ),
        _buildStatRow(
          l10n.median,
          analysis.x.median,
          analysis.y.median,
          analysis.z.median,
          analysis.magnitude.median,
        ),
        _buildStatRow(
          l10n.stdDev,
          analysis.x.stdDev,
          analysis.y.stdDev,
          analysis.z.stdDev,
          analysis.magnitude.stdDev,
        ),
      ],
    );
  }

  TableRow _buildStatRow(
    String label,
    double x,
    double y,
    double z,
    double mag,
  ) {
    return TableRow(
      children: [
        _TableCell(label, isBold: true),
        _TableCell(x.toStringAsFixed(2)),
        _TableCell(y.toStringAsFixed(2)),
        _TableCell(z.toStringAsFixed(2)),
        _TableCell(mag.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildDistributionChart(SensorAnalysis analysis) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).accelDistribution,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(analysis),
                  barGroups: _getBarGroups(analysis),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['Min', 'Média', 'Máx'];
                          if (value.toInt() >= 0 &&
                              value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxValue(SensorAnalysis analysis) {
    return analysis.acceleration.magnitude.max * 1.2;
  }

  List<BarChartGroupData> _getBarGroups(SensorAnalysis analysis) {
    final mag = analysis.acceleration.magnitude;
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(toY: mag.min, color: Colors.blue[300], width: 40),
        ],
      ),
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(toY: mag.mean, color: Colors.blue[600], width: 40),
        ],
      ),
      BarChartGroupData(
        x: 2,
        barRods: [
          BarChartRodData(toY: mag.max, color: Colors.blue[900], width: 40),
        ],
      ),
    ];
  }

  Widget _buildPhoneSensorAnalysisSection(PhoneSensorAnalysis analysis) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available sensors grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (analysis.hasAccelerometer)
              _buildPhoneSensorCard(
                l10n.accelerometer,
                Icons.vibration,
                Colors.blue,
                [
                  'X: ${analysis.accelerometer?.x.mean.toStringAsFixed(2)} m/s²',
                  'Y: ${analysis.accelerometer?.y.mean.toStringAsFixed(2)} m/s²',
                  'Z: ${analysis.accelerometer?.z.mean.toStringAsFixed(2)} m/s²',
                ],
              ),
            if (analysis.hasGyroscope)
              _buildPhoneSensorCard(
                l10n.gyroscope,
                Icons.rotate_right,
                Colors.green,
                [
                  'X: ${analysis.gyroscope?.x.mean.toStringAsFixed(3)} rad/s',
                  'Y: ${analysis.gyroscope?.y.mean.toStringAsFixed(3)} rad/s',
                  'Z: ${analysis.gyroscope?.z.mean.toStringAsFixed(3)} rad/s',
                ],
              ),
            if (analysis.hasMagnetometer)
              _buildPhoneSensorCard(
                l10n.magnetometer,
                Icons.explore,
                Colors.purple,
                [
                  'X: ${analysis.magnetometer?.x.mean.toStringAsFixed(1)} µT',
                  'Y: ${analysis.magnetometer?.y.mean.toStringAsFixed(1)} µT',
                  'Z: ${analysis.magnetometer?.z.mean.toStringAsFixed(1)} µT',
                ],
              ),
            if (analysis.hasGps)
              _buildPhoneSensorCard(
                l10n.gps,
                Icons.location_on,
                Colors.orange,
                [
                  '${l10n.avgSpeed}: ${analysis.gpsAverageSpeed.toStringAsFixed(2)} m/s',
                ],
              ),
            if (analysis.hasBarometer)
              _buildPhoneSensorCard(
                l10n.barometer,
                Icons.cloud,
                Colors.cyan,
                [
                  '${l10n.barometer}: ${analysis.barometerAveragePressure.toStringAsFixed(1)} hPa',
                ],
              ),
          ],
        ),
        if (!analysis.hasAccelerometer &&
            !analysis.hasGyroscope &&
            !analysis.hasBarometer &&
            !analysis.hasMagnetometer &&
            !analysis.hasGps)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.noPhoneSensorActivated,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneSensorCard(
    String title,
    IconData icon,
    Color color,
    List<String> stats,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: (MediaQuery.of(context).size.width - 48) / 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats.map(
              (stat) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  stat,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isBold;

  const _TableCell(this.text, {this.isHeader = false, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader || isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
