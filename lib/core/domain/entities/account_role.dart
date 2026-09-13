import '../../setup/domain/entities/account_binding_mode.dart';
import '../ports/setup_account_lookup_port.dart';

export '../../setup/domain/entities/account_binding_mode.dart';

enum AccountRole {
  revenue,
  receivable,
  payable,
  cash,
  bank,
  inventory,
  cogs,
  tax,
  discount,
  inventoryFrom,
  inventoryTo,
  adjustment,
  fxGainLoss,
  taxInput,
  purchaseDiscount,
  retainedEarnings,
  openingEquity;

  SetupAccountType get expectedAccountType {
    switch (this) {
      case AccountRole.revenue:
      case AccountRole.discount:
      case AccountRole.purchaseDiscount:
      case AccountRole.fxGainLoss:
        return SetupAccountType.revenue;
      case AccountRole.receivable:
      case AccountRole.cash:
      case AccountRole.bank:
      case AccountRole.inventory:
      case AccountRole.inventoryFrom:
      case AccountRole.inventoryTo:
      case AccountRole.taxInput:
        return SetupAccountType.asset;
      case AccountRole.payable:
      case AccountRole.tax:
        return SetupAccountType.liability;
      case AccountRole.retainedEarnings:
      case AccountRole.openingEquity:
        return SetupAccountType.equity;
      case AccountRole.cogs:
      case AccountRole.adjustment:
        return SetupAccountType.expense;
    }
  }

  AccountBindingMode get defaultBindingMode {
    switch (this) {
      case AccountRole.receivable:
      case AccountRole.payable:
      case AccountRole.cash:
        return AccountBindingMode.parentAccountWithDescendants;
      default:
        return AccountBindingMode.singleAccount;
    }
  }

  bool get isParentGroupBinding {
    return defaultBindingMode ==
        AccountBindingMode.parentAccountWithDescendants;
  }
}
