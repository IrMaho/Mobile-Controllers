import 'package:flutter/services.dart';

class AccessibilityHelper {
  static const _methodChannel = MethodChannel(
    'com.example.mobail_contorolers/mouse',
  );

  static Future<void> openAccessibilitySettings() async {
    try {
      await _methodChannel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Error opening accessibility settings: $e');
    }
  }
}
