import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/user_role.dart';
import 'squircle_icon_button.dart';

class AppNavbar extends StatelessWidget implements PreferredSizeWidget {
  final UserRole role;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLogoTap;
  final bool hasUnreadNotifications;

  const AppNavbar({
    super.key,
    required this.role,
    required this.onOpenDrawer,
    required this.onOpenNotifications,
    required this.onLogoTap,
    this.hasUnreadNotifications = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.line, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(21, 48, 42, 0.07),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SquircleIconButton(
            onTap: onOpenDrawer,
            icon: const Icon(
              Icons.menu_rounded,
              size: 20,
              color: AppColors.forest,
            ),
            tooltip: 'Open menu',
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onLogoTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.adminNavyLight, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(21, 48, 42, 0.12),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Container(
                  color: AppColors.surfaceAlt,
                  alignment: Alignment.center,
                  child: Text(
                    'S',
                    style: GoogleFonts.fraunces(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.adminNavyDeep,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onLogoTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sri Siva Sai Seeds',
                    style: GoogleFonts.manrope(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    role.consoleTitle.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08 * 10,
                      color: AppColors.adminNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SquircleIconButton(
            onTap: onOpenNotifications,
            hasBadge: hasUnreadNotifications,
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppColors.forest,
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}
