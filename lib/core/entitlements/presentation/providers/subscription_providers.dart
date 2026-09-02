import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl();
});

final availablePlansProvider = FutureProvider<List<CommercialPlan>>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchPlans();
});

final availablePackagesProvider = FutureProvider<List<AddonPackage>>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchPackages();
});
