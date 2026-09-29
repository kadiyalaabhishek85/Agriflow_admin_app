import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../controllers/auth_controller.dart';

/// Native Startup / Splash Screen matching approved HTML #flow-splash and visual references.
/// Displays Sri Siva Sai Seeds branding on dark navy background.
/// Waits for user interaction (tap anywhere) before initiating session restoration.
class SplashScreen extends StatefulWidget {
  final AuthController authController;

  const SplashScreen({
    super.key,
    required this.authController,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Do NOT automatically call restoreSession() here.
    // The screen must wait for explicit user tap.
  }

  void _onTap() {
    // Prevent duplicate calls if session restoration is already in progress
    if (widget.authController.state.isSessionRestoring) {
      return;
    }
    widget.authController.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.adminNavyDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.adminNavyDeep, // #16293F
                AppColors.adminNavy,     // #1E3A5C
              ],
            ),
          ),
          child: GestureDetector(
            onTap: _onTap,
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Logo Container matching HTML .splash-logo
                      Container(
                        width: 156,
                        height: 156,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.92),
                            width: 4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.55),
                              blurRadius: 46,
                              spreadRadius: -14,
                              offset: Offset(0, 20),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/sri_siva_sai_seeds_logo.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            semanticLabel: 'Sri Siva Sai Seeds Logo',
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Brand Title matching HTML #flow-splash
                      Text(
                        'Sri Siva Sai Seeds',
                        style: AppTypography.displayLarge(
                          color: const Color(0xFFEEF3F9),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),

                      // Admin Badge matching HTML .splash-badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 13,
                              color: Color(0xFFEEF3F9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ADMIN CONSOLE',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.06 * 11,
                                color: const Color(0xFFEEF3F9),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Tap Hint / Loading state matching HTML .splash-tap-hint
                      ListenableBuilder(
                        listenable: widget.authController,
                        builder: (context, _) {
                          final isRestoring =
                              widget.authController.state.isSessionRestoring;
                          if (isRestoring) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFEEF3F9),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Session restoring...',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.04 * 11,
                                    color: const Color(0xFFEEF3F9).withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Text(
                            'Tap anywhere to continue',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.04 * 11,
                              color: const Color(0xFFEEF3F9).withValues(alpha: 0.7),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
