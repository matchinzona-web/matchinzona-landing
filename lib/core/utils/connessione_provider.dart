import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final connessioneProvider = StreamProvider<bool>((ref) async* {
  final internet = InternetConnection();

  final iniziale = await internet.hasInternetAccess;
  yield iniziale;

  await for (final status in internet.onStatusChange) {
    yield status == InternetStatus.connected;
  }
});
