import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/connection_repository.dart';

class AdvertisePresence implements UseCase<void, NoParams> {
  final ConnectionRepository repository;

  AdvertisePresence(this.repository);

  @override
  Future<Result<void>> call(NoParams params) async {
    return await repository.startAdvertising();
  }
}
