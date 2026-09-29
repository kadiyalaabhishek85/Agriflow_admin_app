import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/user_role.dart';
import '../navigation/nav_destination.dart';

class CustomDrawer extends StatelessWidget {
  final UserRole role;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final int unreadNotifications;
  final int pendingOrders;

  const CustomDrawer({
    super.key,
    required this.role,
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    this.userName = 'Manager User',
    this.userEmail = 'manager@srisivasaiseeds.com',
    this.unreadNotifications = 0,
    this.pendingOrders = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 16,
      width: MediaQuery.of(context).size.width * 0.82,
      child: Column(
        children: [
          // Drawer Header with Brand Gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.adminNavyDeep, AppColors.adminNavy],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        userName.isNotEmpty
                            ? userName[0].toUpperCase()
                            : (role.isAdmin ? 'A' : 'M'),
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        role.displayLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEEF3F9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEEF3F9).withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Scrollable Menu Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Overview'),
                  _buildDrawerItem(
                    context,
                    destination: NavDestination.home,
                  ),
                  const SizedBox(height: 8),

                  _buildSectionHeader('Operations'),
                  _buildDrawerItem(
                    context,
                    destination: NavDestination.seedPurchase,
                    badge: pendingOrders > 0 ? '$pendingOrders' : null,
                  ),
                  _buildDrawerItem(context, destination: NavDestination.seedsInventory),
                  _buildDrawerItem(context, destination: NavDestination.warehouse),
                  _buildDrawerItem(context, destination: NavDestination.bookingSlot),
                  _buildDrawerItem(context, destination: NavDestination.billing),
                  _buildDrawerItem(context, destination: NavDestination.farmVisits),
                  _buildDrawerItem(context, destination: NavDestination.grainSales),
                  _buildDrawerItem(context, destination: NavDestination.marketRates),

                  if (role.isAdmin) ...[
                    _buildDrawerItem(context, destination: NavDestination.reports),
                    _buildDrawerItem(context, destination: NavDestination.eventLogs),
                  ] else ...[
                    _buildDrawerItem(context, destination: NavDestination.allFarmers),
                  ],

                  const SizedBox(height: 8),

                  // Administration section only for Admin
                  if (role.isAdmin) ...[
                    _buildSectionHeader('Administration'),
                    _buildDrawerItem(context, destination: NavDestination.managers),
                    _buildDrawerItem(context, destination: NavDestination.allFarmers),
                    _buildDrawerItem(context, destination: NavDestination.credits),
                    _buildDrawerItem(context, destination: NavDestination.cacheManagement),
                    const SizedBox(height: 8),
                  ],

                  _buildSectionHeader('Account'),
                  if (!role.isAdmin)
                    _buildDrawerItem(
                      context,
                      destination: NavDestination.notifications,
                      badge: unreadNotifications > 0 ? '$unreadNotifications' : null,
                    ),
                  _buildDrawerItem(context, destination: NavDestination.account),
                  _buildDrawerItem(context, destination: NavDestination.settings),
                  if (!role.isAdmin)
                    _buildDrawerItem(context, destination: NavDestination.help),
                ],
              ),
            ),
          ),

          // Drawer Footer with Logout
          Container(
            padding: EdgeInsets.only(
              top: 12,
              left: 14,
              right: 14,
              bottom: MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom + 4
                  : 14,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line, width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.bad),
                label: Text(
                  'Log out',
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bad,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.badBg,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.08 * 10.5,
          color: AppColors.textFaint,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required NavDestination destination,
    String? badge,
  }) {
    final isSelected = currentRoute == destination.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? AppColors.surfaceAlt : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onNavigate(destination.id);
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.surfaceAlt,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: AppColors.line, width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    destination.icon,
                    size: 17,
                    color: isSelected ? AppColors.adminNavy : AppColors.adminNavyDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.title,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: isSelected ? AppColors.adminNavy : AppColors.text,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.alert,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
