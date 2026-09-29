# APP_INVENTORY.md — agriflow_admin Flutter application

Generated from source on 2026-09-27: every `.dart` file under `lib/` and `test/` is listed with its layer role and the public types actually declared in it. Descriptions marked by hand in the architecture section were written from files read in full.

## Files

### app root

- `lib/app.dart`: app root, routing and auth gate — public types: AgriFlowApp, AuthRouter, AuthenticatedAppShell, FoundationShowcaseScreen
- `lib/main.dart`: app entrypoint — top-level helpers: main

### core + app root

- `lib/core/constants/app_colors.dart`: design constants — public types: AppColors
- `lib/core/constants/app_typography.dart`: design constants — public types: AppTypography
- `lib/core/models/user_role.dart`: core model / enum — public types: UserRole
- `lib/core/navigation/nav_destination.dart`: navigation model — public types: NavSection, NavDestination
- `lib/core/network/api_contracts.dart`: cross-feature repository contracts — public types: IAuthRepository, IDashboardRepository, ISeedPurchaseRepository, IBookingSlotsRepository, IFarmVisitsRepository, IGrainSalesRepository, ISeedsInventoryRepository, IWarehouseRepository, IBillingRepository, IMarketRatesRepository, IFarmersRepository, IManagersRepository, IReportsRepository, IEventLogsRepository, ICreditsRepository, ICacheRepository
- `lib/core/theme/app_theme.dart`: theme definitions — public types: AppTheme
- `lib/core/widgets/app_card.dart`: shared design-system widget — public types: AppCard, StatCard
- `lib/core/widgets/app_navbar.dart`: shared design-system widget — public types: AppNavbar
- `lib/core/widgets/app_scaffold.dart`: shared design-system widget — public types: AppScaffold
- `lib/core/widgets/app_text_field.dart`: shared design-system widget — public types: AppTextField
- `lib/core/widgets/app_toast.dart`: shared design-system widget — public types: AppToast
- `lib/core/widgets/custom_drawer.dart`: shared design-system widget — public types: CustomDrawer
- `lib/core/widgets/custom_tabbar.dart`: shared design-system widget — public types: TabItemData, CustomTabbar
- `lib/core/widgets/module_placeholder_screen.dart`: shared design-system widget — public types: ModulePlaceholderScreen
- `lib/core/widgets/squircle_icon_button.dart`: shared design-system widget — public types: SquircleIconButton
- `lib/core/widgets/state_views.dart`: shared design-system widget — public types: EmptyStateView, AppSkeleton, AppLoadingView, AppErrorView
- `lib/core/widgets/status_pill.dart`: shared design-system widget — public types: PillType, StatusPill

### feature: admin

- `lib/features/admin/dashboard/data/datasources/admin_dashboard_remote_data_source.dart`: remote/local data source — public types: AdminDashboardRemoteDataSource, FastApiAdminDashboardRemoteDataSource
- `lib/features/admin/dashboard/data/repositories/admin_dashboard_repository_impl.dart`: repository implementation — public types: AdminDashboardRepositoryImpl
- `lib/features/admin/dashboard/domain/entities/admin_dashboard_data.dart`: domain entity / data model — public types: AdminAuditItem, AdminDashboardData
- `lib/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart`: repository contract — public types: AdminDashboardRepository
- `lib/features/admin/dashboard/presentation/controllers/admin_dashboard_controller.dart`: view controller (ChangeNotifier) — public types: AdminDashboardController
- `lib/features/admin/dashboard/presentation/screens/admin_dashboard_view.dart`: screen — public types: AdminDashboardView
- `lib/features/admin/presentation/admin_shell.dart`: role-based authenticated app shell — public types: AdminShell

### feature: auth

