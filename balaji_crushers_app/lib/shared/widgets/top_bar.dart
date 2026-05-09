import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/app_refresh_provider.dart';
import '../../core/utils/ist_date_utils.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class TopBar extends ConsumerStatefulWidget {
  final String title;
  final List<Widget>? actions;

  const TopBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  ConsumerState<TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  String _currentTime = '';
  String _currentDate = '';
  bool _isRefreshing = false;
  late AnimationController _spinCtrl;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDateTime());
  }

  void _updateDateTime() {
    if (!mounted) return;
    final now = appNowIst();
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(now);
      _currentDate = DateFormat('EEE, dd MMM yyyy').format(now);
    });
  }

  Future<void> _refreshApp() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _spinCtrl.repeat();
    try {
      ref.read(appRefreshProvider.notifier).refresh();
      await Future.delayed(const Duration(milliseconds: 800));
    } finally {
      if (mounted) {
        _spinCtrl.stop();
        _spinCtrl.reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?['name'] as String? ??
        authState.user?['username'] as String? ?? 'Manager';
    final userInitial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'M';

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, Color(0xFF1A3352), AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // ── Page Title ──────────────────────────────────────────────────
            _buildTitle(),
            const Spacer(),
            // ── DateTime pill ───────────────────────────────────────────────
            _buildDateTimePill(),
            const SizedBox(width: 10),
            // ── Extra actions from caller ───────────────────────────────────
            if (widget.actions != null) ...widget.actions!,
            const SizedBox(width: 6),
            // ── Refresh ─────────────────────────────────────────────────────
            _buildRefreshButton(),
            const SizedBox(width: 4),
            // ── Settings ────────────────────────────────────────────────────
            _buildIconButton(
              icon: Icons.settings_rounded,
              tooltip: 'Settings',
              onTap: () => context.go('/settings'),
            ),
            const SizedBox(width: 10),
            // ── Divider ─────────────────────────────────────────────────────
            Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(width: 10),
            // ── User menu ───────────────────────────────────────────────────
            _buildUserMenu(userName, userInitial, authState),
          ],
        ),
      ),
    );
  }

  // ── Title ──────────────────────────────────────────────────────────────────
  Widget _buildTitle() {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final showBack = currentRoute == '/profile' || currentRoute == '/settings';
    final prevRoute = ref.read(previousRouteProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Back button — only on /profile
        if (showBack) ...[
          Tooltip(
            message: 'Go back',
            preferBelow: true,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => context.go(prevRoute),
                borderRadius: BorderRadius.circular(10),
                hoverColor: Colors.white.withValues(alpha: 0.1),
                splashColor: Colors.white.withValues(alpha: 0.08),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18), width: 1),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        // Accent bar
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ── DateTime pill ──────────────────────────────────────────────────────────
  Widget _buildDateTimePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 13, color: Colors.white.withValues(alpha: 0.65)),
          const SizedBox(width: 6),
          Text(
            _currentDate,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 1, height: 12, color: Colors.white.withValues(alpha: 0.2)),
          ),
          Icon(Icons.access_time_rounded,
              size: 13, color: AppColors.accentLight.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated refresh button ────────────────────────────────────────────────
  Widget _buildRefreshButton() {
    return Tooltip(
      message: 'Refresh all data',
      preferBelow: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _refreshApp,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isRefreshing
                  ? AppColors.accent.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isRefreshing
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: _isRefreshing
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _spinCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: _spinCtrl.value * 2 * math.pi,
                  child: child,
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _isRefreshing
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Generic icon button ────────────────────────────────────────────────────
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      preferBelow: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.08),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
            child: Icon(icon,
                size: 18, color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
      ),
    );
  }

  // ── User dropdown menu ─────────────────────────────────────────────────────
  Widget _buildUserMenu(String userName, String initial, AuthState authState) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      color: AppColors.surface,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      tooltip: '',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient avatar
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.65)),
          ],
        ),
      ),
      onSelected: (value) {
        if (value == 'logout') {
          ref.read(authProvider.notifier).logout();
        } else if (value == 'profile') {
          context.go('/profile');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_outline_rounded,
                    size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('My Profile',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  Text('View & edit profile',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.8))),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout_rounded,
                    size: 17, color: AppColors.error),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Logout',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.error)),
                  Text('Sign out of account',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.8))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
