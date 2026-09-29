import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/user_role.dart';

class TabItemData {
  final String id;
  final String label;
  final IconData icon;

  const TabItemData({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class CustomTabbar extends StatelessWidget {
  final UserRole role;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CustomTabbar({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  List<TabItemData> get tabs {
    if (role.isAdmin) {
      return const [
        TabItemData(
          id: 'seed-purchase',
          label: 'Seed Purchase',
          icon: Icons.shopping_cart_outlined,
        ),
        TabItemData(
          id: 'booking-slot',
          label: 'Booking Slot',
          icon: Icons.calendar_today_outlined,
        ),
        TabItemData(
          id: 'farm-visits',
          label: 'Farm Visits',
          icon: Icons.location_on_outlined,
        ),
        TabItemData(
          id: 'grain-sales',
          label: 'Grain Sales',
          icon: Icons.storefront_outlined,
        ),
      ];
    } else {
      return const [
        TabItemData(
          id: 'seed-purchase',
          label: 'Seed Purchase',
          icon: Icons.shopping_cart_outlined,
        ),
        TabItemData(
          id: 'booking-slot',
          label: 'Booking Slot',
          icon: Icons.calendar_today_outlined,
        ),
        TabItemData(
          id: 'farm-visits',
          label: 'Farm Visits',
          icon: Icons.location_on_outlined,
        ),
        TabItemData(
          id: 'grain-sales',
          label: 'Grain Sales',
          icon: Icons.storefront_outlined,
        ),
        TabItemData(
          id: 'account',
          label: 'Account',
          icon: Icons.person_outline_rounded,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 8,
        left: 6,
        right: 6,
        bottom: bottomPadding > 0 ? bottomPadding : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: AppColors.line, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(21, 48, 42, 0.06),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isActive = index == selectedIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(14),
              splashColor: AppColors.surfaceAlt,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 22,
                      color: isActive ? AppColors.adminNavy : AppColors.textFaint,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab.label,
                      style: GoogleFonts.manrope(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.adminNavy : AppColors.textFaint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.adminNavyLight : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
