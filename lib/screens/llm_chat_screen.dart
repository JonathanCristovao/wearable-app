import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/activity_record.dart';
import '../providers/sensor_provider.dart';
import '../services/llm_service.dart';
import '../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models for chat messages
// ─────────────────────────────────────────────────────────────────────────────

enum _MsgRole { user, assistant, chart }

// Per-sensor palette (up to 8 sensors)
const _kSensorColors = [
  Color(0xFF6C63FF),
  Color(0xFF3ECFCF),
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFFFF9F43),
  Color(0xFFA29BFE),
  Color(0xFFFA8231),
];

class _ChartPayload {
  final String title;
  final String metric;
  // sensorKey → time-series; length == 1 for single-sensor charts
  final Map<String, List<({double t, double value})>> seriesMap;

  const _ChartPayload({
    required this.title,
    required this.metric,
    required this.seriesMap,
  });

  bool get isMultiSensor => seriesMap.length > 1;
}

class _Message {
  final _MsgRole role;
  final String text;
  final _ChartPayload? chart;
  final DateTime ts;

  _Message.user(this.text)
      : role = _MsgRole.user,
        chart = null,
        ts = DateTime.now();

  _Message.assistant(this.text)
      : role = _MsgRole.assistant,
        chart = null,
        ts = DateTime.now();

  _Message.chart(_ChartPayload c)
      : role = _MsgRole.chart,
        text = '',
        chart = c,
        ts = DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class LLMChatScreen extends StatefulWidget {
  const LLMChatScreen({super.key});

  @override
  State<LLMChatScreen> createState() => _LLMChatScreenState();
}

class _LLMChatScreenState extends State<LLMChatScreen> {
  final LLMService _llm = LLMService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  ActivityRecord? _selectedActivity;
  String? _selectedSensor;
  String _selectedMetric = 'accelX';
  bool _allSensors = false; // overlay all sensors on one chart

  final List<_Message> _messages = [];
  final List<Map<String, String>> _history = [];
  bool _loading = false;

  // ── metric meta ──────────────────────────────────────────────────────────────
  static const _metrics = [
    ('accelX', 'Acel. X', 'g'),
    ('accelY', 'Acel. Y', 'g'),
    ('accelZ', 'Acel. Z', 'g'),
    ('gyroX', 'Giro. X', '°/s'),
    ('gyroY', 'Giro. Y', '°/s'),
    ('gyroZ', 'Giro. Z', '°/s'),
    ('roll', 'Roll', '°'),
    ('pitch', 'Pitch', '°'),
    ('yaw', 'Yaw', '°'),
  ];

