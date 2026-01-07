import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/connection_repository.dart';

class DisconnectDevice implements UseCase<void, NoParams> {
  final ConnectionRepository repository;

  DisconnectDevice(this.repository);

  @override
  Future<Result<void>> call(NoParams params) async {
    return await repository.disconnect();
  }
}