- `lib/features/auth/data/datasources/auth_local_data_source.dart`: remote/local data source — public types: AuthLocalDataSource, SharedPreferencesAuthLocalDataSource
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`: remote/local data source — public types: AuthRemoteDataSource, FastApiAuthRemoteDataSource
- `lib/features/auth/data/repositories/auth_repository_impl.dart`: repository implementation — public types: AuthRepositoryImpl
- `lib/features/auth/domain/entities/auth_exception.dart`: domain entity / data model — public types: AuthException
- `lib/features/auth/domain/entities/auth_session.dart`: domain entity / data model — public types: AuthSession
- `lib/features/auth/domain/entities/auth_user.dart`: domain entity / data model — public types: AuthUser
- `lib/features/auth/domain/repositories/auth_repository.dart`: repository contract — public types: AuthRepository
- `lib/features/auth/presentation/controllers/auth_controller.dart`: view controller (ChangeNotifier) — public types: AuthController
- `lib/features/auth/presentation/controllers/auth_state.dart`: auth state machine model — public types: AuthStatus, AuthState
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`: screen — public types: ForgotPasswordScreen
- `lib/features/auth/presentation/screens/login_screen.dart`: screen — public types: LoginScreen
- `lib/features/auth/presentation/screens/splash_screen.dart`: screen — public types: SplashScreen
- `lib/features/auth/presentation/screens/unsupported_role_screen.dart`: screen — public types: UnsupportedRoleScreen

### feature: booking_slot

- `lib/features/booking_slot/data/datasources/booking_remote_data_source.dart`: remote/local data source — public types: BookingRemoteDataSource, BookingRemoteDataSourceImpl
- `lib/features/booking_slot/data/repositories/booking_repository_impl.dart`: repository implementation — public types: BookingRepositoryImpl
- `lib/features/booking_slot/domain/entities/booking_exception.dart`: domain entity / data model — public types: BookingException
- `lib/features/booking_slot/domain/entities/booking_item.dart`: domain entity / data model — public types: BookingItem
- `lib/features/booking_slot/domain/entities/booking_pagination.dart`: domain entity / data model — public types: BookingPagination
- `lib/features/booking_slot/domain/entities/warehouse_item.dart`: domain entity / data model — public types: WarehouseItem
- `lib/features/booking_slot/domain/repositories/booking_repository.dart`: repository contract — public types: BookingRepository
- `lib/features/booking_slot/presentation/controllers/booking_controller.dart`: view controller (ChangeNotifier) — public types: BookingViewStatus, BookingController
- `lib/features/booking_slot/presentation/screens/booking_slot_screen.dart`: screen — public types: BookingSlotScreen
- `lib/features/booking_slot/presentation/widgets/booking_card.dart`: presentation widget — public types: BookingCard
- `lib/features/booking_slot/presentation/widgets/booking_detail_sheet.dart`: presentation widget — public types: BookingDetailSheet
- `lib/features/booking_slot/presentation/widgets/date_selector_strip.dart`: presentation widget — public types: DateSelectorStrip

### feature: dashboard

- `lib/features/dashboard/shared/presentation/dashboard_state.dart`: cross-role shared feature module — public types: DashboardStatus, DashboardState
- `lib/features/dashboard/shared/presentation/widgets/dashboard_chart_card.dart`: cross-role shared feature module — public types: MonthlyChartPoint, DashboardChartCard
- `lib/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart`: cross-role shared feature module — public types: MandiRateItem, DashboardMandiStrip
- `lib/features/dashboard/shared/presentation/widgets/dashboard_metric_card.dart`: cross-role shared feature module — public types: DashboardMetricCard
- `lib/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart`: cross-role shared feature module — public types: DashboardLoadingView, DashboardErrorView, DashboardEmptyView
- `lib/features/dashboard/shared/presentation/widgets/dashboard_summary_strip.dart`: cross-role shared feature module — public types: DashboardSummaryStrip

### feature: farm_visits

- `lib/features/farm_visits/data/datasources/farm_visit_remote_data_source.dart`: remote/local data source — public types: FarmVisitRemoteDataSource, FarmVisitRemoteDataSourceImpl
- `lib/features/farm_visits/data/repositories/farm_visit_repository_impl.dart`: repository implementation — public types: FarmVisitRepositoryImpl
- `lib/features/farm_visits/domain/entities/farm_visit_exception.dart`: domain entity / data model — public types: FarmVisitException, FarmVisitNetworkException, FarmVisitAuthException, FarmVisitPermissionException, FarmVisitNotFoundException, FarmVisitValidationException, FarmVisitServerException
- `lib/features/farm_visits/domain/entities/farm_visit_item.dart`: domain entity / data model — public types: FarmVisitItem
- `lib/features/farm_visits/domain/entities/farm_visit_pagination.dart`: domain entity / data model — public types: FarmVisitPagination
- `lib/features/farm_visits/domain/repositories/farm_visit_repository.dart`: repository contract — public types: FarmVisitRepository
- `lib/features/farm_visits/presentation/controllers/farm_visit_controller.dart`: view controller (ChangeNotifier) — public types: FarmVisitViewStatus, FarmVisitController
- `lib/features/farm_visits/presentation/screens/farm_visit_screen.dart`: screen — public types: FarmVisitScreen
- `lib/features/farm_visits/presentation/widgets/complete_visit_dialog.dart`: presentation widget — public types: CompleteVisitDialog
- `lib/features/farm_visits/presentation/widgets/farm_visit_card.dart`: presentation widget — public types: FarmVisitCard
- `lib/features/farm_visits/presentation/widgets/farm_visit_detail_sheet.dart`: presentation widget — public types: FarmVisitDetailSheet
- `lib/features/farm_visits/presentation/widgets/reschedule_visit_dialog.dart`: presentation widget — public types: RescheduleVisitDialog

