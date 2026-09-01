abstract class PeriodValidatorPort {
  Future<void> assertEntryAllowed(DateTime entryDate);
  Future<void> assertMutationAllowed({
    required DateTime entryDate,
    DateTime? originalDate,
  });
}
