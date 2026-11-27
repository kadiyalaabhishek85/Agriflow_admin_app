import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/core/navigation/nav_destination.dart';
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/core/widgets/app_scaffold.dart';
import 'package:agriflow_admin/core/widgets/module_placeholder_screen.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/admin/dashboard/data/datasources/admin_dashboard_remote_data_source.dart';
import 'package:agriflow_admin/features/admin/dashboard/data/repositories/admin_dashboard_repository_impl.dart';
import 'package:agriflow_admin/features/admin/dashboard/presentation/controllers/admin_dashboard_controller.dart';
import 'package:agriflow_admin/features/admin/dashboard/presentation/screens/admin_dashboard_view.dart';

import 'package:agriflow_admin/features/seed_purchase/data/datasources/seed_purchase_remote_data_source.dart';
import 'package:agriflow_admin/features/seed_purchase/data/repositories/seed_purchase_repository_impl.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/controllers/seed_purchase_controller.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/screens/seed_purchase_screen.dart';

import 'package:agriflow_admin/features/booking_slot/data/datasources/booking_remote_data_source.dart';
import 'package:agriflow_admin/features/booking_slot/data/repositories/booking_repository_impl.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/controllers/booking_controller.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/screens/booking_slot_screen.dart';

import 'package:agriflow_admin/features/farm_visits/data/datasources/farm_visit_remote_data_source.dart';
import 'package:agriflow_admin/features/farm_visits/data/repositories/farm_visit_repository_impl.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/controllers/farm_visit_controller.dart';
import 'package:agriflow_admin/features/farm_visits/presentation/screens/farm_visit_screen.dart';

import 'package:agriflow_admin/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart';
import 'package:agriflow_admin/features/grain_sales/data/repositories/grain_sale_repository_impl.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/controllers/grain_sale_controller.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/screens/grain_sale_screen.dart';

import 'package:agriflow_admin/features/farmers/data/datasources/farmer_remote_data_source.dart';
import 'package:agriflow_admin/features/farmers/data/repositories/farmer_repository_impl.dart';
import 'package:agriflow_admin/features/farmers/presentation/controllers/farmer_controller.dart';
import 'package:agriflow_admin/features/farmers/presentation/screens/farmer_screen.dart';

import 'package:agriflow_admin/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart';
import 'package:agriflow_admin/features/seeds_inventory/data/repositories/seeds_inventory_repository_impl.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart';

import 'package:agriflow_admin/features/warehouse/data/datasources/fast_api_warehouse_remote_data_source.dart';
import 'package:agriflow_admin/features/warehouse/data/repositories/warehouse_repository_impl.dart';
import 'package:agriflow_admin/features/warehouse/presentation/controllers/warehouse_controller.dart';
import 'package:agriflow_admin/features/warehouse/presentation/screens/warehouse_screen.dart';

import 'package:agriflow_admin/features/billing/data/datasources/fast_api_billing_remote_data_source.dart';
import 'package:agriflow_admin/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:agriflow_admin/features/billing/presentation/controllers/billing_controller.dart';
import 'package:agriflow_admin/features/billing/presentation/screens/billing_screen.dart';

import 'package:agriflow_admin/features/market_rates/data/datasources/fast_api_market_rates_remote_data_source.dart';
import 'package:agriflow_admin/features/market_rates/data/repositories/market_rates_repository_impl.dart';
import 'package:agriflow_admin/features/market_rates/presentation/controllers/market_rates_controller.dart';
import 'package:agriflow_admin/features/market_rates/presentation/screens/market_rates_screen.dart';

import 'package:agriflow_admin/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:agriflow_admin/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:agriflow_admin/features/notifications/domain/entities/notification_item.dart';
import 'package:agriflow_admin/features/notifications/presentation/controllers/notification_controller.dart';
import 'package:agriflow_admin/features/notifications/presentation/screens/notification_screen.dart';
import 'package:agriflow_admin/features/notifications/presentation/services/system_notification_service.dart';

import 'package:agriflow_admin/features/account/presentation/screens/account_screen.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/help/presentation/screens/help_screen.dart';
import 'package:agriflow_admin/features/settings/presentation/screens/settings_screen.dart';