### feature: farmers

- `lib/features/farmers/data/datasources/farmer_remote_data_source.dart`: remote/local data source — public types: FarmerRemoteDataSource, FastApiFarmerRemoteDataSource
- `lib/features/farmers/data/repositories/farmer_repository_impl.dart`: repository implementation — public types: FarmerRepositoryImpl
- `lib/features/farmers/domain/entities/bank_change_request_item.dart`: domain entity / data model — public types: BankChangeRequestItem
- `lib/features/farmers/domain/entities/farmer_exception.dart`: domain entity / data model — public types: FarmerException, FarmerUnauthorizedException, FarmerForbiddenException, FarmerNotFoundException, FarmerValidationException, FarmerConflictException, FarmerServerException
- `lib/features/farmers/domain/entities/farmer_item.dart`: domain entity / data model — public types: FarmerItem
- `lib/features/farmers/domain/entities/farmer_pagination.dart`: domain entity / data model — public types: FarmerPagination
- `lib/features/farmers/domain/entities/farmer_profile_item.dart`: domain entity / data model — public types: FarmerProfileItem
- `lib/features/farmers/domain/repositories/farmer_repository.dart`: repository contract — public types: FarmerRepository
- `lib/features/farmers/presentation/controllers/farmer_controller.dart`: view controller (ChangeNotifier) — public types: FarmerController
- `lib/features/farmers/presentation/screens/farmer_screen.dart`: screen — public types: FarmerScreen
- `lib/features/farmers/presentation/widgets/add_farmer_sheet.dart`: presentation widget — public types: AddFarmerSheet
- `lib/features/farmers/presentation/widgets/bank_change_requests_sheet.dart`: presentation widget — public types: BankChangeRequestsSheet
- `lib/features/farmers/presentation/widgets/farmer_card.dart`: presentation widget — public types: FarmerCard
- `lib/features/farmers/presentation/widgets/farmer_detail_sheet.dart`: presentation widget — public types: FarmerDetailSheet

### feature: grain_sales

- `lib/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart`: remote/local data source — public types: GrainSaleRemoteDataSource, FastApiGrainSaleRemoteDataSource
- `lib/features/grain_sales/data/repositories/grain_sale_repository_impl.dart`: repository implementation — public types: GrainSaleRepositoryImpl
- `lib/features/grain_sales/domain/entities/grain_sale_exception.dart`: domain entity / data model — public types: GrainSaleException, GrainSaleUnauthorizedException, GrainSaleForbiddenException, GrainSaleNotFoundException, GrainSaleValidationException, GrainSaleConflictException, GrainSaleServerException
- `lib/features/grain_sales/domain/entities/grain_sale_item.dart`: domain entity / data model — public types: GrainSaleItem
- `lib/features/grain_sales/domain/entities/grain_sale_pagination.dart`: domain entity / data model — public types: GrainSalePagination
- `lib/features/grain_sales/domain/repositories/grain_sale_repository.dart`: repository contract — public types: GrainSaleRepository
- `lib/features/grain_sales/presentation/controllers/grain_sale_controller.dart`: view controller (ChangeNotifier) — public types: GrainSaleController
- `lib/features/grain_sales/presentation/screens/grain_sale_screen.dart`: screen — public types: GrainSaleScreen
- `lib/features/grain_sales/presentation/widgets/grain_sale_card.dart`: presentation widget — public types: GrainSaleCard
- `lib/features/grain_sales/presentation/widgets/grain_sale_detail_sheet.dart`: presentation widget — public types: GrainSaleDetailSheet
- `lib/features/grain_sales/presentation/widgets/log_received_crop_sheet.dart`: presentation widget — public types: LogReceivedCropSheet

### feature: manager

