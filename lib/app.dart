import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_typography.dart';
import 'core/models/user_role.dart';
import 'core/theme/app_theme.dart';

import 'core/widgets/app_card.dart';
import 'core/widgets/app_scaffold.dart';
import 'core/widgets/app_text_field.dart';
import 'core/widgets/app_toast.dart';
import 'core/widgets/squircle_icon_button.dart';
import 'core/widgets/state_views.dart';
import 'core/widgets/status_pill.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/domain/entities/auth_session.dart';
import 'features/auth/domain/entities/auth_user.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/unsupported_role_screen.dart';
import 'features/admin/presentation/admin_shell.dart';
import 'features/manager/presentation/manager_shell.dart';

class AgriFlowApp extends StatelessWidget {
  final AuthController? authController;
  final bool showcaseMode;

  /// Token storage used to build the authenticated `ApiClient` so
  /// notification requests always use a fresh, refreshable access token.
  final AuthLocalDataSource? localDataSource;

  const AgriFlowApp({
    super.key,
    this.authController,
    this.showcaseMode = false,
    this.localDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sri Siva Sai Seeds — Admin & Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showcaseMode
          ? const FoundationShowcaseScreen()
          : AuthRouter(
              authController: authController,
              localDataSource: localDataSource,
            ),
    );
  }
}

class AuthRouter extends StatefulWidget {
  final AuthController? authController;
  final AuthLocalDataSource? localDataSource;

  const AuthRouter({
    super.key,
    this.authController,
    this.localDataSource,
  });

  @override
  State<AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<AuthRouter> {
  late final AuthController _controller;
  ApiClient? _apiClient;

  @override
  void initState() {
    super.initState();
    _controller = widget.authController ??
        AuthController(
          repository: _UnconfiguredAuthRepository(),
        );
    if (widget.localDataSource != null) {
      _apiClient = ApiClient(
        localDataSource: widget.localDataSource!,
        onSessionExpired: () => _controller.handleSessionExpired(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        if (state.isInitializing || state.isSessionRestoring) {
          return SplashScreen(authController: _controller);
        }

        if (state.isUnsupportedRole) {
          return UnsupportedRoleScreen(
            authController: _controller,
            roleName: state.unsupportedRoleName ?? 'Unauthorized',
          );
        }

        if (state.isAuthenticated && _controller.currentRole != null) {
          final role = _controller.currentRole!;
          if (role.isAdmin) {
            return AdminShell(
              session: state.session!,
              onLogout: () => _controller.logout(),
              apiClient: _apiClient,
              authController: _controller,
            );
          } else if (role == UserRole.manager) {
            return ManagerShell(
              session: state.session!,
              onLogout: () => _controller.logout(),
              apiClient: _apiClient,
              authController: _controller,
            );
          } else {
            return UnsupportedRoleScreen(
              authController: _controller,
              roleName: role.displayLabel,
            );
          }
        }

        return LoginScreen(authController: _controller);
      },
    );
  }
}

class _UnconfiguredAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    throw UnimplementedError('Backend API required — to be supplied by Syed.');
  }

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<void> requestPasswordResetOtp({required String phone}) async {}

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<AuthUser> getCurrentUser({required String accessToken}) async {
    throw UnimplementedError('Backend API required — to be supplied by Syed.');
  }
}

class AuthenticatedAppShell extends StatelessWidget {
  final AuthSession session;
  final VoidCallback onLogout;
  final ApiClient? apiClient;

  const AuthenticatedAppShell({
    super.key,
    required this.session,
    required this.onLogout,
    this.apiClient,
  });

  @override
  Widget build(BuildContext context) {
    if (session.role.isAdmin) {
      return AdminShell(session: session, onLogout: onLogout, apiClient: apiClient);
    }
    return ManagerShell(session: session, onLogout: onLogout, apiClient: apiClient);
  }
}


class FoundationShowcaseScreen extends StatefulWidget {
  const FoundationShowcaseScreen({super.key});

