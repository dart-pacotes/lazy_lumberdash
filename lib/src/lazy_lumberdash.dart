import 'dart:async';

import 'package:lumberdash/lumberdash.dart';
import 'package:meta/meta.dart';

abstract class LazyLumberdash extends LumberdashClient {
  final LumberdashClient _innerLumberdashClient;

  final List<Function> _logCalls = [];

  bool _lock = false;

  LazyLumberdash({
    @required final LumberdashClient client,
  }) : _innerLumberdashClient = client;

  @override
  void logError(dynamic exception, [dynamic stacktrace]) {
    return registerLogCall(
      () => _innerLumberdashClient.logError(exception, stacktrace),
    );
  }

  @override
  void logFatal(String message, [Map<String, String> extras]) {
    return registerLogCall(
      () => _innerLumberdashClient.logFatal(message, extras),
    );
  }

  @override
  void logMessage(String message, [Map<String, String> extras]) {
    return registerLogCall(
      () => _innerLumberdashClient.logMessage(message, extras),
    );
  }

  @override
  void logWarning(String message, [Map<String, String> extras]) {
    return registerLogCall(
      () => _innerLumberdashClient.logWarning(message, extras),
    );
  }

  @mustCallSuper
  void registerLogCall(final void Function() call) {
    _logCalls.add(call);

    onNewLogCall(call);
  }

  @mustCallSuper
  void dispatchLogCalls() {
    if (!_lock) {
      _lock = true;
      for (var i = 0; i < _logCalls.length; i++) {
        _logCalls.removeAt(i)();
      }

      _lock = false;
    }
  }

  void onNewLogCall(final void Function() call);
}

class PeriodicLazyLumberdash extends LazyLumberdash {
  final Duration duration;

  Timer _periodicTimer;

  PeriodicLazyLumberdash({
    @required final LumberdashClient client,
    @required final this.duration,
  }) : super(client: client);

  @override
  void onNewLogCall(final void Function() call) {
    if (_periodicTimer == null) {
      Timer.periodic(
        duration,
        (_) {
          super.dispatchLogCalls();
        },
      );
    }
  }
}

class StackLazyLumberdash extends LazyLumberdash {
  final int limit;

  StackLazyLumberdash({
    @required final LumberdashClient client,
    @required final this.limit,
  }) : super(client: client);

  @override
  void onNewLogCall(final void Function() call) {
    if (super._logCalls.length >= limit) {
      super.dispatchLogCalls();
    }
  }
}
