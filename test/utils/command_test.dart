import 'package:articly/utils/command.dart';
import 'package:checks/checks.dart';
import 'package:test/test.dart';

void main() {
  group('Command', () {
    test(
      'initially has running = false, error = null, completed = false, and hasError is false',
      () {
        final command = Command();

        check(command.running).isFalse();
        check(command.error).isNull();
        check(command.completed).isFalse();
        check(command.hasError).isFalse();
      },
    );

    group('finish', () {
      test('sets completed to true when there is no error message', () {
        final command = Command();

        command.finish(null);

        check(command.running).isFalse();
        check(command.error).isNull();
        check(command.completed).isTrue();
        check(command.hasError).isFalse();
      });

      test('sets completed to false when there is an error message', () {
        final command = Command();

        command.finish('Something went wrong');

        check(command.running).isFalse();
        check(command.error).equals('Something went wrong');
        check(command.completed).isFalse();
        check(command.hasError).isTrue();
      });
    });

    group('successful', () {
      test('sets running to false, error to null, and completed to true', () {
        final command = Command();

        command.successful();

        check(command.running).isFalse();
        check(command.error).isNull();
        check(command.completed).isTrue();
        check(command.hasError).isFalse();
      });
    });

    group('problem', () {
      test(
        'sets running to false, error to the given message, and completed to false',
        () {
          final command = Command();

          command.problem('An error occurred');

          check(command.running).isFalse();
          check(command.error).equals('An error occurred');
          check(command.completed).isFalse();
          check(command.hasError).isTrue();
        },
      );
    });

    group('clear', () {
      test('resets running, error, and completed to their initial values', () {
        final command = Command();
        command.running = true;
        command.error = 'some error';
        command.completed = true;

        command.clear();

        check(command.running).isFalse();
        check(command.error).isNull();
        check(command.completed).isFalse();
        check(command.hasError).isFalse();
      });
    });
  });
}
