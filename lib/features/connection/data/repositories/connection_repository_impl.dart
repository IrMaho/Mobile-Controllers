import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/connection_repository.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  Socket? _socket;
  ServerSocket? _serverSocket;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _dataController = StreamController<Uint8List>.broadcast();

  ConnectionRepositoryImpl() {
    _statusController.add(ConnectionStatus.disconnected);
  }

  @override
  Stream<ConnectionStatus> get status => _statusController.stream;

  @override
  Stream<Uint8List> get onDataReceived => _dataController.stream;

  @override
  Future<Result<void>> startServer(int port) async {
    try {
      _statusController.add(ConnectionStatus.connecting);
      // Listen on all interfaces
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);

      debugPrint('Server running on port $port');

      _serverSocket!.listen((socket) {
        debugPrint('Client connected: ${socket.remoteAddress.address}');
        _handleNewConnection(socket);
      });

      return const Success(null);
    } catch (e) {
      _statusController.add(ConnectionStatus.disconnected);
      return ResultFailure(ConnectionFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> connect(String ip, int port) async {
    try {
      _statusController.add(ConnectionStatus.connecting);
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      _handleNewConnection(socket);
      return const Success(null);
    } catch (e) {
      _statusController.add(ConnectionStatus.disconnected);
      return ResultFailure(ConnectionFailure(e.toString()));
    }
  }

  void _handleNewConnection(Socket socket) {
    _socket?.destroy(); // Close existing if any
    _socket = socket;
    _statusController.add(ConnectionStatus.connected);

    _socket!.listen(
      (data) {
        _dataController.add(data);
      },
      onDone: () {
        debugPrint('Connection closed');
        _disconnectCleanup();
      },
      onError: (e) {
        debugPrint('Connection error: $e');
        _disconnectCleanup();
      },
    );
  }

  @override
  Future<Result<void>> disconnect() async {
    try {
      _disconnectCleanup();
      return const Success(null);
    } catch (e) {
      return ResultFailure(ConnectionFailure(e.toString()));
    }
  }

  void _disconnectCleanup() {
    _socket?.destroy();
    _socket = null;
    _serverSocket?.close();
    _serverSocket = null;
    _statusController.add(ConnectionStatus.disconnected);
  }

  Future<Result<void>> sendData(Uint8List data) async {
    if (_socket == null) {
      return const ResultFailure(ConnectionFailure("No active connection"));
    }
    try {
      _socket!.add(data);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ConnectionFailure(e.toString()));
    }
  }

  // --- Auto Discovery ---
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;

  @override
  Future<Result<void>> startAdvertising() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpSocket?.broadcastEnabled = true;

      _broadcastTimer?.cancel();
      _broadcastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final message = "MOBILE_CONTROLLER_DISCOVERY:5000:AndroidDevice";
        final data = Uint8List.fromList(message.codeUnits);
        _udpSocket?.send(data, InternetAddress('255.255.255.255'), 45454);
      });
      return const Success(null);
    } catch (e) {
      return ResultFailure(ConnectionFailure("UDP Bind Failed: $e"));
    }
  }

  @override
  Future<Result<void>> stopAdvertising() async {
    _broadcastTimer?.cancel();
    _udpSocket?.close();
    return const Success(null);
  }

  @override
  Stream<List<DiscoveredDevice>> scanForDevices() {
    final controller = StreamController<List<DiscoveredDevice>>();
    RawDatagramSocket? scanSocket;
    final devices = <String, DiscoveredDevice>{};

    void startScan() async {
      try {
        scanSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          45454,
        );
        scanSocket?.listen((event) {
          if (event == RawSocketEvent.read) {
            final datagram = scanSocket?.receive();
            if (datagram != null) {
              final message = String.fromCharCodes(datagram.data);
              // Format: HEADER:PORT:NAME
              if (message.startsWith("MOBILE_CONTROLLER_DISCOVERY")) {
                final parts = message.split(':');
                if (parts.length >= 3) {
                  final port = int.tryParse(parts[1]) ?? 5000;
                  final name = parts[2];
                  final ip = datagram.address.address;

                  final device = DiscoveredDevice(ip, port, name);
                  devices[ip] = device; // Deduplicate by IP
                  controller.add(devices.values.toList());
                  debugPrint("Discovered: $ip - $name");
                }
              }
            }
          }
        });
      } catch (e) {
        debugPrint("Scan failed: $e");
        // Windows firewall might block this.
      }
    }

    startScan();

    controller.onCancel = () {
      scanSocket?.close();
    };

    return controller.stream;
  }
}
