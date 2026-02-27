import 'package:flutter/material.dart';

import '../db/settings_database.dart';
import '../model/purchase_model.dart';
import '../theme/keepset_colors.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  late final PurchaseModel model;

  bool freeTrial = true;
  String selectedProductId = '';

  @override
  void initState() {
    super.initState();
    model = PurchaseModel();
    selectedProductId = model.productIds.last;
    model.addListener(_onModelUpdate);
  }

  @override
  void dispose() {
    model.removeListener(_onModelUpdate);
    super.dispose();
  }

  void _onModelUpdate() async {
    if (model.isSubscribed) {
      await SettingsDatabase.instance.setBool('is_premium', true);
      if (mounted) Navigator.pop(context);
    }
    setState(() {});
  }

  String get callToActionText {
    final product = model.productDetails
        .firstWhere((p) => p.productId == selectedProductId);
    return product.hasTrial ? 'Start Free Trial' : 'Unlock Now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KeepsetColors.base,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'Unlock Premium Access',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: KeepsetColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              for (final product in model.productDetails) _planTile(product),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                value: freeTrial,
                onChanged: (v) {
                  setState(() {
                    freeTrial = v;
                    selectedProductId =
                        v ? model.productIds.last : model.productIds.first;
                  });
                },
                title: Text(
                  'Free Trial Enabled',
                  style: TextStyle(color: KeepsetColors.textPrimary),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KeepsetColors.layer3,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: model.isPurchasing
                    ? null
                    : () => model.purchaseSubscription(selectedProductId),
                child: model.isPurchasing
                    ? const CircularProgressIndicator()
                    : Text(
                        callToActionText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planTile(PurchaseProductDetails p) {
    final selected = selectedProductId == p.productId;

    return GestureDetector(
      onTap: () => setState(() => selectedProductId = p.productId),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? KeepsetColors.layer3 : KeepsetColors.textMuted,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.durationPlanName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: KeepsetColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${p.price} per ${p.duration}',
                    style: TextStyle(color: KeepsetColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: KeepsetColors.layer3,
            )
          ],
        ),
      ),
    );
  }
}
