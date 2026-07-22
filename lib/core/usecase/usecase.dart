import '../error/failures.dart';
import '../error/result.dart';

abstract class UseCase<T, Params> {
  Future<Result<T, Failure>> call(Params params);
}

class NoParams {
  const NoParams();
}
