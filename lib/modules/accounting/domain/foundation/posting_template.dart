import 'package:equatable/equatable.dart';
import 'package:stock_count/core/domain/entities/account_role.dart';

enum LineSide { debit, credit }

class TemplateLineDefinition extends Equatable {
  const TemplateLineDefinition({
    required this.role,
    required this.side,
    required this.amountKey,
    this.isOptional = false,
    this.lineDescriptionTemplate,
  });

  final AccountRole role;
  final LineSide side;
  final String amountKey;
  final bool isOptional;
  final String? lineDescriptionTemplate;

  @override
  List<Object?> get props => [
        role,
        side,
        amountKey,
        isOptional,
        lineDescriptionTemplate,
      ];
}

class PostingTemplate extends Equatable {
  const PostingTemplate({
    required this.templateId,
    required this.sourceType,
    required this.voucherType,
    required this.lines,
  });

  final String templateId;
  final String sourceType;
  final String voucherType;
  final List<TemplateLineDefinition> lines;

  @override
  List<Object?> get props => [templateId, sourceType, voucherType, lines];
}
