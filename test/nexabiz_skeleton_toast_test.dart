import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexabiz_ui/nexabiz_ui.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  group('Skeleton Primitives & AppLoading Behavioral Tests', () {
    testWidgets('AppLoadingStyle.skeletonList renders canonical skeleton placeholder via .asSkeleton()', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: const shadcn.Scaffold(
            child: AppLoading(
              style: AppLoadingStyle.skeletonList,
              skeletonItemCount: 3,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('Loading item title placeholder'), findsNWidgets(3));
    });

    testWidgets('asSkeleton extension transforms widget into skeleton placeholder', (tester) async {
      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.Scaffold(
            child: const Text('Sample Text Content').asSkeleton(),
          ),
        ),
      );

      expect(find.text('Sample Text Content'), findsOneWidget);
    });
  });

  group('Toast Layer & Overlay Behavioral Tests', () {
    testWidgets('showToast displays notification inside ToastLayer and supports close', (tester) async {
      shadcn.ToastOverlay? overlayController;

      await tester.pumpWidget(
        shadcn.ShadcnApp(
          home: shadcn.ToastLayer(
            child: shadcn.Scaffold(
              child: Builder(
                builder: (context) {
                  return shadcn.PrimaryButton(
                    onPressed: () {
                      overlayController = shadcn.showToast(
                        context: context,
                        location: shadcn.ToastLocation.topRight,
                        showDuration: const Duration(seconds: 10),
                        builder: (context, overlay) {
                          return Container(
                            key: const ValueKey('toast_content'),
                            child: const Text('Operation Successful Toast'),
                          );
                        },
                      );
                    },
                    child: const Text('Trigger Toast'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap to trigger toast
      await tester.tap(find.text('Trigger Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('toast_content')), findsOneWidget);
      expect(find.text('Operation Successful Toast'), findsOneWidget);
      expect(overlayController, isNotNull);
      expect(overlayController!.isShowing, isTrue);

      // Dismiss programmatically
      overlayController!.close();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));

      expect(find.byKey(const ValueKey('toast_content')), findsNothing);
    });

    testWidgets('showAppSnackBar calls registered handler correctly', (tester) async {
      String? capturedMessage;
      bool? capturedSuccess;

      registerAppSnackBarHandler((
        context, {
        required message,
        required isSuccess,
        duration,
        persistToHistory = false,
      }) {
        capturedMessage = message;
        capturedSuccess = isSuccess;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAppSnackBar(
                      context,
                      message: 'Test notification',
                      isSuccess: true,
                    );
                  },
                  child: const Text('Show SnackBar'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      expect(capturedMessage, equals('Test notification'));
      expect(capturedSuccess, isTrue);
    });
  });
}
