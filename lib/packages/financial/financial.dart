// Financial Package Public API Export

// Domain Primitives
export 'domain/common/financial_exceptions.dart';
export 'domain/money/decimal_money.dart';
export 'domain/money/decimal_rate.dart';
export 'domain/money/canonical_rounding_policy.dart';
export 'domain/currency/currency.dart';

// Domain Entities
export 'domain/account/account_currency_policy.dart';
export 'domain/account/financial_account.dart';
export 'domain/subject/accounting_subject.dart';
export 'domain/subject/subject_account_bucket.dart';
export 'domain/exchange_rate/exchange_rate_snapshot.dart';
export 'domain/journal/financial_side.dart';
export 'domain/journal/journal_status.dart';
export 'domain/journal/journal_line.dart';
export 'domain/journal/journal_entry.dart';

// Validation & Projections & Posting
export 'validation/financial_validator.dart';
export 'validation/financial_int64_boundary.dart';
export 'domain/projection/financial_projection_reconstruction_service.dart';
export 'domain/posting/posting_engine.dart';
export 'domain/posting/financial_posting_command.dart';
export 'domain/posting/financial_posting_port.dart';
export 'domain/posting/financial_posting_service.dart';

// Provisioning & Binding Services
export 'domain/provisioning/account_code_generator.dart';
export 'domain/provisioning/customer_accounting_provisioning_service.dart';
export 'domain/provisioning/supplier_accounting_provisioning_service.dart';
export 'domain/binding/subject_account_binding_service.dart';
export 'domain/resolution/canonical_account_resolver_service.dart';

// GATE-08 V4 Fiscal Period & Closing Domain Services
export 'domain/fiscal_period/fiscal_year.dart';
export 'domain/fiscal_period/fiscal_period.dart';
export 'domain/fiscal_period/fiscal_period_state_machine.dart';
export 'domain/fiscal_period/financial_period_resolver.dart';
export 'domain/fiscal_period/financial_period_gate.dart';
export 'domain/closing/fx_revaluation_engine.dart';
export 'domain/closing/period_closing_operation_service.dart';
export 'domain/closing/year_end_closing_engine.dart';

// Repositories & Infrastructure
export 'infrastructure/repositories/financial_account_repository.dart';
export 'infrastructure/repositories/financial_subject_repository.dart';
export 'infrastructure/repositories/exchange_rate_repository.dart';
export 'infrastructure/repositories/financial_journal_repository.dart';
export 'infrastructure/persistence/drift_financial_repositories.dart';
