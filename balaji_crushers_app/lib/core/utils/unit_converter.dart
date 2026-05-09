class UnitConverter {
  UnitConverter._();

  // 1 brass = 100 cubic feet
  // Standard conversion: 1 brass ≈ 4.5 tons (for stone products)
  static const double brassToTonsFactor = 4.5;

  static double brassToTons(double brass) {
    return brass * brassToTonsFactor;
  }

  static double tonsToBrass(double tons) {
    return tons / brassToTonsFactor;
  }

  static String formatBrass(double value) {
    return '${value.toStringAsFixed(2)} Brass';
  }

  static String formatTons(double value) {
    return '${value.toStringAsFixed(2)} Tons';
  }

  // Format currency in Indian rupees
  static String formatRupees(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(2)} K';
    }
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Format large numbers
  static String formatNumber(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}