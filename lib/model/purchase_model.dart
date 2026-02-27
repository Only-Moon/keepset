import 'package:flutter/foundation.dart';

class PurchaseProductDetails {
  final String price;
  final String productId;
  final String duration;
  final String durationPlanName;
  final bool hasTrial;

  const PurchaseProductDetails({
    required this.price,
    required this.productId,
    required this.duration,
    required this.durationPlanName,
    required this.hasTrial,
  });
}

class PurchaseModel extends ChangeNotifier {
  bool isSubscribed = false;
  bool isPurchasing = false;
  bool isFetchingProducts = false;

  final List<String> productIds = ['demo_y', 'demo_w'];

  final List<PurchaseProductDetails> productDetails = const [
    PurchaseProductDetails(
      price: '\$25.99',
      productId: 'demo_y',
      duration: 'year',
      durationPlanName: 'Yearly Plan',
      hasTrial: false,
    ),
    PurchaseProductDetails(
      price: '\$4.99',
      productId: 'demo_w',
      duration: 'week',
      durationPlanName: '3-Day Trial',
      hasTrial: true,
    ),
  ];

  void purchaseSubscription(String productId) async {
    isPurchasing = true;
    notifyListeners();

    // ⛔ STUB: real billing later
    await Future.delayed(const Duration(seconds: 2));

    isSubscribed = true;
    isPurchasing = false;
    notifyListeners();
  }

  void restorePurchases() async {
    // ⛔ STUB
  }
}
