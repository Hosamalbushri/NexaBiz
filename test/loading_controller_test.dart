import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/core/services/loading_controller.dart';

void main() {
  group('LoadingController', () {
    test('show/hide uses reference counting', () {
      final controller = LoadingController();
      expect(controller.isVisible, isFalse);

      controller.show(message: 'A');
      expect(controller.isVisible, isTrue);
      expect(controller.message, 'A');
      expect(controller.depth, 1);

      controller.show(message: 'B');
      expect(controller.depth, 2);
      expect(controller.message, 'B');

      controller.hide();
      expect(controller.isVisible, isTrue);
      expect(controller.depth, 1);

      controller.hide();
      expect(controller.isVisible, isFalse);
      expect(controller.message, isNull);
    });

    test('run hides overlay after success', () async {
      final controller = LoadingController();
      final value = await controller.run(
        message: 'Working',
        action: () async {
          expect(controller.isVisible, isTrue);
          return 42;
        },
      );
      expect(value, 42);
      expect(controller.isVisible, isFalse);
    });

    test('run hides overlay after exception', () async {
      final controller = LoadingController();
      await expectLater(
        () => controller.run(
          message: 'Boom',
          action: () async {
            throw StateError('fail');
          },
        ),
        throwsA(isA<StateError>()),
      );
      expect(controller.isVisible, isFalse);
      expect(controller.depth, 0);
    });

    test('nested run keeps overlay until outer finishes', () async {
      final controller = LoadingController();
      await controller.run(
        message: 'Outer',
        action: () async {
          await controller.run(
            message: 'Inner',
            action: () async {
              expect(controller.depth, 2);
            },
          );
          expect(controller.isVisible, isTrue);
          expect(controller.depth, 1);
        },
      );
      expect(controller.isVisible, isFalse);
    });
  });
}
