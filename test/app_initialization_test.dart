import 'package:flutter_test/flutter_test.dart';
import 'package:stock_count/app/bootstrap/app_initialization_state.dart';
import 'package:stock_count/core/errors/app_error_domain.dart';

void main() {
  group('InitializationState Unit Tests', () {
    test('Initial state is notStarted', () {
      const state = InitializationState.notStarted();
      expect(state.status, equals(InitializationStatus.notStarted));
      expect(state.isNotStarted, isTrue);
      expect(state.canOperate, isFalse);
    });

    test('State ready allows operation', () {
      const state = InitializationState(
        status: InitializationStatus.ready,
        stage: InitializationStage.applicationReady,
      );
      expect(state.isReady, isTrue);
      expect(state.canOperate, isTrue);
    });

    test('State degraded allows operation', () {
      const state = InitializationState(
        status: InitializationStatus.degraded,
        stage: InitializationStage.applicationReady,
        error: AppError(
          category: AppErrorCategory.network,
          message: 'Network offline during sync init',
        ),
      );
      expect(state.isDegraded, isTrue);
      expect(state.canOperate, isTrue);
    });

    test('State setupRequired allows operation for setup flow', () {
      const state = InitializationState(
        status: InitializationStatus.setupRequired,
        isFirstLaunch: true,
      );
      expect(state.isSetupRequired, isTrue);
      expect(state.canOperate, isTrue);
    });

    test('State failed blocks operation', () {
      const state = InitializationState(
        status: InitializationStatus.failed,
        error: AppError(
          category: AppErrorCategory.database,
          message: 'Corrupted database',
          severity: FailureSeverity.fatal,
        ),
      );
      expect(state.isFailed, isTrue);
      expect(state.canOperate, isFalse);
    });
  });

  group('AppError Classification Tests', () {
    test('Classifies network error correctly as recoverable', () {
      final error = classifyAppError('SocketException: Failed host lookup');
      expect(error.category, equals(AppErrorCategory.network));
      expect(error.isRecoverable, isTrue);
    });

    test('Classifies corrupted database error as fatal', () {
      final error = classifyAppError('Database corrupt or unusable box');
      expect(error.category, equals(AppErrorCategory.database));
      expect(error.isFatal, isTrue);
    });

    test('Classifies TLS error as recoverable', () {
      final error = classifyAppError('HandshakeException: TLS certificate error');
      expect(error.category, equals(AppErrorCategory.tlsCertificate));
      expect(error.isRecoverable, isTrue);
    });
  });
}
