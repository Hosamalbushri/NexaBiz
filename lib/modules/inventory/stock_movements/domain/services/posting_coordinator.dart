import 'package:equatable/equatable.dart';
import 'package:stock_count/modules/inventory/shared/domain/entities/inventory_document_ref.dart';
import 'stock_validation_service.dart';

sealed class PostResult extends Equatable {
  const PostResult();
}

class PostSuccess extends PostResult {
  const PostSuccess({
    required this.document,
    required this.postedValue,
  });

  final InventoryDocumentRef document;
  final double postedValue;

  @override
  List<Object?> get props => [document, postedValue];
}

class PostStockShortage extends PostResult {
  const PostStockShortage({
    required this.shortages,
  });

  final List<StockShortageItem> shortages;

  @override
  List<Object?> get props => [shortages];
}

class PostInvalidStatus extends PostResult {
  const PostInvalidStatus({
    required this.reason,
  });

  final String reason;

  @override
  List<Object?> get props => [reason];
}

sealed class UnpostResult extends Equatable {
  const UnpostResult();
}

class UnpostSuccess extends UnpostResult {
  const UnpostSuccess();

  @override
  List<Object?> get props => [];
}

class UnpostBlockedByDependencies extends UnpostResult {
  const UnpostBlockedByDependencies({
    required this.dependentDocuments,
    required this.message,
  });

  final List<InventoryDocumentRef> dependentDocuments;
  final String message;

  @override
  List<Object?> get props => [dependentDocuments, message];
}

class UnpostInvalidStatus extends UnpostResult {
  const UnpostInvalidStatus({
    required this.reason,
  });

  final String reason;

  @override
  List<Object?> get props => [reason];
}

abstract class PostingCoordinator {
  /// Validates and posts an inventory document.
  Future<PostResult> post({
    required InventoryDocumentRef document,
    String? userId,
  });

  /// Validates dependencies and unposts an inventory document.
  Future<UnpostResult> unpost({
    required InventoryDocumentRef document,
    String? requestedBy,
    String? reason,
  });
}
