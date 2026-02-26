import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/log_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, int> _eventCounts = {};

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Calendar View",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _eventCounts = {};
            for (var doc in snapshot.data!.docs) {
              final ts = doc['timestamp'];
              if (ts is Timestamp) {
                final date = DateTime(
                  ts.toDate().year,
                  ts.toDate().month,
                  ts.toDate().day,
                );
                _eventCounts[date] = (_eventCounts[date] ?? 0) + 1;
              }
            }
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e223e),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.now(),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF667eea),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF48bb78),
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                    defaultTextStyle: const TextStyle(color: Colors.white70),
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                  ),
                  eventLoader: (day) {
                    final normalizedDay = DateTime(day.year, day.month, day.day);
                    final count = _eventCounts[normalizedDay] ?? 0;
                    return List.generate(count > 3 ? 3 : count, (index) => 'event');
                  },
                ),
              ),
              if (_selectedDay != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, size: 18, color: Color(0xFF667eea)),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_selectedDay!),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildEventList(uid, _selectedDay!),
                ),
              ] else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 48, color: Colors.white10),
                        const SizedBox(height: 12),
                        Text(
                          "Tap a date to see activities",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(String uid, DateTime date) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('logs')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredLogs = snapshot.data!.docs
            .map((doc) => LogModel.fromFirestore(doc))
            .where((log) => isSameDay(log.timestamp, date))
            .toList();

        if (filteredLogs.isEmpty) {
          return Center(
            child: Text(
              "No logs found for this day",
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredLogs.length,
          itemBuilder: (context, index) {
            final log = filteredLogs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1e223e).withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.circle, size: 8, color: Color(0xFF667eea)),
                title: Text(log.eventName.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: log.details.isNotEmpty ? Text(log.details) : null,
                trailing: Text(
                  DateFormat('H:mm').format(log.timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
