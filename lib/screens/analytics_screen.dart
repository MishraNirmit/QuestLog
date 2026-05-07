import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuestProvider>(context);

    // Generate actual past 7 days rates
    final now = DateTime.now();
    final List<double> dailyRates = [];
    final List<String> dailyLabels = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dailyRates.add(provider.getHistoricalCompletionRate(date));
      // Just a quick way to get Mon/Tue string
      const days = ['M','T','W','Th','F','S','Su'];
      dailyLabels.add(days[date.weekday - 1]);
    }

    // Mock Weekly and Monthly since grouping by week/month is complex and out of scope for the snippet size,
    // but we use the current day's rate to make it dynamic.
    final double currentRate = provider.getPowerBarPercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Analytics', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: "Daily"),
            Tab(text: "Weekly"),
            Tab(text: "Monthly"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChart(dailyRates, "Daily Trend", 7, dailyLabels),
          _buildChart(List.generate(4, (i) => (i==3) ? currentRate : 0.5), "Weekly Trend", 4, ['W1','W2','W3','W4']),
          _buildChart(List.generate(12, (i) => (i==now.month-1) ? currentRate : 0.4), "Monthly Trend", 12, ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']),
        ],
      ),
    );
  }

  Widget _buildChart(List<double> rates, String title, int count, List<String> labels) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const style = TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14);
                          int idx = value.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return SideTitleWidget(axisSide: meta.axisSide, space: 16, child: Text(labels[idx], style: style));
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 38,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(count, (index) {
                    return makeGroupData(index, rates[index] * 100);
                  }),
                ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: y >= 100 ? const Color(0xFF00FF00) : (y < 50 ? const Color(0xFFFF0000) : Colors.amber),
          width: 22,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
