/// Supported inventory cost valuation methods.
enum CostValuationMethod {
  /// First-In, First-Out: Oldest inventory cost layers are consumed first.
  fifo,

  /// Last-In, First-Out: Newest inventory cost layers are consumed first.
  lifo,

  /// Weighted Average: Cost is calculated as total cost / total on-hand quantity.
  weightedAverage;

  String get displayName {
    switch (this) {
      case CostValuationMethod.fifo:
        return 'الوارد أولاً يصرف أولاً (FIFO)';
      case CostValuationMethod.lifo:
        return 'الوارد أخيراً يصرف أولاً (LIFO)';
      case CostValuationMethod.weightedAverage:
        return 'المتوسط المرجح (Weighted Average)';
    }
  }
}
