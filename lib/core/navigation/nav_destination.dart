import 'package:flutter/material.dart';

enum NavSection {
  overview,
  operations,
  administration,
  account,
}

class NavDestination {
  final String id;
  final String title;
  final IconData icon;
  final NavSection section;
  final bool adminOnly;
  final int? adminTabIndex;
  final int? managerTabIndex;

  const NavDestination({
    required this.id,
    required this.title,
    required this.icon,
    required this.section,
    this.adminOnly = false,
    this.adminTabIndex,
    this.managerTabIndex,
  });

  // Overview
  static const home = NavDestination(
    id: 'home',
    title: 'Dashboard',
    icon: Icons.dashboard_outlined,
    section: NavSection.overview,
  );

  // Operations
  static const seedPurchase = NavDestination(
    id: 'seed-purchase',
    title: 'Seed Purchase',
    icon: Icons.shopping_cart_outlined,
    section: NavSection.operations,
    adminTabIndex: 0,
    managerTabIndex: 0,
  );

  static const bookingSlot = NavDestination(
    id: 'booking-slot',
    title: 'Booking Slot',
    icon: Icons.calendar_today_outlined,
    section: NavSection.operations,
    adminTabIndex: 1,
    managerTabIndex: 1,
  );

  static const farmVisits = NavDestination(
    id: 'farm-visits',
    title: 'Farm Visits',
    icon: Icons.location_on_outlined,
    section: NavSection.operations,
    adminTabIndex: 2,
    managerTabIndex: 2,
  );

  static const grainSales = NavDestination(
    id: 'grain-sales',
    title: 'Grain Sales',
    icon: Icons.storefront_outlined,
    section: NavSection.operations,
    adminTabIndex: 3,
    managerTabIndex: 3,
  );

  static const seedsInventory = NavDestination(
    id: 'seeds-inventory',
    title: 'Seeds Inventory',
    icon: Icons.inventory_2_outlined,
    section: NavSection.operations,
  );

  static const warehouse = NavDestination(
    id: 'warehouse',
    title: 'Warehouse',
    icon: Icons.warehouse_outlined,
    section: NavSection.operations,
  );

  static const billing = NavDestination(
    id: 'billing',
    title: 'Billing & Invoices',
    icon: Icons.receipt_long_outlined,
    section: NavSection.operations,
  );

  static const marketRates = NavDestination(
    id: 'market-rates',
    title: 'Market Rates',
    icon: Icons.trending_up_rounded,
    section: NavSection.operations,
  );

  static const reports = NavDestination(
    id: 'reports',
    title: 'Reports & Analytics',
    icon: Icons.bar_chart_rounded,
    section: NavSection.operations,
    adminOnly: true,
  );

  static const eventLogs = NavDestination(
    id: 'event-logs',
    title: 'Event Logs',
    icon: Icons.history_rounded,
    section: NavSection.operations,
    adminOnly: true,
  );

  static const allFarmers = NavDestination(
    id: 'all-farmers',
    title: 'Farmers',
    icon: Icons.people_outline_rounded,
    section: NavSection.operations,
  );

  // Administration (Admin Only)
  static const managers = NavDestination(
    id: 'managers',
    title: 'Managers',
    icon: Icons.badge_outlined,
    section: NavSection.administration,
    adminOnly: true,
  );

  static const credits = NavDestination(
    id: 'credits',
    title: 'Credits',
    icon: Icons.credit_card_outlined,
    section: NavSection.administration,
    adminOnly: true,
  );

  static const cacheManagement = NavDestination(
    id: 'cache-management',
    title: 'Cache Management',
    icon: Icons.cached_rounded,
    section: NavSection.administration,
    adminOnly: true,
  );

  // Account
  static const notifications = NavDestination(
    id: 'notifications',
    title: 'Notifications',
    icon: Icons.notifications_none_rounded,
    section: NavSection.account,
  );

  static const account = NavDestination(
    id: 'account',
    title: 'My Account',
    icon: Icons.person_outline_rounded,
    section: NavSection.account,
    managerTabIndex: 4,
  );

  static const settings = NavDestination(
    id: 'settings',
    title: 'Settings',
    icon: Icons.settings_outlined,
    section: NavSection.account,
  );

  static const help = NavDestination(
    id: 'help',
    title: 'Help & Support',
    icon: Icons.help_outline_rounded,
    section: NavSection.account,
  );

  static const List<NavDestination> allDestinations = [
    home,
    seedPurchase,
    seedsInventory,
    warehouse,
    bookingSlot,
    billing,
    farmVisits,
    grainSales,
    marketRates,
    reports,
    eventLogs,
    managers,
    allFarmers,
    credits,
    cacheManagement,
    notifications,
    account,
    settings,
    help,
  ];

  static NavDestination fromId(String id) {
    return allDestinations.firstWhere(
      (d) => d.id == id,
      orElse: () => home,
    );
  }
}
