import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobail_contorolers/features/connection/domain/repositories/connection_repository.dart';

import '../../data/sources/windows_mouse_monitor.dart';
import '../../data/models/input_event.dart';

part 'input_capture_state.dart';

class InputCaptureCubit extends Cubit<InputCaptureState> {
  final ConnectionRepository connectionRepository;
  WindowsMouseMonitor? _mouseMonitor;

  InputCaptureCubit({required this.connectionRepository})
    : super(InputCaptureIdle());

  void initialize() {
    if (!Platform.isWindows) return;

    emit(InputCaptureMonitoring());

    _mouseMonitor = WindowsMouseMonitor()
      ..onMouseMove = _handleMouseMove
      ..onMouseButton = _handleMouseButton
      ..onCaptureStart = _handleCaptureStart
      ..onCaptureStop = _handleCaptureStop
      ..startMonitoring();

    debugPrint('✅ InputCapture initialized with WindowsMouseMonitor');
  }

  void _handleMouseMove(int deltaX, int deltaY) {
    final data = InputEventSerializer.serializeMouseMove(deltaX, deltaY);
    connectionRepository.sendData(data);
  }

  void _handleMouseButton(bool isDown, int button) {
    final data = InputEventSerializer.serializeMouseButton(isDown, button);
    connectionRepository.sendData(data);
  }

  void _handleCaptureStart() {
    emit(const InputCaptureActive('Phone'));
  }

  void _handleCaptureStop() {
    emit(InputCaptureMonitoring());
  }

  void stop() {
    _mouseMonitor?.dispose();
    debugPrint('✅ InputCapture stopped');
  }

  @override
  Future<void> close() {
    _mouseMonitor?.dispose();
    return super.close();
  }
}
