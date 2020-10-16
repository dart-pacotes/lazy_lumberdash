import 'package:lazy_lumberdash/lazy_lumberdash.dart';
import 'package:print_lumberdash/print_lumberdash.dart';

void main() {
  putLumberdashToWork(
    withClients: [
      StackLazyLumberdash(
        limit: 5,
        client: PrintLumberdash(),
      ),
    ],
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
}