- `lib/features/manager/dashboard/data/datasources/manager_dashboard_remote_data_source.dart`: remote/local data source — public types: ManagerDashboardRemoteDataSource, FastApiManagerDashboardRemoteDataSource
- `lib/features/manager/dashboard/data/repositories/manager_dashboard_repository_impl.dart`: repository implementation — public types: ManagerDashboardRepositoryImpl
- `lib/features/manager/dashboard/domain/entities/manager_dashboard_data.dart`: domain entity / data model — public types: ManagerNotificationItem, ManagerDashboardData
- `lib/features/manager/dashboard/domain/repositories/manager_dashboard_repository.dart`: repository contract — public types: ManagerDashboardRepository
- `lib/features/manager/dashboard/presentation/controllers/manager_dashboard_controller.dart`: view controller (ChangeNotifier) — public types: ManagerDashboardController
- `lib/features/manager/dashboard/presentation/screens/manager_dashboard_view.dart`: screen — public types: ManagerDashboardView
- `lib/features/manager/presentation/manager_shell.dart`: role-based authenticated app shell — public types: ManagerShell

### feature: seed_purchase

- `lib/features/seed_purchase/data/datasources/seed_purchase_remote_data_source.dart`: remote/local data source — public types: SeedPurchaseRemoteDataSource, SeedPurchaseRemoteDataSourceImpl
- `lib/features/seed_purchase/data/repositories/seed_purchase_repository_impl.dart`: repository implementation — public types: SeedPurchaseRepositoryImpl
- `lib/features/seed_purchase/domain/entities/seed_catalog_item.dart`: domain entity / data model — public types: SeedCatalogItem
- `lib/features/seed_purchase/domain/entities/seed_purchase_exception.dart`: domain entity / data model — public types: SeedPurchaseException
- `lib/features/seed_purchase/domain/entities/seed_purchase_item.dart`: domain entity / data model — public types: SeedPurchaseItem
- `lib/features/seed_purchase/domain/entities/seed_purchase_pagination.dart`: domain entity / data model — public types: SeedPurchasePagination
- `lib/features/seed_purchase/domain/repositories/seed_purchase_repository.dart`: repository contract — public types: SeedPurchaseRepository
- `lib/features/seed_purchase/presentation/controllers/seed_purchase_controller.dart`: view controller (ChangeNotifier) — public types: SeedPurchaseViewStatus, SeedPurchaseController
- `lib/features/seed_purchase/presentation/screens/seed_purchase_screen.dart`: screen — public types: SeedPurchaseScreen
- `lib/features/seed_purchase/presentation/widgets/seed_purchase_card.dart`: presentation widget — public types: SeedPurchaseCard
- `lib/features/seed_purchase/presentation/widgets/seed_purchase_detail_sheet.dart`: presentation widget — public types: SeedPurchaseDetailSheet

### feature: seeds_inventory

- `lib/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart`: remote/local data source — public types: SeedsInventoryRemoteDataSource, FastApiSeedsInventoryRemoteDataSource
- `lib/features/seeds_inventory/data/repositories/seeds_inventory_repository_impl.dart`: repository implementation — public types: SeedsInventoryRepositoryImpl
- `lib/features/seeds_inventory/domain/entities/seed_inventory_item.dart`: domain entity / data model — public types: SeedInventoryItem
- `lib/features/seeds_inventory/domain/entities/seed_warehouse_brief.dart`: domain entity / data model — public types: SeedWarehouseBrief
- `lib/features/seeds_inventory/domain/exceptions/seeds_inventory_exception.dart`: domain exception type — public types: SeedsInventoryException, SeedsInventoryUnauthorizedException, SeedsInventoryForbiddenException, SeedsInventoryNotFoundException, SeedsInventoryValidationException, SeedsInventoryServerException, SeedsInventoryNetworkException
- `lib/features/seeds_inventory/domain/repositories/seeds_inventory_repository.dart`: repository contract — public types: SeedsInventoryRepository
- `lib/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart`: view controller (ChangeNotifier) — public types: SeedsInventoryController
- `lib/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart`: screen — public types: SeedsInventoryScreen
- `lib/features/seeds_inventory/presentation/widgets/add_edit_seed_sheet.dart`: presentation widget — public types: AddEditSeedSheet
- `lib/features/seeds_inventory/presentation/widgets/seed_inventory_card.dart`: presentation widget — public types: SeedInventoryCard

### feature: warehouse

