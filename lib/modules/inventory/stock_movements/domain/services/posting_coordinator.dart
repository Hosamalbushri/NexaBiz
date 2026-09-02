import 'package:stock_count/core/domain/entities/document_ref.dart';
import 'package:stock_count/core/domain/ports/posting_port.dart';

export 'package:stock_count/core/domain/ports/posting_port.dart'
    show
        PostingCoordinatorPort,
        PostResult,
        PostSuccess,
        PostStockShortage,
        PostInvalidStatus,
        UnpostResult,
        UnpostSuccess,
        UnpostBlockedByDependencies,
        UnpostInvalidStatus;

abstract class PostingCoordinator implements PostingCoordinatorPort {
  /// Validates and posts an inventory document.
  @override
  Future<PostResult> post({
    required DocumentRef document,
    String? userId,
  });

  /// Validates dependencies and unposts an inventory document.
  @override
  Future<UnpostResult> unpost({
    required DocumentRef document,
    String? requestedBy,
    String? reason,
  });
}
