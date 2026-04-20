class PlayerEconomy {
  const PlayerEconomy({
    required this.credits,
    required this.premiumCredits,
  });

  final int credits;
  final int premiumCredits;

  bool isValid({
    required int maxCredits,
    required int maxPremiumCredits,
  }) {
    return credits >= 0 &&
        premiumCredits >= 0 &&
        credits <= maxCredits &&
        premiumCredits <= maxPremiumCredits;
  }

  PlayerEconomy toSanitized({
    required int maxCredits,
    required int maxPremiumCredits,
  }) {
    return PlayerEconomy(
      credits: credits.clamp(0, maxCredits),
      premiumCredits: premiumCredits.clamp(0, maxPremiumCredits),
    );
  }

  PlayerEconomy copyWith({
    int? credits,
    int? premiumCredits,
  }) {
    return PlayerEconomy(
      credits: credits ?? this.credits,
      premiumCredits: premiumCredits ?? this.premiumCredits,
    );
  }
}
