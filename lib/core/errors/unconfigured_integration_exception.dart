import 'package:stock_count/modules/accounting/journals/domain/models/journal_exception.dart';

/// Thrown when an integrated business operation requires accounting ledger posting
/// or account resolution, but the accounting integration is missing or unconfigured.
class UnconfiguredIntegrationException extends JournalException {
  const UnconfiguredIntegrationException([
    super.message = 'التكامل المحاسبي غير مهيأ أو غير متاح في الوضع المتكامل.',
  ]);

  @override
  String toString() => 'UnconfiguredIntegrationException: $message';
}
