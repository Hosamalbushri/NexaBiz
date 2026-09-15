import '../../domain/subject/accounting_subject.dart';
import '../../domain/subject/subject_account_bucket.dart';

/// Repository port interface for Accounting Subjects & Multi-Currency Buckets.
abstract class FinancialSubjectRepository {
  Future<void> saveSubject(AccountingSubject subject);
  Future<AccountingSubject?> findSubjectById(String companyId, String id);
  Future<AccountingSubject?> findSubjectByCode(
    String companyId,
    AccountingSubjectType subjectType,
    String code,
  );
  Future<AccountingSubject?> findSubjectByPrimaryAccountId(String companyId, String accountId);
  Future<SubjectAccountBucket?> getBucket({
    required String companyId,
    required String subjectId,
    required String accountId,
    required String currencyCode,
  });
  Future<void> updateBucketBalance(SubjectAccountBucket bucket);
}
