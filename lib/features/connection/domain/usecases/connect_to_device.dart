import 'package:equatable/equatable.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/connection_repository.dart';

class ConnectToDevice implements UseCase<void, ConnectParams> {
  final ConnectionRepository repository;

  ConnectToDevice(this.repository);

  @override
  Future<Result<void>> call(ConnectParams params) async {
    return await repository.connect(params.ip, params.port);
  }
}

class ConnectParams extends Equatable {
  final String ip;
  final int port;

  const ConnectParams({required this.ip, required this.port});

  @override
  List<Object> get props => [ip, port];
}
