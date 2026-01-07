import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/input_event.dart';

class AndroidInputReceiver {
  static const _methodChannel = MethodChannel(
    'com.example.mobail_contorolers/mouse',
  );

  void handleInputData(Uint8List data) {
    final event = InputEventSerializer.deserialize(data);
    if (event == null) {
      debugPrint('Failed to deserialize event');
      return;
    }

    debugPrint('Received: $event');

    switch (event['type']) {
      case 'mouseMove':
        _handleMouseMove(event['deltaX'], event['deltaY']);
        break;
      case 'mouseDown':
        _handleMouseButton(true, event['button']);
        break;
      case 'mouseUp':
        _handleMouseButton(false, event['button']);
        break;
    }
  }

  void _handleMouseMove(int deltaX, int deltaY) {
    debugPrint('MouseMove: dx=$deltaX, dy=$deltaY');
    try {
      _methodChannel.invokeMethod('moveCursor', {
        'deltaX': deltaX,
        'deltaY': deltaY,
      });
    } catch (e) {
      debugPrint('Error moving cursor: $e');
    }
  }

  void _handleMouseButton(bool isDown, int button) {
    debugPrint('MouseButton: ${isDown ? "Down" : "Up"}, button=$button');
    if (isDown) {
      try {
        _methodChannel.invokeMethod('performClick');
      } catch (e) {
        debugPrint('Error performing click: $e');
      }
    }
  }
}
