// lib/utils/premium_gate.dart

enum PremiumAction {
  aiUse,
  addWidget,
  enableBackup,
  restoreBackup,
  advancedHomeToggle,
}

enum GateReason {
  requiresSubscription,
}

sealed class GateResult {
  const GateResult();
}

class GateAllowed extends GateResult {
  const GateAllowed();
}

class GateBlocked extends GateResult {
  final GateReason reason;
  const GateBlocked(this.reason);
}
