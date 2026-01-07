part of 'connection_cubit.dart';

abstract class ConnectionState extends Equatable {
  const ConnectionState();

  @override
  List<Object> get props => [];
}

class ConnectionInitial extends ConnectionState {}

class ConnectionLoading extends ConnectionState {}

class ConnectionScanning extends ConnectionState {}

class ConnectionDiscovered extends ConnectionState {
  final List<DiscoveredDevice> devices;
  const ConnectionDiscovered(this.devices);
  @override
  List<Object> get props => [devices];
}

class ConnectionConnected extends ConnectionState {
  const ConnectionConnected();
}

class ConnectionError extends ConnectionState {
  final String message;
  const ConnectionError(this.message);
  @override
  List<Object> get props => [message];
}
