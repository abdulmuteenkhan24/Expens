class AppCurrency {
  final String code;
  final String name;
  final String symbol;
  final String locale;
  final int decimals;

  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.locale,
    this.decimals = 0,
  });
}

/// Common currencies for Pakistan + freelancers / travel.
const supportedCurrencies = <AppCurrency>[
  AppCurrency(
    code: 'PKR',
    name: 'Pakistani Rupee',
    symbol: 'Rs ',
    locale: 'en_PK',
    decimals: 0,
  ),
  AppCurrency(
    code: 'USD',
    name: 'US Dollar',
    symbol: '\$',
    locale: 'en_US',
    decimals: 2,
  ),
  AppCurrency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    locale: 'en_EU',
    decimals: 2,
  ),
  AppCurrency(
    code: 'GBP',
    name: 'British Pound',
    symbol: '£',
    locale: 'en_GB',
    decimals: 2,
  ),
  AppCurrency(
    code: 'AED',
    name: 'UAE Dirham',
    symbol: 'AED ',
    locale: 'en_AE',
    decimals: 2,
  ),
  AppCurrency(
    code: 'SAR',
    name: 'Saudi Riyal',
    symbol: 'SAR ',
    locale: 'en_SA',
    decimals: 2,
  ),
  AppCurrency(
    code: 'INR',
    name: 'Indian Rupee',
    symbol: '₹',
    locale: 'en_IN',
    decimals: 0,
  ),
  AppCurrency(
    code: 'CNY',
    name: 'Chinese Yuan',
    symbol: '¥',
    locale: 'en_CN',
    decimals: 2,
  ),
  AppCurrency(
    code: 'CAD',
    name: 'Canadian Dollar',
    symbol: 'CA\$',
    locale: 'en_CA',
    decimals: 2,
  ),
  AppCurrency(
    code: 'AUD',
    name: 'Australian Dollar',
    symbol: 'A\$',
    locale: 'en_AU',
    decimals: 2,
  ),
];

AppCurrency currencyByCode(String code) {
  return supportedCurrencies.firstWhere(
    (c) => c.code == code,
    orElse: () => supportedCurrencies.first,
  );
}

/// Default rates: how many units of [primary] equal 1 unit of [code].
/// User can edit these in Settings. Example: 1 USD = 278 PKR.
const defaultRatesToPkr = <String, double>{
  'PKR': 1,
  'USD': 278,
  'EUR': 300,
  'GBP': 350,
  'AED': 76,
  'SAR': 74,
  'INR': 3.3,
  'CNY': 38,
  'CAD': 200,
  'AUD': 180,
};
