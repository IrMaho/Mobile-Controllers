import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/usecases/connect_to_device.dart';
import '../../domain/usecases/disconnect_device.dart';
import '../../domain/usecases/listen_connection_status.dart';
import '../../domain/usecases/start_server.dart';
import '../../domain/usecases/advertise_presence.dart';
import '../../domain/usecases/scan_for_devices.dart';

part 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionState> {
  final StartServer startServerUseCase;
  final ConnectToDevice connectToDeviceUseCase;
  final DisconnectDevice disconnectDeviceUseCase;
  final ListenConnectionStatus listenConnectionStatus;
  final AdvertisePresence advertisePresenceUseCase;
  final ScanForDevices scanForDevicesUseCase;

  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<List<DiscoveredDevice>>? _scanSubscription;

  ConnectionCubit({
    required this.startServerUseCase,
    required this.connectToDeviceUseCase,
    required this.disconnectDeviceUseCase,
    required this.listenConnectionStatus,
    required this.advertisePresenceUseCase,
    required this.scanForDevicesUseCase,
  }) : super(ConnectionInitial()) {
    _monitorConnectionStatus();
  }

  void _monitorConnectionStatus() {
    _statusSubscription = listenConnectionStatus().listen((status) {
      switch (status) {
        case ConnectionStatus.disconnected:
          emit(ConnectionInitial());
          break;
        case ConnectionStatus.connecting:
          emit(ConnectionLoading());
          break;
        case ConnectionStatus.connected:
          emit(const ConnectionConnected());
          break;
      }
    });
  }

  Future<void> startServer(int port) async {
    emit(ConnectionLoading());
    final result = await startServerUseCase(port);
    if (result is ResultFailure) {
      emit(ConnectionError(result.failure.message));
    } else {
      // Auto-start advertising
      await advertisePresenceUseCase(const NoParams());
    }
  }

  Future<void> connect(String ip, int port) async {
    emit(ConnectionLoading());
    final result = await connectToDeviceUseCase(
      ConnectParams(ip: ip, port: port),
    );
    if (result is ResultFailure) {
      emit(ConnectionError(result.failure.message));
    }
  }

  Future<void> disconnect() async {
    await disconnectDeviceUseCase(const NoParams());
  }

  void startScan() {
    emit(ConnectionScanning());
    _scanSubscription?.cancel();
    _scanSubscription = scanForDevicesUseCase().listen((devices) {
      emit(ConnectionDiscovered(devices));
    });
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _scanSubscription?.cancel();
    return super.close();
  }
}
