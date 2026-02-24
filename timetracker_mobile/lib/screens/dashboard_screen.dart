import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/log_model.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLogs = snapshot.data!.docs.map((doc) => LogModel.fromFirestore(doc)).toList();
          final filteredLogs = allLogs.where((log) => _isSameDay(log.timestamp, selectedDate)).toList();

          // Calculate summary for selected day
          final summary = _calculateDaySummary(filteredLogs);

          return Column(
            children: [
              // Premium Home Summary
              GlassCard(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem("Work Today", summary['work']!, Icons.timer_rounded, const Color(0xFF667eea)),
                    Container(width: 1.5, height: 40, color: Colors.white.withOpacity(0.1)),
                    _buildSummaryItem("Break Time", summary['break']!, Icons.coffee_rounded, const Color(0xFFed8936)),
                  ],
                ),
              ),

              // Date Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 28),
                      onPressed: () {
                        setState(() {
                          selectedDate = selectedDate.subtract(const Duration(days: 1));
                        });
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEEE').format(selectedDate),
                            style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        size: 28,
                        color: _isSameDay(selectedDate, DateTime.now()) ? Colors.white10 : Colors.white,
                      ),
                      onPressed: _isSameDay(selectedDate, DateTime.now())
                          ? null
                          : () {
                              setState(() {
                                selectedDate = selectedDate.add(const Duration(days: 1));
                              });
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Activity List
              Expanded(
                child: filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final eventMeta = _getEventMeta(log.eventName);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1e223e).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      eventMeta['color'].withOpacity(0.2),
                                      eventMeta['color'].withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(eventMeta['icon'], color: eventMeta['color'], size: 22),
                              ),
                              title: Text(
                                log.eventName.replaceAll('_', ' '),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2),
                              ),
                              subtitle: log.details.isNotEmpty
                                  ? Text(log.details, style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w500))
                                  : null,
                              trailing: Text(
                                DateFormat('hh:mm a').format(log.timestamp),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, String> _calculateDaySummary(List<LogModel> logs) {
    if (logs.isEmpty) return {'work': '0h 00m', 'break': '0h 00m'};

    DateTime? punchIn;
    DateTime? endDay;
    int totalBreakMs = 0;
    DateTime? breakStart;

    // Process from oldest to newest for temporal logic
    final cronLogs = logs.reversed.toList();

    for (var log in cronLogs) {
      if (log.eventName == 'PUNCH_IN' && punchIn == null) {
        punchIn = log.timestamp;
      } else if (log.eventName == 'END_DAY') {
        endDay = log.timestamp;
      } else if (log.eventName == 'BREAK_START') {
        breakStart = log.timestamp;
      } else if (log.eventName == 'BREAK_END') {
        // Try to parse duration from details first (most accurate)
        final mins = _extractMinutes(log.details);
        if (mins > 0) {
          totalBreakMs += mins * 60000;
        } else if (breakStart != null) {
          // Fallback to timestamp difference
          totalBreakMs += log.timestamp.difference(breakStart).inMilliseconds;
        }
        breakStart = null;
      } else if (log.eventName == 'EDIT_BREAK') {
        final mins = _extractMinutes(log.details);
        if (log.details.contains('added')) {
          totalBreakMs += mins * 60000;
        } else if (log.details.contains('Reduced')) {
          totalBreakMs -= mins * 60000;
        }
      }
    }

    // Ensure break time doesn't go negative
    if (totalBreakMs < 0) totalBreakMs = 0;

    // If still on break, add time until now
    if (breakStart != null && _isSameDay(breakStart, DateTime.now())) {
      totalBreakMs += DateTime.now().difference(breakStart).inMilliseconds;
    }

    // Work duration: from punch in until (end day OR now)
    int totalWorkMs = 0;
    if (punchIn != null) {
      final endTime = endDay ?? (_isSameDay(punchIn, DateTime.now()) ? DateTime.now() : punchIn.add(const Duration(hours: 8)));
      totalWorkMs = endTime.difference(punchIn).inMilliseconds - totalBreakMs;
      if (totalWorkMs < 0) totalWorkMs = 0;
    }

    return {
      'work': _formatDuration(totalWorkMs),
      'break': _formatDuration(totalBreakMs),
    };
  }

  int _extractMinutes(String details) {
    final regExp = RegExp(r'(\d+)m');
    final match = regExp.firstMatch(details);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Opacity(
        opacity: 0.3,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_motion_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text("No activities today", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, dynamic> _getEventMeta(String event) {
    switch (event) {
      case 'PUNCH_IN': return {'icon': Icons.login_rounded, 'color': const Color(0xFF48bb78)};
      case 'BREAK_START': return {'icon': Icons.coffee_rounded, 'color': const Color(0xFFf56565)};
      case 'BREAK_END': return {'icon': Icons.play_arrow_rounded, 'color': const Color(0xFF4fc1ff)};
      case 'EDIT_BREAK': return {'icon': Icons.edit_calendar_rounded, 'color': const Color(0xFFb5cea8)};
      case 'END_DAY': return {'icon': Icons.flag_rounded, 'color': const Color(0xFFed8936)};
      case 'RESUME_WORK': return {'icon': Icons.work_rounded, 'color': const Color(0xFFb5cea8)};
      case 'Meeting': return {'icon': Icons.people_rounded, 'color': const Color(0xFFce9178)};
      default: return {'icon': Icons.info_outline_rounded, 'color': const Color(0xFF9cdcfe)};
    }
  }
}
