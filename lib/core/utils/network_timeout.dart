import 'dart:async';

Future<T> conTimeoutRete<T>(
  Future<T> future, {
  Duration timeout = const Duration(seconds: 8),
}) {
  return future.timeout(
    timeout,
    onTimeout: () {
      throw TimeoutException('La richiesta ha impiegato troppo tempo.');
    },
  );
}
