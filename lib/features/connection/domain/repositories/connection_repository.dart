import 'dart:typed_data';
import '../../../../core/error/result.dart';

enum ConnectionStatus { disconnected, connecting, connected }

abstract class ConnectionRepository {
  /// Stream of connection status changes
  Stream<ConnectionStatus> get status;

  /// Stream of incoming data
  Stream<Uint8List> get onDataReceived;

  /// Starts a TCP server on the device (For Android)
  Future<Result<void>> startServer(int port);

  /// Connects to a TCP server (For Windows)
  Future<Result<void>> connect(String ip, int port);

  /// Disconnects current connection or stops server
  Future<Result<void>> disconnect();

  /// Sends raw data packet
  Future<Result<void>> sendData(Uint8List data);

  /// Starts broadcasting presence via UDP (For Android)
  Future<Result<void>> startAdvertising();

  /// Stops broadcasting
  Future<Result<void>> stopAdvertising();

  /// Scans for devices via UDP (For Windows)
  Stream<List<DiscoveredDevice>> scanForDevices();
}

class DiscoveredDevice {
  final String ip;
  final int port;
  final String name;

  const DiscoveredDevice(this.ip, this.port, this.name);
}
