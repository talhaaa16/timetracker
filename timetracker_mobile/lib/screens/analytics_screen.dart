import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Analytics",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .limit(500)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final last7Days = DateTime.now().subtract(const Duration(days: 7));
          final recentLogs = docs.where((doc) {
            final ts = doc['timestamp'];
            if (ts is! Timestamp) return false;
            return ts.toDate().isAfter(last7Days);
          }).toList();

          final eventCounts = <String, int>{};
          for (var doc in recentLogs) {
            final event = doc['event_name'] ?? 'Unknown';
            eventCounts[event] = (eventCounts[event] ?? 0) + 1;
          }

          final dailyActivity = <String, int>{};
          for (var i = 0; i < 7; i++) {
            final date = DateTime.now().subtract(Duration(days: i));
            final dateKey = DateFormat('EEE').format(date);
            dailyActivity[dateKey] = 0;
          }

          for (var doc in recentLogs) {
            final ts = doc['timestamp'];
            if (ts is Timestamp) {
              final dateKey = DateFormat('EEE').format(ts.toDate());
              if (dailyActivity.containsKey(dateKey)) {
                dailyActivity[dateKey] = dailyActivity[dateKey]! + 1;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Stats
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: _StatItem("Total Activity", recentLogs.length.toString(), Icons.bolt_rounded, Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: _StatItem("Peak Day", _getPeakDay(dailyActivity), Icons.leaderboard_rounded, Colors.purpleAccent),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Bar Chart Section
                const Text(
                  "Activity Trend",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e223e).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (dailyActivity.values.isEmpty ? 10 : dailyActivity.values.reduce((a, b) => a > b ? a : b) + 5).toDouble(),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => const Color(0xFF667eea),
                            tooltipRoundedRadius: 10,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final keys = dailyActivity.keys.toList().reversed.toList();
                                if (value.toInt() >= 0 && value.toInt() < keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      keys[value.toInt()],
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: dailyActivity.entries.toList().reversed.toList().asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.value.toDouble(),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: (dailyActivity.values.isEmpty ? 10 : dailyActivity.values.reduce((a, b) => a > b ? a : b) + 5).toDouble(),
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Distribution Section
                const Text(
                  "Event Distribution",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 16),
                ...eventCounts.entries.map((entry) {
                   final total = recentLogs.length;
                   final percentage = (entry.value / total * 100).toStringAsFixed(1);
                   return _buildDistributionItem(entry.key, entry.value, percentage);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPeakDay(Map<String, int> dailyActivity) {
    if (dailyActivity.isEmpty) return "None";
    var peakKey = dailyActivity.keys.first;
    var maxVal = dailyActivity.values.first;
    dailyActivity.forEach((key, val) {
      if (val > maxVal) {
        maxVal = val;
        peakKey = key;
      }
    });
    return peakKey;
  }

  Widget _StatItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDistributionItem(String name, int count, String percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e223e).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF667eea).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.category_rounded, color: Color(0xFF667eea), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: double.parse(percentage) / 100,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: const Color(0xFF667eea),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text("$percentage%", style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
