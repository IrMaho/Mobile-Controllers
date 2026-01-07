import '../repositories/connection_repository.dart';

class ListenConnectionStatus {
  final ConnectionRepository repository;

  ListenConnectionStatus(this.repository);

  Stream<ConnectionStatus> call() {
    return repository.status;
  }
}
