import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/user_role.dart';
import 'app_navbar.dart';
import 'custom_drawer.dart';
import 'custom_tabbar.dart';

class AppScaffold extends StatefulWidget {
  final UserRole role;
  final Widget body;
  final String currentRoute;
  final int selectedTabIndex;
  final ValueChanged<int>? onTabSelected;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onLogout;
  final bool showBottomNav;
  final bool showAppBar;
  final PreferredSizeWidget? customAppBar;
  final String userName;
  final String userEmail;
  final int unreadNotifications;
  final int pendingOrders;

  const AppScaffold({
    super.key,
    required this.role,
    required this.body,
    this.currentRoute = 'home',
    this.selectedTabIndex = 0,
    this.onTabSelected,
    this.onNavigate,
    this.onLogout,
    this.showBottomNav = true,
    this.showAppBar = true,
    this.customAppBar,
    this.userName = 'Manager User',
    this.userEmail = 'manager@srisivasaiseeds.com',
    this.unreadNotifications = 0,
    this.pendingOrders = 0,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhoneViewport = constraints.maxWidth <= 480;

        Widget scaffoldContent = Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          appBar: widget.showAppBar
              ? (widget.customAppBar ??
                  AppNavbar(
                    role: widget.role,
                    onOpenDrawer: _openDrawer,
                    onOpenNotifications: () {
                      widget.onNavigate?.call('notifications');
                    },
                    onLogoTap: () {
                      widget.onNavigate?.call('home');
                    },
                    hasUnreadNotifications: widget.unreadNotifications > 0,
                  ))
              : null,
          drawer: CustomDrawer(
            role: widget.role,
            currentRoute: widget.currentRoute,
            onNavigate: (route) {
              widget.onNavigate?.call(route);
            },
            onLogout: () {
              widget.onLogout?.call();
            },
            userName: widget.userName,
            userEmail: widget.userEmail,
            unreadNotifications: widget.unreadNotifications,
            pendingOrders: widget.pendingOrders,
          ),
          body: widget.body,
          bottomNavigationBar: widget.showBottomNav && widget.onTabSelected != null
              ? CustomTabbar(
                  role: widget.role,
                  selectedIndex: widget.selectedTabIndex,
                  onTabSelected: widget.onTabSelected!,
                )
              : null,
        );

        if (isPhoneViewport) {
          return scaffoldContent;
        }

        // On larger desktop/web screens, center in an elegant phone-frame preview
        // matching the approved HTML preview frame (.device in HTML CSS).
        return Container(
          color: const Color(0xFFDCE6C9),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Container(
            width: 412,
            height: 860,
            decoration: BoxDecoration(
              color: AppColors.adminNavyDeep,
              borderRadius: BorderRadius.circular(52),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 30, 25, 0.45),
                  blurRadius: 70,
                  offset: Offset(0, 30),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: scaffoldContent,
            ),
          ),
        );
      },
    );
  }
}
