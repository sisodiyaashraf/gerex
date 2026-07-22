import 'failures.dart';

sealed class Result<S, F extends Failure> {
  const Result();

  /// Execute `onSuccess` if result is Success, `onFailure` if FailureResult.
  T fold<T>({
    required T Function(S value) onSuccess,
    required T Function(F error) onFailure,
  }) {
    if (this is Success<S, F>) {
      return onSuccess((this as Success<S, F>).value);
    } else if (this is FailureResult<S, F>) {
      return onFailure((this as FailureResult<S, F>).error);
    }
    throw AssertionError('Invalid state');
  }

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is FailureResult<S, F>;

  S? getOrNull() {
    if (this is Success<S, F>) {
      return (this as Success<S, F>).value;
    }
    return null;
  }
}

class Success<S, F extends Failure> extends Result<S, F> {
  final S value;
  const Success(this.value);
}

class FailureResult<S, F extends Failure> extends Result<S, F> {
  final F error;
  const FailureResult(this.error);
}