  @override
  State<FoundationShowcaseScreen> createState() => _FoundationShowcaseScreenState();
}

class _FoundationShowcaseScreenState extends State<FoundationShowcaseScreen> {
  UserRole _currentRole = UserRole.manager;
  int _selectedTabIndex = 0;
  String _currentRoute = 'home';
  final TextEditingController _samplePhoneController = TextEditingController();
  String? _sampleErrorText;

  void _onRoleChanged(UserRole newRole) {
    setState(() {
      _currentRole = newRole;
      if (_selectedTabIndex >= (_currentRole.isAdmin ? 4 : 5)) {
        _selectedTabIndex = 0;
      }
    });
    AppToast.show(
      context,
      'Switched active role to ${_currentRole.displayLabel} (${_currentRole.consoleTitle})',
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onNavigate(String route) {
    setState(() {
      _currentRoute = route;
    });
    AppToast.show(context, 'Navigated to $route via Drawer');
  }

  @override
  void dispose() {
    _samplePhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      role: _currentRole,
      currentRoute: _currentRoute,
      selectedTabIndex: _selectedTabIndex,
      onTabSelected: _onTabSelected,
      onNavigate: _onNavigate,
      onLogout: () {
        AppToast.show(context, 'Logout triggered — returning to session');
      },
      unreadNotifications: 3,
      pendingOrders: 5,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Milestone 1 Banner
            _buildMilestoneBanner(),
            const SizedBox(height: 20),

            // Role Switcher (Verify Admin vs Manager UI Differences)
            _buildRoleSwitcher(),
            const SizedBox(height: 24),

            // Typography Showcase
            _buildTypographySection(),
            const SizedBox(height: 24),

            // Color Tokens
            _buildColorTokensSection(),
            const SizedBox(height: 24),

            // Status Pills
            _buildStatusPillsSection(),
            const SizedBox(height: 24),

            // Stat Cards & App Cards
            _buildCardsSection(),
            const SizedBox(height: 24),

            // Form Inputs & Validation Presentation
            _buildFormInputsSection(),
            const SizedBox(height: 24),

            // Interactive Buttons & Toasts
            _buildInteractiveButtonsSection(),
            const SizedBox(height: 24),

            // State Views (Empty, Loading, Error, Skeleton)
            _buildStateViewsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.adminNavyDeep, AppColors.adminNavy],
        ),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.canopy,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'MILESTONE 1 VERIFIED',
                  style: AppTypography.eyebrow(color: Colors.white),
                ),
              ),
              const Spacer(),
              const Icon(Icons.check_circle_rounded, color: AppColors.canopyLight, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Core Theme & Design System Foundation',
            style: AppTypography.displaySmall(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Built strictly to approved HTML designs with zero mock business data. '
            'Ready for clean FastAPI contract integration.',
            style: AppTypography.bodySmall(color: const Color(0xFFD6E2EE)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitcher() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, color: AppColors.adminNavy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verify Role-Aware Navigation',
                  style: AppTypography.titleSmall(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Switch roles to observe dynamic bottom navigation (Admin: 4 tabs vs. Manager: 5 tabs) '
            'and drawer menu filtering (Managers, Reports, Logs, Credits, Cache).',
            style: AppTypography.bodySmall(color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildRoleButton(
                  role: UserRole.manager,
                  label: 'Manager Role',
                  subtitle: '5 Tabs · Field Focus',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildRoleButton(
                  role: UserRole.admin,
                  label: 'Admin Role',
                  subtitle: '4 Tabs · 17 Drawer Items',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _currentRole == role;

    return Material(
      color: isSelected ? AppColors.adminNavy : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _onRoleChanged(role),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(
            children: [
              Text(
                label,
                style: AppTypography.titleSmall(
                  color: isSelected ? Colors.white : AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall(
                  color: isSelected ? const Color(0xFFD6E2EE) : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TYPOGRAPHY SCALING', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fraunces Serif Display', style: AppTypography.displayLarge()),
              const SizedBox(height: 6),
              Text('Manrope Primary Sans-Serif Body', style: AppTypography.bodyMedium()),
              const SizedBox(height: 6),
              Text('JetBrains Mono · ₹1,24,800 · SR-2041', style: AppTypography.monoLarge()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorTokensSection() {
    final tokens = [
      {'name': 'Admin Navy', 'color': AppColors.adminNavy},
      {'name': 'Canopy Green', 'color': AppColors.canopy},
      {'name': 'Forest Dark', 'color': AppColors.forest},
      {'name': 'Amber Soft', 'color': AppColors.amber},
      {'name': 'Surface Alt', 'color': AppColors.surfaceAlt},
      {'name': 'Alert Red', 'color': AppColors.alert},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('COLOR DESIGN TOKENS', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tokens.map((t) {
            final color = t['color'] as Color;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                t['name'] as String,
                style: AppTypography.bodySmall(
                  color: color.computeLuminance() > 0.5 ? AppColors.text : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStatusPillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS PILLS (.pill in HTML)', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusPill.fromStatus('approved'),
            StatusPill.fromStatus('pending'),
            StatusPill.fromStatus('rejected'),
            StatusPill.fromStatus('upcoming'),
            StatusPill.fromStatus('delivered'),
            StatusPill.fromStatus('paid'),
            StatusPill.fromStatus('open'),
            StatusPill.fromStatus('full'),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STAT CARDS (.stat-card in HTML)', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: const Icon(Icons.shopping_cart_outlined, size: 18, color: Color(0xFF0369A1)),
                iconBackgroundColor: const Color(0xFFECF5FD),
                value: '4',
                label: 'Pending Orders',
                deltaText: '▲ 2 new today',
                onTap: () => AppToast.show(context, 'Seed requests shortcut tapped'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.canopyDeep),
                iconBackgroundColor: const Color(0xFFF0F8EC),
                value: '9',
                label: 'Bookings Today',
                deltaText: '3 slots remaining',
                deltaColor: AppColors.textMuted,
                onTap: () => AppToast.show(context, 'Booking slots shortcut tapped'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormInputsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FORM INPUTS (.field-input-wrap in HTML)', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Phone number',
                hint: '+91 98765 43210',
                controller: _samplePhoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textFaint),
                errorText: _sampleErrorText,
                onChanged: (val) {
                  setState(() {
                    if (val.isNotEmpty && val.length < 10) {
                      _sampleErrorText = 'Phone number must be at least 10 digits';
                    } else {
                      _sampleErrorText = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              const AppTextField(
                label: 'Password',
                hint: 'Enter secure password',
                isPassword: true,
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textFaint),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveButtonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TACTILE BUTTONS & TOAST TRIGGERS', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  AppToast.show(context, 'Primary action successful');
                },
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Primary action'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  AppToast.show(context, 'Validation alert triggered', isError: true);
                },
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('Error toast'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SquircleIconButton(
              icon: const Icon(Icons.search_rounded, size: 18, color: AppColors.forest),
              tooltip: 'Search button',
              onTap: () => AppToast.show(context, 'Search tapped'),
            ),
            SquircleIconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 18, color: AppColors.forest),
              hasBadge: true,
              tooltip: 'Badge button',
              onTap: () => AppToast.show(context, 'Notifications tapped'),
            ),
            SquircleIconButton.back(
              onTap: () => AppToast.show(context, 'Back tapped'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateViewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATE VIEWS (Empty, Skeleton, Loading, Error)', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Animated Shimmer Skeleton (.skel in HTML)', style: AppTypography.bodySmall()),
              const SizedBox(height: 10),
              const AppSkeleton(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              const AppSkeleton(width: 180, height: 16),
              const SizedBox(height: 16),
              const Divider(),
              const EmptyStateView(
                title: 'No records pending',
                description: 'This is the standardized empty state view matching the HTML prototype.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
