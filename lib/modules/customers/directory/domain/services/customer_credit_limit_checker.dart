import '../entities/customer.dart';
import '../models/customer_exception.dart';

/// Enforces customer credit limits and status checks when creating financial exposure.
class CustomerCreditLimitChecker {
  const CustomerCreditLimitChecker();

  /// Validates whether a customer can undertake a new financial exposure.
  ///
  /// Throws [CustomerException] if the customer is blocked or if the projected balance
  /// (`currentOutstandingBalance + proposedExposureAmount`) exceeds the customer's credit limit.
  void validateExposure({
    required Customer customer,
    required double currentOutstandingBalance,
    required double proposedExposureAmount,
  }) {
    if (customer.status == CustomerStatus.blocked) {
      throw const CustomerException(
        'customer_blocked',
        'Customer is blocked from new credit transactions.',
      );
    }

    if (customer.creditLimit == null || customer.creditLimit! <= 0) {
      // Unrestricted / no credit limit configured.
      return;
    }

    final projectedBalance = currentOutstandingBalance + proposedExposureAmount;
    if (projectedBalance > customer.creditLimit!) {
      throw CustomerException(
        CustomerException.creditLimitExceeded,
        'Projected customer balance ($projectedBalance) exceeds credit limit (${customer.creditLimit}).',
      );
    }
  }
}
