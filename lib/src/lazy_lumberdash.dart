import 'dart:async';

import 'package:lumberdash/lumberdash.dart';
import 'package:meta/meta.dart';

/// [LazyLumberdash] is an abstraction of [LumberdashClient] that registers
/// log calls on an array, using `registerLogCall` to be later drained when
/// calling `dispatchLogCalls`.
///
/// The `registerLogCall` notifies the implementer using `onNewLogCall`
/// method. Implementers need to override this method so they can decide
/// when to dispatch the log calls using the `dispatchLogCalls`method.
///
/// [LazyLumberdash] also provides the method `close` which forces the
/// dispatch of all log calls. This is useful for example when exiting the app
/// and not all log calls have been sent to a server or a file.
///
/// If the implementer decides to override the `close`, `dispatchLogCalls` and
/// `registerLogCall` methods, it needs to call the super implementation in the
/// first place.
abstract class LazyLumberdash extends LumberdashClient {
  /// The [LumberdashClient] which will receive the log calls
  final LumberdashClient _innerLumberdashClient;

  /// The array that contains the log calls to be dispatch
  final List<Function> _logCalls = [];

  /// Variable to control [_logCalls] drain
  bool _lock = false;

  LazyLumberdash({
    @required final LumberdashClient client,
  }) : _innerLumberdashClient = client;

  /// Registers a [_innerLumberdashClient] `logError` call on [_logCalls]
  @override
  void logError(dynamic exception, [dynamic stacktrace]) {
    return registerLogCall(
      () => _innerLumberdashClient.logError(exception, stacktrace),
    );
  }

  /// Registers a [_innerLumberdashClient] `logFatal` call on [_logCalls]
  @override
  void logFatal(String message, [Map<String, String> extras]) {
    return registerLogCall(
      () => _innerLumberdashClient.logFatal(message, extras),
    );
  }

  /// Registers a [_innerLumberdashClient] `logMessage` call on [_logCalls]
  @override
  void logMessage(String message, [Map<String, String> extras]) {
    return registerLogCall(
      () => _innerLumberdashClient.logMessage(message, extras),
    );
  }

  /// Registers a [_innerLumberdashClient] `logWarning` call on [_logCalls]
  @override
  void logWarning(String message, [Map<String, String> extras]) {
    return registerLogCall(
      () => _innerLumberdashClient.logWarning(message, extras),
    );
  }

  /// Endpoint for [_innerLumberdashClient] log calls registry on [_logCalls].
  /// Notifies the implementer after register the call, by call `onNewLogCall`.
  @mustCallSuper
  void registerLogCall(final void Function() call) {
    _logCalls.add(call);

    onNewLogCall(call);
  }

  /// Dispatches all log calls that exist on [_logCalls] array in a FIFO order.
  /// Uses [_lock] to grant mutual exclusion access on the log calls dispatch.
  @mustCallSuper
  void dispatchLogCalls() {
    if (!_lock) {
      _lock = true;

      while (_logCalls.isNotEmpty) {
        _logCalls.removeAt(0)();
      }

      _lock = false;
    }
  }

  /// Calls `dispatchLogCalls`
  @mustCallSuper
  void close() => dispatchLogCalls();

  /// Override this method to listen to new log calls and
  /// decide whether or not you should call `dispatchLogCalls`.
  void onNewLogCall(final void Function() call);
}

/// The periodic implementation of [LazyLumberdash].
/// It receives a duration and then on the first log call
/// starts a periodic [Timer] that will call `dispatchLogCalls`
/// every `duration`.
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
      _periodicTimer = Timer.periodic(
        duration,
        (_) {
          super.dispatchLogCalls();
        },
      );
    }
  }

  @override
  void close() {
    super.close();

    _periodicTimer.cancel();
  }
}

/// The stack limit implementation of [LazyLumberdash].
/// It receives an integer that defines the limit calls that can be stored
/// in [_logCalls] before `dispatchLogCalls` is called.
///
/// Once the limit is reached or surpassed, `dispatchLogCalls` is called.
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
