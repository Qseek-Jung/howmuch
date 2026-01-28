class SplitResult {
  final double perPersonRounded;
  final double surplus;
  final double totalCollected;

  SplitResult({
    required this.perPersonRounded,
    required this.surplus,
    required this.totalCollected,
  });
}

class SplitCalculator {
  static SplitResult calculateSplit({
    required double totalAmount,
    required int peopleCount,
    required int roundUnit,
  }) {
    if (peopleCount <= 0) {
      return SplitResult(perPersonRounded: 0, surplus: 0, totalCollected: 0);
    }

    // 1. Exact amount
    double perPersonExact = totalAmount / peopleCount;

    // 2. Rounded up per person
    // Example: 50,000 / 3 = 16,666.666
    // If roundUnit is 1,000:
    // ceil(16.666) * 1,000 = 17,000
    double perPersonRounded =
        (perPersonExact / roundUnit).ceilToDouble() * roundUnit;

    // 3. Total collected
    double totalCollected = perPersonRounded * peopleCount;

    // 4. Surplus (Gunda-bo-zzi)
    double surplus = totalCollected - totalAmount;

    return SplitResult(
      perPersonRounded: perPersonRounded,
      surplus: surplus,
      totalCollected: totalCollected,
    );
  }
}