import 'package:agriflow_admin/features/managers/data/datasources/fast_api_manager_remote_data_source.dart';
import 'package:agriflow_admin/features/managers/data/repositories/manager_repository_impl.dart';
import 'package:agriflow_admin/features/managers/presentation/controllers/manager_controller.dart';
import 'package:agriflow_admin/features/managers/presentation/screens/manager_screen.dart';

import 'package:agriflow_admin/features/reports/data/datasources/fast_api_report_remote_data_source.dart';
import 'package:agriflow_admin/features/reports/data/repositories/report_repository_impl.dart';
import 'package:agriflow_admin/features/reports/presentation/controllers/report_controller.dart';
import 'package:agriflow_admin/features/reports/presentation/screens/report_screen.dart';

import 'package:agriflow_admin/features/event_logs/data/datasources/fast_api_event_log_remote_data_source.dart';
import 'package:agriflow_admin/features/event_logs/data/repositories/event_log_repository_impl.dart';
import 'package:agriflow_admin/features/event_logs/presentation/controllers/event_log_controller.dart';
import 'package:agriflow_admin/features/event_logs/presentation/screens/event_log_screen.dart';

/// Production navigation shell for Super Admin and Admin roles.
class AdminShell extends StatefulWidget {
  final AuthSession session;
  final VoidCallback onLogout;
  final AdminDashboardController? dashboardController;
  final SeedPurchaseController? seedPurchaseController;
  final BookingController? bookingController;
  final FarmVisitController? farmVisitsController;
  final GrainSaleController? grainSalesController;
  final FarmerController? farmerController;
  final SeedsInventoryController? seedsInventoryController;
  final WarehouseController? warehouseController;
  final BillingController? billingController;
  final NotificationController? notificationController;
  final MarketRatesController? marketRatesController;
  final ManagerController? managerController;
  final ReportController? reportController;
  final EventLogController? eventLogController;

  /// When provided, notification requests read the access token from secure
  /// storage at request time and refresh it on 401 (backend tokens expire
  /// after 900s — a token captured once at startup stops working in 15 min).
  final ApiClient? apiClient;

  /// System (Android) popup layer; defaults to the real local-notification
  /// service. Tests inject a recording fake.
  final SystemNotificationService? systemNotifications;

  /// Optional — lets the account screen apply profile edits
  /// (PATCH /users/me) to the active session.
  final AuthController? authController;

