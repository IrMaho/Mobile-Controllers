import 'package:get_it/get_it.dart';
import 'package:mobail_contorolers/features/connection/data/repositories/connection_repository_impl.dart';
import 'package:mobail_contorolers/features/connection/domain/repositories/connection_repository.dart';
import 'package:mobail_contorolers/features/connection/domain/usecases/connect_to_device.dart';
import 'package:mobail_contorolers/features/connection/domain/usecases/disconnect_device.dart';
import 'package:mobail_contorolers/features/connection/domain/usecases/listen_connection_status.dart';
import 'package:mobail_contorolers/features/connection/domain/usecases/start_server.dart';
import 'package:mobail_contorolers/features/connection/presentation/cubit/connection_cubit.dart';
import 'package:mobail_contorolers/features/connection/domain/usecases/advertise_presence.dart';
import 'package:mobail_contorolers/features/connection/domain/usecases/scan_for_devices.dart';
import 'package:mobail_contorolers/features/input_capture/presentation/cubit/input_capture_cubit.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Core
  // getIt.registerLazySingleton<NetworkService>(() => NetworkServiceImpl());

  // Features
  _setupConnectionFeature();
  _setupInputCaptureFeature();
}

void _setupInputCaptureFeature() {
  // Cubit - needs ConnectionRepository
  getIt.registerFactory(() => InputCaptureCubit(connectionRepository: getIt()));
}

void _setupConnectionFeature() {
  // Repository
  getIt.registerLazySingleton<ConnectionRepository>(
    () => ConnectionRepositoryImpl(),
  );

  // UseCases
  getIt.registerLazySingleton(() => StartServer(getIt()));
  getIt.registerLazySingleton(() => ConnectToDevice(getIt()));
  getIt.registerLazySingleton(() => DisconnectDevice(getIt()));
  getIt.registerLazySingleton(() => ListenConnectionStatus(getIt()));
  getIt.registerLazySingleton(() => AdvertisePresence(getIt()));
  getIt.registerLazySingleton(() => ScanForDevices(getIt()));

  // Cubit
  getIt.registerFactory(
    () => ConnectionCubit(
      startServerUseCase: getIt(),
      connectToDeviceUseCase: getIt(),
      disconnectDeviceUseCase: getIt(),
      listenConnectionStatus: getIt(),
      advertisePresenceUseCase: getIt(),
      scanForDevicesUseCase: getIt(),
    ),
  );
}
