import 'package:random_app/utils.dart';
import 'package:test/test.dart';

void main() {
  test('timestamp test', () {
    String time =
        getDisplayTimestamp(DateTime.fromMicrosecondsSinceEpoch(10000000));
    expect(time, '6:00 PM - 12/31');
  });
}
