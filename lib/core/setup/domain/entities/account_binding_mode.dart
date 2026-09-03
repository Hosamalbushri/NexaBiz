/// Defines whether an account requirement expects an exact transaction account
/// or a parent root account whose descendants will be dynamically resolved.
enum AccountBindingMode {
  /// The bound account itself is directly consumed by the business feature.
  exact,

  /// The bound account acts as a hierarchy root; its direct children or recursive
  /// descendants will be resolved at runtime.
  parent,
}
