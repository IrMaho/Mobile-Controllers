import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

// Windows API bindings
typedef GetCursorPosNative = Int32 Function(Pointer<POINT>);
typedef GetCursorPosDart = int Function(Pointer<POINT>);

typedef SetCursorPosNative = Int32 Function(Int32 x, Int32 y);
typedef SetCursorPosDart = int Function(int x, int y);

typedef ShowCursorNative = Int32 Function(Int32 show);
typedef ShowCursorDart = int Function(int show);

typedef GetSystemMetricsNative = Int32 Function(Int32 index);
typedef GetSystemMetricsDart = int Function(int index);

typedef GetAsyncKeyStateNative = Int16 Function(Int32 vKey);
typedef GetAsyncKeyStateDart = int Function(int vKey);

final class POINT extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;
}

class WindowsMouseMonitor {
  late DynamicLibrary _user32;
  late GetCursorPosDart _getCursorPos;
  late SetCursorPosDart _setCursorPos;
  late ShowCursorDart _showCursor;
  late GetSystemMetricsDart _getSystemMetrics;
  late GetAsyncKeyStateDart _getAsyncKeyState;

  Timer? _pollingTimer;
  bool _isCapturing = false;
  int _lastX = 0;
  int _lastY = 0;
  bool _lastLeftButton = false;
  bool _lastRightButton = false;

  late int _screenWidth;
  late int _screenHeight;

  Function(int deltaX, int deltaY)? onMouseMove;
  Function(bool isDown, int button)? onMouseButton;
  Function()? onCaptureStart;
  Function()? onCaptureStop;

  WindowsMouseMonitor() {
    if (!Platform.isWindows) return;

    _user32 = DynamicLibrary.open('user32.dll');

    _getCursorPos = _user32
        .lookup<NativeFunction<GetCursorPosNative>>('GetCursorPos')
        .asFunction();

    _setCursorPos = _user32
        .lookup<NativeFunction<SetCursorPosNative>>('SetCursorPos')
        .asFunction();

    _showCursor = _user32
        .lookup<NativeFunction<ShowCursorNative>>('ShowCursor')
        .asFunction();

    _getSystemMetrics = _user32
        .lookup<NativeFunction<GetSystemMetricsNative>>('GetSystemMetrics')
        .asFunction();

    _getAsyncKeyState = _user32
        .lookup<NativeFunction<GetAsyncKeyStateNative>>('GetAsyncKeyState')
        .asFunction();

    // SM_CXSCREEN = 0, SM_CYSCREEN = 1
    _screenWidth = _getSystemMetrics(0);
    _screenHeight = _getSystemMetrics(1);

    debugPrint('🖥️ Screen: ${_screenWidth}x$_screenHeight');
  }

  void startMonitoring() {
    if (!Platform.isWindows) return;

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _checkMousePosition();
    });

    debugPrint('👀 Mouse monitoring started');
  }

  void stopMonitoring() {
    _pollingTimer?.cancel();
    if (_isCapturing) {
      _stopCapture();
    }
    debugPrint('👀 Mouse monitoring stopped');
  }

  void _checkMousePosition() {
    final point = calloc<POINT>();
    try {
      _getCursorPos(point);
      final x = point.ref.x;
      final y = point.ref.y;

      // Check mouse buttons (VK_LBUTTON=0x01, VK_RBUTTON=0x02)
      final leftButtonDown = (_getAsyncKeyState(0x01) & 0x8000) != 0;
      final rightButtonDown = (_getAsyncKeyState(0x02) & 0x8000) != 0;

      // Check ESC key (VK_ESCAPE=0x1B) for emergency exit
      final escPressed = (_getAsyncKeyState(0x1B) & 0x8000) != 0;

      if (_isCapturing) {
        // Emergency exit with ESC
        if (escPressed) {
          debugPrint('🚪 ESC pressed - exiting capture');
          _stopCapture();
          return;
        }

        // In capture mode: send deltas
        final deltaX = x - _lastX;
        final deltaY = y - _lastY;

        // Exit capture on left edge BEFORE recentering
        // This is critical - check FIRST before manipulating cursor
        if (x < 100) {
          debugPrint('🚪 Exiting capture (x=$x)');
          _stopCapture();
          return; // Don't recenter if exiting!
        }

        if (deltaX != 0 || deltaY != 0) {
          onMouseMove?.call(deltaX, deltaY);

          // Keep cursor in center to allow infinite movement
          final centerX = _screenWidth ~/ 2;
          final centerY = _screenHeight ~/ 2;
          _setCursorPos(centerX, centerY);
          _lastX = centerX;
          _lastY = centerY;
        }

        // Send button events
        if (leftButtonDown != _lastLeftButton) {
          onMouseButton?.call(leftButtonDown, 0); // 0 = left
          _lastLeftButton = leftButtonDown;
        }
        if (rightButtonDown != _lastRightButton) {
          onMouseButton?.call(rightButtonDown, 1); // 1 = right
          _lastRightButton = rightButtonDown;
        }
      } else {
        // Monitor mode: just track position, check for right edge
        _lastX = x;
        _lastY = y;
        _lastLeftButton = leftButtonDown;
        _lastRightButton = rightButtonDown;

        const edgeThreshold = 5;
        if (x >= _screenWidth - edgeThreshold) {
          _startCapture();
        }
      }
    } finally {
      calloc.free(point);
    }
  }

  void _startCapture() {
    _isCapturing = true;
    _showCursor(0); // Hide cursor

    // Center cursor
    final centerX = _screenWidth ~/ 2;
    final centerY = _screenHeight ~/ 2;
    _setCursorPos(centerX, centerY);
    _lastX = centerX;
    _lastY = centerY;

    onCaptureStart?.call();
    debugPrint('🎮 Capture mode STARTED');
  }

  void _stopCapture() {
    _isCapturing = false;
    _showCursor(1); // Show cursor
    onCaptureStop?.call();
    debugPrint('🎮 Capture mode STOPPED');
  }

  void dispose() {
    stopMonitoring();
  }
}