- `lib/features/warehouse/data/datasources/fast_api_warehouse_remote_data_source.dart`: remote/local data source — public types: WarehouseRemoteDataSource, FastApiWarehouseRemoteDataSource
- `lib/features/warehouse/data/repositories/warehouse_repository_impl.dart`: repository implementation — public types: WarehouseRepositoryImpl
- `lib/features/warehouse/domain/entities/warehouse_inventory_item.dart`: domain entity / data model — public types: WarehouseInventoryItem
- `lib/features/warehouse/domain/entities/warehouse_item.dart`: domain entity / data model — public types: WarehouseItem
- `lib/features/warehouse/domain/entities/warehouse_slot_item.dart`: domain entity / data model — public types: WarehouseSlotItem
- `lib/features/warehouse/domain/exceptions/warehouse_exception.dart`: domain exception type — public types: WarehouseException, WarehouseUnauthorizedException, WarehouseForbiddenException, WarehouseNotFoundException, WarehouseConflictException, WarehouseValidationException, WarehouseServerException, WarehouseNetworkException
- `lib/features/warehouse/domain/repositories/warehouse_repository.dart`: repository contract — public types: WarehouseRepository
- `lib/features/warehouse/presentation/controllers/warehouse_controller.dart`: view controller (ChangeNotifier) — public types: WarehouseController
- `lib/features/warehouse/presentation/screens/warehouse_screen.dart`: screen — public types: WarehouseScreen
- `lib/features/warehouse/presentation/widgets/add_edit_warehouse_sheet.dart`: presentation widget — public types: AddEditWarehouseSheet
- `lib/features/warehouse/presentation/widgets/add_inventory_sheet.dart`: presentation widget — public types: AddInventorySheet
- `lib/features/warehouse/presentation/widgets/create_slot_sheet.dart`: presentation widget — public types: CreateSlotSheet
- `lib/features/warehouse/presentation/widgets/warehouse_card.dart`: presentation widget — public types: WarehouseCard
- `lib/features/warehouse/presentation/widgets/warehouse_detail_sheet.dart`: presentation widget — public types: WarehouseDetailSheet

### test

- `test/features/admin/admin_dashboard_test.dart`: test suite — top-level helpers: main
- `test/features/auth/auth_controller_test.dart`: test suite — public types: MockAuthRepository
- `test/features/auth/auth_local_data_source_test.dart`: test suite — top-level helpers: main
- `test/features/auth/login_screen_test.dart`: test suite — public types: TestAuthRepository
- `test/features/auth/responsive_test.dart`: test suite — public types: MockAuthRepo
- `test/features/auth/role_mapping_test.dart`: test suite — top-level helpers: main
- `test/features/auth/splash_screen_test.dart`: test suite — public types: SplashTestAuthRepository
- `test/features/booking_slot/booking_slot_test.dart`: test suite — top-level helpers: main
- `test/features/farm_visits/farm_visit_test.dart`: test suite — top-level helpers: main
- `test/features/farmers/farmer_test.dart`: test suite — top-level helpers: main
- `test/features/grain_sales/grain_sale_test.dart`: test suite — top-level helpers: main
- `test/features/manager/manager_dashboard_test.dart`: test suite — top-level helpers: main
- `test/features/navigation/navigation_shell_test.dart`: test suite — top-level helpers: main
- `test/features/seed_purchase/seed_purchase_test.dart`: test suite — top-level helpers: main
- `test/features/seeds_inventory/seeds_inventory_test.dart`: test suite — public types: MockSeedsInventoryRepository
- `test/features/warehouse/warehouse_test.dart`: test suite — public types: MockWarehouseRepository
- `test/widget_test.dart`: test suite — top-level helpers: main

## Architecture (written from files read in full)

**Stack.** Dart SDK `^3.12.2` Flutter app (`pubspec.yaml`): Material, google_fonts, intl, shared_preferences, http. No third-party state-management, routing, or DI package — state and navigation are hand-rolled ChangeNotifiers and an id-switch shell.

**Entry and wiring.** `lib/main.dart` (21 lines) builds SharedPreferences → SharedPreferencesAuthLocalDataSource → FastApiAuthRemoteDataSource → AuthRepositoryImpl → AuthController and injects it into AgriFlowApp.

