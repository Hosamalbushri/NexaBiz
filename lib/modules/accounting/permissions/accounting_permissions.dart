/// Accounting permission codes used by domain use cases.
abstract final class AccountingPermissions {
  static const journalsView = ['accounting.journals.view'];
  static const journalsCreate = ['accounting.journals.create'];
  static const journalsUpdate = ['accounting.journals.update'];
  static const journalsDelete = ['accounting.journals.delete'];

  static const accountsView = ['accounting.accounts.view'];
  static const accountsCreate = ['accounting.accounts.create'];
  static const accountsUpdate = ['accounting.accounts.update'];
  static const accountsDelete = ['accounting.accounts.delete'];

  static const fiscalYearsView = ['accounting.fiscal_years.view'];
  static const fiscalYearsCreate = ['accounting.fiscal_years.create'];
  static const fiscalYearsUpdate = ['accounting.fiscal_years.update'];
  static const openPeriod = ['accounting.fiscal_years.open_period'];
  static const closePeriod = ['accounting.fiscal_years.close_period'];
  static const reopenPeriod = ['accounting.fiscal_years.reopen_period'];
  static const configureFx = ['accounting.fiscal_years.configure_fx'];
}
