import 'package:flutter_test/flutter_test.dart';
import 'package:timetracker_mobile/models/log_model.dart';

void main() {
  test('LogModel constructor initializes properties correctly', () {
    final timestamp = DateTime.now();
    final log = LogModel(
      id: 'test_id',
      eventName: 'PUNCH_IN',
      details: 'Test details',
      timestamp: timestamp,
    );

    expect(log.id, 'test_id');
    expect(log.eventName, 'PUNCH_IN');
    expect(log.details, 'Test details');
    expect(log.timestamp, timestamp);
  });
}
