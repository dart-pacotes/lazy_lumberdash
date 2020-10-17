import 'package:lazy_lumberdash/lazy_lumberdash.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockLumberdashClient extends Mock implements LumberdashClient {}

void main() {
  final mockLumberdashClient = MockLumberdashClient();

  group(
    'LazyLumberdash',
    () {
      test(
        'only dispatches log calls once per time',
        () async {
          final lazyLumberdashClient = StackLazyLumberdash(
            client: mockLumberdashClient,
            limit: 1,
          );

          concurrentLogCallsWorkCallback(final int timesToLog) {
            for (var i = 0; i < timesToLog; i++) {
              lazyLumberdashClient.logMessage('$i');
            }
          }

          final callsPerWorker = 1000;

          final workers = 25;

          final concurrentLogWorkers = List.generate(
            workers,
            (_) {
              return Future.value(
                concurrentLogCallsWorkCallback(callsPerWorker),
              );
            },
          );

          await Future.wait(concurrentLogWorkers);

          final expectedLogCallCount = workers * callsPerWorker;

          verify(mockLumberdashClient.logMessage(any)).called(
            expectedLogCallCount,
          );
        },
      );

      test(
        'dispatches log calls sequentially based on the call order',
        () {
          final callOrder = <String>[];

          when(mockLumberdashClient.logMessage(any)).thenAnswer(
            (_) {
              callOrder.add(_.positionalArguments.first);
            },
          );

          final lazyLumberdashClient = StackLazyLumberdash(
            client: mockLumberdashClient,
            limit: 3,
          );

          lazyLumberdashClient.logMessage('a');
          lazyLumberdashClient.logMessage('b');
          lazyLumberdashClient.logMessage('c');

          verify(mockLumberdashClient.logMessage(any)).called(3);

          expect(callOrder, ['a', 'b', 'c']);
        },
      );
    },
  );

  group(
    'PeriodicLumberdash',
    () {
      test(
        'dispatches log calls after every injected duration',
        () async {
          final callOrder = <String>[];

          when(mockLumberdashClient.logMessage(any)).thenAnswer(
            (_) {
              callOrder.add(_.positionalArguments.first);
            },
          );

          const duration = Duration(milliseconds: 500);

          final lazyLumberdashClient = PeriodicLazyLumberdash(
            client: mockLumberdashClient,
            duration: duration,
          );

          lazyLumberdashClient.logMessage('a');
          lazyLumberdashClient.logMessage('b');

          await Future.delayed(duration);

          verify(mockLumberdashClient.logMessage(any)).called(2);

          expect(callOrder, ['a', 'b']);

          lazyLumberdashClient.logMessage('c');

          await Future.delayed(duration);

          verify(mockLumberdashClient.logMessage(any)).called(1);

          expect(callOrder, ['a', 'b', 'c']);

          lazyLumberdashClient.close();
        },
      );
    },
  );

  group(
    'StackLumberdash',
    () {
      test(
        'does not dispatch log calls if stack limit has not been reached',
        () {
          final lazyLumberdashClient = StackLazyLumberdash(
            client: mockLumberdashClient,
            limit: 3,
          );

          lazyLumberdashClient.logMessage('a');
          lazyLumberdashClient.logMessage('b');

          verifyNever(mockLumberdashClient.logMessage(any));
        },
      );

      test(
        'dispatches log calls if stack limit has been reached',
        () {
          final lazyLumberdashClient = StackLazyLumberdash(
            client: mockLumberdashClient,
            limit: 3,
          );

          lazyLumberdashClient.logMessage('a');
          lazyLumberdashClient.logMessage('b');
          lazyLumberdashClient.logMessage('c');

          verify(mockLumberdashClient.logMessage(any)).called(3);
        },
      );
    },
  );
}
