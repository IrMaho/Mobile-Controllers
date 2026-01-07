import '../repositories/connection_repository.dart';

class ScanForDevices {
  final ConnectionRepository repository;

  ScanForDevices(this.repository);

  Stream<List<DiscoveredDevice>> call() {
    return repository.scanForDevices();
  }
}