  const AdminShell({
    super.key,
    required this.session,
    required this.onLogout,
    this.dashboardController,
    this.seedPurchaseController,
    this.bookingController,
    this.farmVisitsController,
    this.grainSalesController,
    this.farmerController,
    this.seedsInventoryController,
    this.warehouseController,
    this.billingController,
    this.notificationController,
    this.marketRatesController,
    this.managerController,
    this.reportController,
    this.eventLogController,
    this.apiClient,
    this.systemNotifications,
    this.authController,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> with WidgetsBindingObserver {
  String _currentRoute = NavDestination.home.id;
  int _selectedTabIndex = -1; // -1 when on non-tab screen (e.g. Dashboard)
  final List<String> _routeHistory = [];
  late final AdminDashboardController _dashboardController;
  late final SeedPurchaseController _seedPurchaseController;
  late final BookingController _bookingController;
  late final FarmVisitController _farmVisitsController;
  late final GrainSaleController _grainSalesController;
  late final FarmerController _farmerController;
  late final SeedsInventoryController _seedsInventoryController;
  late final WarehouseController _warehouseController;
  late final BillingController _billingController;
  late final NotificationController _notificationController;
  late final MarketRatesController _marketRatesController;
  late final ManagerController _managerController;
  late final ReportController _reportController;
  late final EventLogController _eventLogController;
  late final SystemNotificationService _systemNotifications;
  bool _resolvingNotificationTap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _systemNotifications =
        widget.systemNotifications ?? LocalSystemNotificationService();
    _systemNotifications.setTapHandler((id) {
      NotificationTapBridge.pendingNotificationId.value = id;
    });
    NotificationTapBridge.pendingNotificationId
        .addListener(_onPendingNotificationTap);
    _initSystemNotifications();
    _dashboardController = widget.dashboardController ??
        AdminDashboardController(
          repository: AdminDashboardRepositoryImpl(
            remoteDataSource: FastApiAdminDashboardRemoteDataSource(),
          ),
          accessToken: widget.session.accessToken,
        );
    _dashboardController.loadDashboard();

    _seedPurchaseController = widget.seedPurchaseController ??
        SeedPurchaseController(
          repository: SeedPurchaseRepositoryImpl(
            remoteDataSource: SeedPurchaseRemoteDataSourceImpl(),
          ),
          accessToken: widget.session.accessToken,
        );

    _bookingController = widget.bookingController ??
        BookingController(
          repository: BookingRepositoryImpl(
            remoteDataSource: BookingRemoteDataSourceImpl(
              apiClient: widget.apiClient,
            ),
          ),
          accessToken: widget.session.accessToken,
        );

    _farmVisitsController = widget.farmVisitsController ??
        FarmVisitController(
          repository: FarmVisitRepositoryImpl(
            remoteDataSource: FarmVisitRemoteDataSourceImpl(),
          ),
          accessToken: widget.session.accessToken,
        );

    _grainSalesController = widget.grainSalesController ??
        GrainSaleController(
          repository: GrainSaleRepositoryImpl(
            remoteDataSource: GrainSaleRemoteDataSourceImpl(
              apiClient: widget.apiClient,
            ),
            bookingDataSource: BookingRemoteDataSourceImpl(
              apiClient: widget.apiClient,
            ),
          ),
          accessToken: widget.session.accessToken,
        );

    _farmerController = widget.farmerController ??
        FarmerController(
          repository: FarmerRepositoryImpl(
            remoteDataSource: FastApiFarmerRemoteDataSource(),
          ),
          accessToken: widget.session.accessToken,
        );

    _seedsInventoryController = widget.seedsInventoryController ??
        SeedsInventoryController(
          repository: SeedsInventoryRepositoryImpl(
            remoteDataSource: FastApiSeedsInventoryRemoteDataSource(
              apiClient: widget.apiClient,
            ),
          ),
          accessToken: widget.session.accessToken,
        );

    _warehouseController = widget.warehouseController ??
        WarehouseController(
          repository: WarehouseRepositoryImpl(
            remoteDataSource: FastApiWarehouseRemoteDataSource(
              apiClient: widget.apiClient,
            ),
          ),
          accessToken: widget.session.accessToken,
          isAdmin: true,
        );

    _billingController = widget.billingController ??
        BillingController(
          repository: BillingRepositoryImpl(
            remoteDataSource: FastApiBillingRemoteDataSource(
              apiClient: widget.apiClient,
            ),
          ),
          accessToken: widget.session.accessToken,
        );

    _notificationController = widget.notificationController ??
        NotificationController(
          repository: NotificationRepository(
            remoteDataSource: FastApiNotificationRemoteDataSource(
              apiClient: widget.apiClient,
            ),
          ),
          accessToken: widget.session.accessToken,
          systemNotifications: widget.systemNotifications ??
              _systemNotifications,
        );
    _notificationController.startPolling();
    _notificationController.startRealtime();
    _initMarketRates();
    _initManagersReportsEventLogs();

    // A tap that arrived before this shell mounted (cold-start launch
    // details already recorded) resolves now that the list owner exists.
    final pendingAtMount = NotificationTapBridge.pendingNotificationId.value;
    if (pendingAtMount != null) _onPendingNotificationTap();
  }

  Future<void> _initSystemNotifications() async {
    await _systemNotifications.initialize();
    if (!mounted) return;
    // POST_NOTIFICATIONS: asked at most once per install, right after login
    // when realtime starts — never re-prompted; denial keeps the in-app
    // feed fully working.
    await _systemNotifications.ensurePermissionRequested();
    // Terminated-state tap: the plugin reports the launching notification.
    final launchId = await _systemNotifications.pendingLaunchNotificationId();
    if (launchId != null && mounted) {
      NotificationTapBridge.pendingNotificationId.value = launchId;
    }
  }

  void _onPendingNotificationTap() {
    final id = NotificationTapBridge.pendingNotificationId.value;
    if (id == null || _resolvingNotificationTap) return;
    _resolveNotificationTap(id);
  }

  /// Resolves a tapped notification id against the canonical REST list
  /// (which carries `reference_type`/`reference_id`) and navigates to the
  /// referenced module — falling back to the Notifications screen when no
  /// reliable destination exists. Exact-record screens are not pretended:
  /// this app's modules are navigated to at route level.
  Future<void> _resolveNotificationTap(String id) async {
    _resolvingNotificationTap = true;
    try {
      var item = _findNotification(id);
      if (item == null) {
        await _notificationController.refresh();
        item = _findNotification(id);
      }
      final route = item == null
          ? NavDestination.notifications.id
          : NotificationDestinationResolver.resolveRoute(
              item,
              isAdmin: widget.session.role.isAdmin,
            );
      if (mounted) _onNavigate(route);
      NotificationTapBridge.pendingNotificationId.value = null;
    } finally {
      _resolvingNotificationTap = false;
    }
  }

  NotificationItem? _findNotification(String id) {
    try {
      return _notificationController.notifications
          .firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Timers are throttled while backgrounded — refresh immediately and
      // revive the SSE connection so the badge catches up at once.
      _notificationController.handleAppResumed();
    }
  }

  void _initMarketRates() {
    _marketRatesController = widget.marketRatesController ??
        MarketRatesController(
          repository: MarketRatesRepositoryImpl(
            remoteDataSource: FastApiMarketRatesRemoteDataSource(),
          ),
          accessToken: widget.session.accessToken,
          role: widget.session.role,
        );
  }

  void _initManagersReportsEventLogs() {
    _managerController = widget.managerController ??
        ManagerController(
          repository: ManagerRepositoryImpl(
            remoteDataSource: FastApiManagerRemoteDataSource(),
          ),
          accessToken: widget.session.accessToken,
        );

    _reportController = widget.reportController ??
        ReportController(
          repository: ReportRepositoryImpl(
            remoteDataSource: FastApiReportRemoteDataSource(),
          ),
          accessToken: widget.session.accessToken,
        );

    _eventLogController = widget.eventLogController ??
        EventLogController(
          repository: EventLogRepositoryImpl(
            remoteDataSource: FastApiEventLogRemoteDataSource(),
          ),
          accessToken: widget.session.accessToken,
        );
  }

  void _pushHistory(String fromRoute) {
    if (_routeHistory.isEmpty || _routeHistory.last != fromRoute) {
      _routeHistory.add(fromRoute);
      if (_routeHistory.length > 30) {
        _routeHistory.removeAt(0);
      }
    }
  }

  void _onTabSelected(int index) {
    String nextRoute = _currentRoute;
    switch (index) {
      case 0:
        nextRoute = NavDestination.seedPurchase.id;
        break;
      case 1:
        nextRoute = NavDestination.bookingSlot.id;
        break;
      case 2:
        nextRoute = NavDestination.farmVisits.id;
        break;
      case 3:
        nextRoute = NavDestination.grainSales.id;
        break;
    }
    if (nextRoute == _currentRoute) return;
    setState(() {
      _pushHistory(_currentRoute);
      _selectedTabIndex = index;
      _currentRoute = nextRoute;
    });
  }

  void _onNavigate(String route) {
    if (route == _currentRoute) return;
    setState(() {
      _pushHistory(_currentRoute);
      _currentRoute = route;
      final destination = NavDestination.fromId(route);
      _selectedTabIndex = destination.adminTabIndex ?? -1;
    });
  }

  void _goBack() {
    setState(() {
      final previous = _routeHistory.isNotEmpty
          ? _routeHistory.removeLast()
          : NavDestination.home.id;
      _currentRoute = previous;
      final destination = NavDestination.fromId(previous);
      _selectedTabIndex = destination.adminTabIndex ?? -1;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationTapBridge.pendingNotificationId
        .removeListener(_onPendingNotificationTap);
    if (widget.dashboardController == null) {
      _dashboardController.dispose();
    }
    if (widget.seedPurchaseController == null) {
      _seedPurchaseController.dispose();
    }
    if (widget.bookingController == null) {
      _bookingController.dispose();
    }
    if (widget.farmVisitsController == null) {
      _farmVisitsController.dispose();
    }
    if (widget.grainSalesController == null) {
      _grainSalesController.dispose();
    }
    if (widget.farmerController == null) {
      _farmerController.dispose();
    }
    if (widget.seedsInventoryController == null) {
      _seedsInventoryController.dispose();
    }
    if (widget.warehouseController == null) {
      _warehouseController.dispose();
    }
    if (widget.billingController == null) {
      _billingController.dispose();
    }
    if (widget.notificationController == null) {
      _notificationController.dispose();
    }
    if (widget.marketRatesController == null) {
      _marketRatesController.dispose();
    }
    if (widget.managerController == null) {
      _managerController.dispose();
    }
    if (widget.reportController == null) {
      _reportController.dispose();
    }
    if (widget.eventLogController == null) {
      _eventLogController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user;
    final role = widget.session.role;

    return ListenableBuilder(
      listenable: _notificationController,
      builder: (context, _) {
        return PopScope(
          canPop: _currentRoute == NavDestination.home.id && _routeHistory.isEmpty,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _goBack();
            }
          },
          child: AppScaffold(
            role: role,
            currentRoute: _currentRoute,
            selectedTabIndex: _selectedTabIndex,
            onTabSelected: _onTabSelected,
            onNavigate: _onNavigate,
            onLogout: widget.onLogout,
            userName: user.name.isNotEmpty ? user.name : 'Super Admin',
            userEmail: user.phone.isNotEmpty ? user.phone : (user.email ?? ''),
            unreadNotifications: _notificationController.unreadCount,
            pendingOrders: 0,
            body: _buildCurrentScreen(role),
          ),
        );
      },
    );
  }

  Widget _buildCurrentScreen(UserRole role) {
    if (_currentRoute == NavDestination.home.id) {
      return AdminDashboardView(
        session: widget.session,
        controller: _dashboardController,
        onTabSelected: _onTabSelected,
        onNavigate: _onNavigate,
      );
    }

    if (_currentRoute == NavDestination.seedPurchase.id) {
      return SeedPurchaseScreen(
        controller: _seedPurchaseController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.seedsInventory.id) {
      return SeedsInventoryScreen(
        controller: _seedsInventoryController,
        isAdmin: true,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.bookingSlot.id) {
      return BookingSlotScreen(
        controller: _bookingController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.farmVisits.id) {
      return FarmVisitScreen(
        controller: _farmVisitsController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.grainSales.id) {
      return GrainSaleScreen(
        controller: _grainSalesController,
        onBack: _goBack,
        isManagerRole: false,
      );
    }

    if (_currentRoute == NavDestination.allFarmers.id) {
      return FarmerScreen(
        controller: _farmerController,
        onBack: _goBack,
        isManagerRole: false,
      );
    }

    if (_currentRoute == NavDestination.warehouse.id) {
      return WarehouseScreen(
        controller: _warehouseController,
        isAdmin: true,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.billing.id) {
      return BillingScreen(
        controller: _billingController,
        onBack: _goBack,
        isManagerRole: false,
      );
    }

    if (_currentRoute == NavDestination.marketRates.id) {
      return MarketRatesScreen(
        controller: _marketRatesController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.notifications.id) {
      return NotificationScreen(
        controller: _notificationController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.managers.id) {
      return ManagerScreen(
        controller: _managerController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.reports.id) {
      return ReportScreen(
        controller: _reportController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.eventLogs.id) {
      return EventLogScreen(
        controller: _eventLogController,
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.account.id) {
      return AccountScreen(
        session: widget.session,
        onLogout: widget.onLogout,
        onBack: _goBack,
        authController: widget.authController,
      );
    }

    if (_currentRoute == NavDestination.settings.id) {
      return SettingsScreen(
        onBack: _goBack,
      );
    }

    if (_currentRoute == NavDestination.help.id) {
      return HelpScreen(
        onBack: _goBack,
      );
    }

    final destination = NavDestination.fromId(_currentRoute);
    return ModulePlaceholderScreen(
      title: destination.title,
      destinationId: destination.id,
      icon: destination.icon,
      role: role,
      onBackToDashboard: _goBack,
    );
  }
}
