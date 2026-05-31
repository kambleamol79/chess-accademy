import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/config/theme.dart';

void main() {
  test('App theme uses brand primary blue', () {
    expect(AppTheme.light.colorScheme.primary, AppColors.primaryBlue);
  });
}
