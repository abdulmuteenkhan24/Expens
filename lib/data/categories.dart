import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Icon-grid categories for the add-expense flow.
const expenseCategories = <AppCategory>[
  AppCategory(
    id: 'personal',
    name: 'Personal',
    icon: Icons.person_rounded,
    color: Color(0xFF7E57C2),
  ),
  AppCategory(
    id: 'family',
    name: 'Family',
    icon: Icons.family_restroom_rounded,
    color: Color(0xFFEC407A),
  ),
  AppCategory(
    id: 'home',
    name: 'Home',
    icon: Icons.home_work_rounded,
    color: Color(0xFF8D6E63),
  ),
  AppCategory(
    id: 'rent',
    name: 'Rent',
    icon: Icons.home_rounded,
    color: Color(0xFF9B5DE5),
  ),
  AppCategory(
    id: 'food',
    name: 'Food & Drink',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFF6B6B),
  ),
  AppCategory(
    id: 'groceries',
    name: 'Grocery',
    icon: Icons.local_grocery_store_rounded,
    color: Color(0xFF66BB6A),
  ),
  AppCategory(
    id: 'transport',
    name: 'Transport',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF4ECDC4),
  ),
  AppCategory(
    id: 'fuel',
    name: 'Fuel & Maintenance',
    icon: Icons.local_gas_station_rounded,
    color: Color(0xFFE76F51),
  ),
  AppCategory(
    id: 'travel',
    name: 'Travel',
    icon: Icons.flight_rounded,
    color: Color(0xFF42A5F5),
  ),
  AppCategory(
    id: 'bills',
    name: 'Bills & Utilities',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFFBE0B),
  ),
  AppCategory(
    id: 'mobile',
    name: 'Mobile',
    icon: Icons.phone_android_rounded,
    color: Color(0xFF00BBF9),
  ),
  AppCategory(
    id: 'internet',
    name: 'Internet',
    icon: Icons.wifi_rounded,
    color: Color(0xFF29B6F6),
  ),
  AppCategory(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFF15BB5),
  ),
  AppCategory(
    id: 'clothing',
    name: 'Clothing',
    icon: Icons.checkroom_rounded,
    color: Color(0xFFAB47BC),
  ),
  AppCategory(
    id: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie_rounded,
    color: Color(0xFFEC407A),
  ),
  AppCategory(
    id: 'health',
    name: 'Health',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFEF476F),
  ),
  AppCategory(
    id: 'education',
    name: 'Education',
    icon: Icons.school_rounded,
    color: Color(0xFF26A69A),
  ),
  AppCategory(
    id: 'kids',
    name: 'Kids',
    icon: Icons.child_care_rounded,
    color: Color(0xFFFF8A65),
  ),
  AppCategory(
    id: 'gifts',
    name: 'Gifts',
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFFFFB74D),
  ),
  AppCategory(
    id: 'charity',
    name: 'Charity / Zakat',
    icon: Icons.volunteer_activism_rounded,
    color: Color(0xFF66BB6A),
  ),
  AppCategory(
    id: 'subscriptions',
    name: 'Subscriptions',
    icon: Icons.subscriptions_rounded,
    color: Color(0xFF5C6BC0),
  ),
  AppCategory(
    id: 'atm',
    name: 'ATM / Cash',
    icon: Icons.local_atm_rounded,
    color: Color(0xFF5C6BC0),
  ),
  AppCategory(
    id: 'loan',
    name: 'Loan / Udhaar',
    icon: Icons.handshake_rounded,
    color: Color(0xFFFFAB40),
  ),
  AppCategory(
    id: 'other',
    name: 'Other',
    icon: Icons.more_horiz_rounded,
    color: Color(0xFF8D99AE),
  ),
];