**Auth-driven routing.** `lib/app.dart` (650 lines): MaterialApp home is AuthRouter, a ListenableBuilder over AuthController that switches on AuthState — session restoring goes to SplashScreen, unsupported role to UnsupportedRoleScreen, authenticated admin to AdminShell, manager to ManagerShell, otherwise LoginScreen. An injected-null path falls back to _UnconfiguredAuthRepository which throws `UnimplementedError('Backend API required — to be supplied by Syed.')`; `showcaseMode` renders FoundationShowcaseScreen, a full design-system gallery.

**Role shells and navigation.** AdminShell (`lib/features/admin/presentation/admin_shell.dart`, 324 lines) and ManagerShell construct every feature controller in initState from repository impl + remote data source + the session accessToken (constructor params allow test injection) and dispose only what they created. Screens are swapped by NavDestination id — there is no per-feature Navigator route. Admin has 4 bottom tabs (seed-purchase, booking-slot, farm-visits, grain-sales); Manager has 5 (adds account). NavDestination declares 19 destinations with section grouping, adminOnly flags, and per-role tab indexes; any destination without a built-in screen renders ModulePlaceholderScreen — Billing, Market Rates, Reports, Event Logs, Managers, Credits, Cache, Notifications, Settings, and Help are placeholders today.

**Auth state machine.** AuthController (ChangeNotifier) drives an immutable AuthState with nine AuthStatus values (initial, sessionRestoring, unauthenticated, authenticating, authenticated, authenticationFailure, sessionExpired, loggingOut, unsupportedRole). Role resolves strictly from the session; unknown roles never silently default to Manager (`auth_controller.dart:18`).

**Data-layer pattern.** Every feature repeats the same three layers: domain (entities, repository contract, typed exception hierarchy) → data (remote data source over package:http, thin repository impl forwarding with accessToken) → presentation (ChangeNotifier controller, screen, widgets). Sampled in full: WarehouseRepositoryImpl (184 lines) is a pure pass-through to FastApiWarehouseRemoteDataSource; FastApiAuthRemoteDataSource (249 lines) calls `https://agriflow-backend-t8o4.onrender.com/api/v1`, Bearer token headers, 12–15 s timeouts, unwraps a `{data: …}` envelope, and maps SocketException/TimeoutException to typed AuthExceptions.

**Cross-feature contracts.** `lib/core/network/api_contracts.dart` declares I*Repository interfaces for 16 domains (auth, dashboard, seed purchase, booking, farm visits, grain sales, seeds inventory, warehouse, billing, market rates, farmers, managers, reports, event logs, credits, cache) — the latter group is backend-pending per AGENTS.md.

**RBAC.** `core/models/user_role.dart` UserRole enum feeds role-driven shells, tab sets, drawer filtering, and `isAdmin` flags passed into Warehouse, Seeds Inventory, Farmers, and Grain Sale screens (`admin_shell.dart:156`, `admin_shell.dart:272`, `admin_shell.dart:295`).

**Design system.** AppColors, AppTypography, AppTheme plus 12 core widgets (scaffold, navbar, drawer, tabbar, card/StatCard, text field, toast, status pill, skeleton/empty/loading/error views, squircle button, module placeholder), demonstrated by FoundationShowcaseScreen (Milestone 1).

**Tests.** 17 files / 8,669 lines covering auth (controller, local data source, login, splash, role mapping, responsive layout), the navigation shell, both dashboards, and every major feature, using hand-written mocks rather than mockito.

## Coverage and caveats (honest scope of this view)

Read end-to-end in this session: `lib/main.dart`, `lib/app.dart`, `lib/features/admin/presentation/admin_shell.dart`, `lib/features/auth/presentation/controllers/auth_controller.dart`, `lib/features/auth/presentation/controllers/auth_state.dart`, `lib/core/navigation/nav_destination.dart`, plus the first 90 lines of `lib/features/auth/data/datasources/auth_remote_data_source.dart`, the first 70 lines of `lib/features/warehouse/data/repositories/warehouse_repository_impl.dart`, and `pubspec.yaml`.

Surveyed at declaration level for all 153 Dart files: every public type was extracted from the actual source text, not inferred from file names.

Not read line-by-line: method bodies of the remaining ~129 lib files (screens, sheets, controller logic, entity JSON mappers, per-endpoint data-source tables) and the 17 test bodies. Claims about those files rest on their extracted declarations and directory roles, not a full audit.

Outside the Dart inventory and not audited: `docs/` (backend requirements, bugs, deep-review, milestones), platform folders (android/ios/web/linux/macos/windows), the HTML design prototypes, and the OpenAPI dumps at the repository root.

