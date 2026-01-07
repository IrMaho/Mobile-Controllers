import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/connection_repository.dart';

class StartServer implements UseCase<void, int> {
  final ConnectionRepository repository;

  StartServer(this.repository);

  @override
  Future<Result<void>> call(int port) async {
    return await repository.startServer(port);
  }
}
