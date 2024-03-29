import 'package:lazy_lumberdash/lazy_lumberdash.dart';

class PrintLumberdash extends LumberdashClient {
  @override
  void logError(exception, [stacktrace]) {
    print('logError');

    print(exception);
    print(stacktrace);
  }

  @override
  void logFatal(String message, [Map<String, String>? extras]) {
    print('logFatal');

    print(message);
    print(extras);
  }

  @override
  void logMessage(String message, [Map<String, String>? extras]) {
    print('logMessage');

    print(message);
    print(extras);
  }

  @override
  void logWarning(String message, [Map<String, String>? extras]) {
    print('logWarning');

    print(message);
    print(extras);
  }
}

void main() async {
  // Using StackLazyLumberdash

  final stackLazyLumberdash = StackLazyLumberdash(
    limit: 5,
    client: PrintLumberdash(),
  );

  putLumberdashToWork(
    withClients: [stackLazyLumberdash],
  );

  logMessage('#1 - This message should not trigger lazy lumberdash');

  print('#2 - This message must be logged before #1');

  logWarning('#3 - This message should not trigger lazy lumberdash');

  print('#4 - This message must be logged before #3');

  logFatal('#5 - This message should not trigger lazy lumberdash');

  print('#6 - This message must be logged before #5');

  logError('#7 - This message should not trigger lazy lumberdash');

  print('#8 - This message must be logged before #7');

  logMessage('#9 - This message must trigger lazy lumberdash');

  print('#10 - This message must be logged after #9');

  // Using PeriodicLazyLumberdash

  final periodicLazyLumberdash = PeriodicLazyLumberdash(
    duration: const Duration(seconds: 3),
    client: PrintLumberdash(),
  );

  putLumberdashToWork(
    withClients: [periodicLazyLumberdash],
  );

  logMessage('#1 - This message should not trigger lazy lumberdash');

  print('#2 - This message must be logged before #1');

  await Future.delayed(const Duration(seconds: 3));

  print('#3 - This message must be logged after #1');

  periodicLazyLumberdash.close();
}
