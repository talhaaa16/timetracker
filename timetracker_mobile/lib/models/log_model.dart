import 'package:cloud_firestore/cloud_firestore.dart';

class LogModel {
  final String id;
  final String eventName;
  final String details;
  final DateTime timestamp;

  LogModel({
    required this.id,
    required this.eventName,
    required this.details,
    required this.timestamp,
  });

  factory LogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LogModel(
      id: doc.id,
      eventName: data['event_name'] ?? 'Unknown',
      details: data['details'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