const incomeSources = <AppCategory>[
  AppCategory(
    id: 'salary',
    name: 'Salary',
    icon: Icons.work_rounded,
    color: Color(0xFF06D6A0),
  ),
  AppCategory(
    id: 'freelance',
    name: 'Freelance',
    icon: Icons.laptop_mac_rounded,
    color: Color(0xFF4CC9F0),
  ),
  AppCategory(
    id: 'business',
    name: 'Business',
    icon: Icons.storefront_rounded,
    color: Color(0xFFF72585),
  ),
  AppCategory(
    id: 'family',
    name: 'Family',
    icon: Icons.family_restroom_rounded,
    color: Color(0xFFEC407A),
  ),
  AppCategory(
    id: 'pocket_money',
    name: 'Pocket money',
    icon: Icons.savings_outlined,
    color: Color(0xFFFF8A65),
  ),
  AppCategory(
    id: 'gift',
    name: 'Gift',
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFFFFB74D),
  ),
  AppCategory(
    id: 'bonus',
    name: 'Bonus',
    icon: Icons.celebration_rounded,
    color: Color(0xFFFFD54F),
  ),
  AppCategory(
    id: 'side_hustle',
    name: 'Side hustle',
    icon: Icons.handyman_rounded,
    color: Color(0xFF26A69A),
  ),
  AppCategory(
    id: 'rent_income',
    name: 'Rent income',
    icon: Icons.home_work_rounded,
    color: Color(0xFF5C6BC0),
  ),
  AppCategory(
    id: 'investment_return',
    name: 'Investment',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF7209B7),
  ),
  AppCategory(
    id: 'loan',
    name: 'Loan received',
    icon: Icons.south_west_rounded,
    color: Color(0xFF448AFF),
  ),
  AppCategory(
    id: 'refund',
    name: 'Refund',
    icon: Icons.replay_rounded,
    color: Color(0xFF66BB6A),
  ),
  AppCategory(
    id: 'cashback',
    name: 'Cashback / Rewards',
    icon: Icons.stars_rounded,
    color: Color(0xFFFFA726),
  ),
  AppCategory(
    id: 'pension',
    name: 'Pension',
    icon: Icons.elderly_rounded,
    color: Color(0xFF78909C),
  ),
  AppCategory(
    id: 'scholarship',
    name: 'Scholarship',
    icon: Icons.school_rounded,
    color: Color(0xFF42A5F5),
  ),
  AppCategory(
    id: 'sale',
    name: 'Sale / Sold item',
    icon: Icons.sell_rounded,
    color: Color(0xFFAB47BC),
  ),
  AppCategory(
    id: 'other_income',
    name: 'Other',
    icon: Icons.payments_rounded,
    color: Color(0xFF8D99AE),
  ),
];

const investmentTypes = <AppCategory>[
  AppCategory(
    id: 'stocks',
    name: 'Stocks',
    icon: Icons.show_chart_rounded,
    color: Color(0xFF3A86FF),
  ),
  AppCategory(
    id: 'mutual_funds',
    name: 'Mutual funds',
    icon: Icons.pie_chart_rounded,
    color: Color(0xFF06D6A0),
  ),
  AppCategory(
    id: 'gold',
    name: 'Gold',
    icon: Icons.diamond_rounded,
    color: Color(0xFFFFB703),
  ),
  AppCategory(
    id: 'crypto',
    name: 'Crypto',
    icon: Icons.currency_bitcoin_rounded,
    color: Color(0xFFF72585),
  ),
  AppCategory(
    id: 'savings',
    name: 'Savings',
    icon: Icons.savings_rounded,
    color: Color(0xFF4CC9F0),
  ),
  AppCategory(
    id: 'other_inv',
    name: 'Other',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF8D99AE),
  ),
];

AppCategory expenseCategoryById(String id) {
  return expenseCategories.firstWhere(
    (c) => c.id == id,
    orElse: () => expenseCategories.last,
  );
}

AppCategory incomeSourceById(String id) {
  return incomeSources.firstWhere(
    (c) => c.id == id,
    orElse: () => incomeSources.last,
  );
}

AppCategory investmentTypeById(String id) {
  return investmentTypes.firstWhere(
    (c) => c.id == id,
    orElse: () => investmentTypes.last,
  );
}
