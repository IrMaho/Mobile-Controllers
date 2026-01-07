part of 'input_capture_cubit.dart';

abstract class InputCaptureState extends Equatable {
  const InputCaptureState();

  @override
  List<Object> get props => [];
}

class InputCaptureIdle extends InputCaptureState {}

class InputCaptureMonitoring extends InputCaptureState {}

class InputCaptureActive extends InputCaptureState {
  final String targetIp;
  const InputCaptureActive(this.targetIp);
  @override
  List<Object> get props => [targetIp];
}

class InputCaptureError extends InputCaptureState {
  final String message;
  const InputCaptureError(this.message);
  @override
  List<Object> get props => [message];
}