  // ── quick prompts ────────────────────────────────────────────────────────────
  static const _quickPrompts = [
    ('📊', 'Resumo geral', 'Faça um resumo geral das métricas desta atividade.'),
    ('⚠️', 'Detectar problemas', 'Analise os dados e detecte anomalias ou problemas.'),
    ('🔄', 'Análise de movimento', 'Analise o padrão de movimento com base nos ângulos de Euler.'),
    ('💪', 'Qualidade do treino', 'Avalie a qualidade do treino com base na variabilidade dos dados.'),
    ('📈', 'Picos e vales', 'Identifique os picos e vales mais relevantes dos dados de aceleração.'),
    ('🔀', 'Comparar sensores', 'Compare os dados de todos os sensores e identifique diferenças entre eles.'),
  ];

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty) return;
    _inputCtrl.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(_Message.user(msg));
      _loading = true;
    });
    _scrollToBottom();

    // Chart-generation shortcut: if user asks for a chart, generate it inline
    if (_selectedActivity != null && _isChartRequest(msg)) {
      _addChartMessage(_selectedMetric);
    }

    try {
      final reply = await _llm.chat(
        activity: _selectedActivity,
        history: _history,
        userMessage: msg,
        selectedSensor: _allSensors ? null : _selectedSensor,
        allSensors: _allSensors,
      );

      _history.add({'role': 'user', 'content': msg});
      _history.add({'role': 'assistant', 'content': reply});

      setState(() {
        _messages.add(_Message.assistant(reply));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
            _Message.assistant(AppLocalizations.of(context).errorContactingModel('$e')));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  bool _isChartRequest(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('gráfico') ||
        lower.contains('grafico') ||
        lower.contains('mostrar') ||
        lower.contains('plotar') ||
        lower.contains('visualizar') ||
        lower.contains('plot');
  }

  List<String> _getSensorKeys() {
    if (_selectedActivity == null) return [];
    final keys = <String>{};
    for (final dp in _selectedActivity!.dataPoints) {
      keys.addAll(dp.sensors.keys);
    }
    return keys.toList()..sort();
  }

  void _addChartMessage(String metric) {
    final sensorKeys = _getSensorKeys();
    if (sensorKeys.isEmpty || _selectedActivity == null) return;

    final keys = _allSensors
        ? sensorKeys
        : [_selectedSensor ?? sensorKeys.first];

    final seriesMap = <String, List<({double t, double value})>>{};
    for (final k in keys) {
      final s = _llm.extractTimeSeries(_selectedActivity!, k, metric);
      if (s.isNotEmpty) seriesMap[k] = s;
    }
    if (seriesMap.isEmpty) return;

    final metaLabel = _metrics.firstWhere(
      (m) => m.$1 == metric,
      orElse: () => (metric, metric, ''),
    );
    final title = _allSensors
        ? AppLocalizations.of(context).allSensorsLabel(metaLabel.$2)
        : '${metaLabel.$2} — ${keys.first}';

    setState(() {
      _messages.add(
        _Message.chart(
          _ChartPayload(title: title, metric: metric, seriesMap: seriesMap),
        ),
      );
    });
    _scrollToBottom();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.psychology, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).llmContextTitle),
          ],
        ),
        backgroundColor: cs.surfaceContainerHighest,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildActivitySelector(),
          _buildSensorMetricRow(),
          const Divider(height: 1),
          Expanded(child: _buildMessageList()),
          if (_loading) _buildThinkingIndicator(),
          _buildQuickPrompts(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Activity selector ────────────────────────────────────────────────────────

  Widget _buildActivitySelector() {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final l10n = AppLocalizations.of(context);
        final records = provider.activityRecords;

        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              const Icon(Icons.fitness_center, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: records.isEmpty
                    ? Text(
                        l10n.noRecordedActivities,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<ActivityRecord>(
                          isDense: true,
                          isExpanded: true,
                          hint: Text(l10n.selectActivity,
                              style: const TextStyle(fontSize: 13)),
                          value: _selectedActivity,
                          items: records.reversed
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    '${r.activityName} — ${DateFormat('dd/MM HH:mm').format(r.startTime)}',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedActivity = v;
                            _selectedSensor = null;
                            _messages.clear();
                            _history.clear();
                          }),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sensor / metric row ──────────────────────────────────────────────────────

  Widget _buildSensorMetricRow() {
    final l10n = AppLocalizations.of(context);
    final sensorKeys = _getSensorKeys();

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: sensor toggle + sensor picker + metric picker
          Row(
            children: [
              // All-sensors toggle chip
              if (sensorKeys.length > 1) ...[
                FilterChip(
                  label: Text(l10n.all, style: const TextStyle(fontSize: 11)),
                  avatar: const Icon(Icons.layers, size: 14),
                  selected: _allSensors,
                  onSelected: (v) => setState(() {
                    _allSensors = v;
                    if (v) _selectedSensor = null;
                  }),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
              ],
              // Sensor picker (hidden when allSensors)
              if (sensorKeys.isNotEmpty && !_allSensors) ...[
                const Icon(Icons.sensors, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    hint: Text(l10n.sensor, style: const TextStyle(fontSize: 12)),
                    value: _selectedSensor,
                    items: sensorKeys
                        .map((k) => DropdownMenuItem(
                              value: k,
                              child: Text(k,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSensor = v),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Metric picker
              const Icon(Icons.show_chart, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  value: _selectedMetric,
                  items: _metrics
                      .map((m) => DropdownMenuItem(
                            value: m.$1,
                            child: Text(m.$2,
                                style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedMetric = v ?? _selectedMetric),
                ),
              ),
              const Spacer(),
              // Quick chart button
              if (_selectedActivity != null && sensorKeys.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.bar_chart, size: 16),
                  label: Text(
                    _allSensors ? l10n.overlaidChart : l10n.chartLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _addChartMessage(_selectedMetric),
                ),
            ],
          ),
          // Row 2: sensor colour chips when allSensors is on
          if (_allSensors && sensorKeys.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                children: [
                  for (int i = 0; i < sensorKeys.length; i++)
                    _buildSensorLegendChip(
                      sensorKeys[i],
                      _kSensorColors[i % _kSensorColors.length],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorLegendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ── Message list ─────────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildMessageItem(_messages[i]),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedActivity == null
                ? l10n.selectActivityToStartAnalysis
                : l10n.askAboutSelectedActivity,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(_Message msg) {
    switch (msg.role) {
      case _MsgRole.user:
        return _buildUserBubble(msg);
      case _MsgRole.assistant:
        return _buildAssistantBubble(msg);
      case _MsgRole.chart:
        return _buildChartBubble(msg.chart!);
    }
  }

  Widget _buildUserBubble(_Message msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(_Message msg) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, right: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 14),
          ),
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10, right: 40),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBubble(_ChartPayload payload) {
    final l10n = AppLocalizations.of(context);
    if (payload.seriesMap.isEmpty) return const SizedBox.shrink();

    final metaMeta = _metrics.firstWhere(
      (m) => m.$1 == payload.metric,
      orElse: () => (payload.metric, payload.metric, ''),
    );

    // Global Y range across all series
    double globalMin = double.infinity;
    double globalMax = double.negativeInfinity;
    double maxT = 0;
    for (final s in payload.seriesMap.values) {
      for (final p in s) {
        if (p.value < globalMin) globalMin = p.value;
        if (p.value > globalMax) globalMax = p.value;
        if (p.t > maxT) maxT = p.t;
      }
    }
    final yPad = (globalMax - globalMin) * 0.1 + 0.5;

    // Build one LineChartBarData per sensor
    final sensorKeys = payload.seriesMap.keys.toList();
    final bars = <LineChartBarData>[];
    for (int i = 0; i < sensorKeys.length; i++) {
      final key = sensorKeys[i];
      final color = _kSensorColors[i % _kSensorColors.length];
      final spots = payload.seriesMap[key]!
          .map((p) => FlSpot(p.t, p.value))
          .toList();
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: color,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: payload.isMultiSensor
              ? BarAreaData(show: false)
              : BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.25),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  payload.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          // Legend (multi-sensor only)
          if (payload.isMultiSensor) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                for (int i = 0; i < sensorKeys.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _kSensorColors[i % _kSensorColors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sensorKeys[i],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Chart
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minY: globalMin - yPad,
                maxY: globalMax + yPad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (maxT / 4).clamp(1, 9999),
                      getTitlesWidget: (v, meta) => Text(
                        '${v.toStringAsFixed(0)}s',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: bars,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.chartInfo(metaMeta.$3, sensorKeys.length, maxT.toStringAsFixed(1)),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── Thinking indicator ───────────────────────────────────────────────────────

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(AppLocalizations.of(context).analyzing,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Quick prompts ────────────────────────────────────────────────────────────

  Widget _buildQuickPrompts() {
    if (_messages.isNotEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: _quickPrompts
            .map(
              (q) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Text(q.$1, style: const TextStyle(fontSize: 14)),
                  label: Text(q.$2,
                      style: const TextStyle(fontSize: 12)),
                  onPressed: _selectedActivity != null
                      ? () => _send(q.$3)
                      : null,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                enabled: !_loading,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: _selectedActivity == null
                      ? l10n.selectActivityFirst
                      : l10n.askModel,
                  hintStyle:
                      const TextStyle(fontSize: 14, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
                onSubmitted: _loading || _selectedActivity == null
                    ? null
                    : (v) => _send(v),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _loading || _selectedActivity == null
                    ? null
                    : () => _send(_inputCtrl.text),
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
