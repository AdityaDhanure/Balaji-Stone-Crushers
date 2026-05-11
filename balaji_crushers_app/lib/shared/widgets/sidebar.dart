import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// ─── Data ──────────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

class _NavGroup {
  final String? title;
  final List<_NavItem> items;
  const _NavGroup({this.title, required this.items});
}

const _navGroups = [
  _NavGroup(items: [
    _NavItem(AppStrings.dashboard, Icons.dashboard_rounded, '/dashboard'),
  ]),
  _NavGroup(title: 'Operations', items: [
    _NavItem(AppStrings.blast,    Icons.bolt_rounded,            '/blast'),
    _NavItem(AppStrings.vehicles, Icons.local_shipping_rounded,  '/vehicles'),
    _NavItem(AppStrings.diesel,   Icons.local_gas_station_rounded, '/diesel'),
    _NavItem(AppStrings.crusher,  Icons.factory_rounded,         '/crusher'),
  ]),
  _NavGroup(title: 'Business', items: [
    _NavItem(AppStrings.customers, Icons.people_rounded,               '/customers'),
    _NavItem(AppStrings.billing,   Icons.receipt_long_rounded,         '/billing'),
    _NavItem(AppStrings.expenses,  Icons.account_balance_wallet_rounded, '/expenses'),
  ]),
  _NavGroup(title: 'Human Resources', items: [
    _NavItem(AppStrings.employees,   Icons.badge_rounded,         '/employees'),
    _NavItem(AppStrings.attendance,  Icons.checklist_rounded,     '/attendance'),
    _NavItem(AppStrings.salary,      Icons.payments_rounded,      '/salary'),
    _NavItem(AppStrings.maintenance, Icons.build_rounded,         '/maintenance'),
  ]),
  _NavGroup(title: 'Analytics', items: [
    _NavItem(AppStrings.reports,  Icons.bar_chart_rounded,   '/reports'),
    _NavItem(AppStrings.settings, Icons.settings_rounded,    '/settings'),
  ]),
];

// ─── Main Sidebar ──────────────────────────────────────────────────────────────

class Sidebar extends ConsumerWidget {
  final String currentRoute;
  const Sidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user ?? {};
    final username = user['username'] as String? ?? user['name'] as String? ?? 'Manager';
    final role = user['role'] as String? ?? 'Administrator';

    return Container(
      width: 252,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1E32), Color(0xFF1A2E4A), Color(0xFF1E3A5F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(4, 0)),
        ],
      ),
      child: Column(children: [
        // ── Logo / Brand ───────────────────────────────────────────────────
        _SidebarHeader(),
        const SizedBox(height: 4),

        // ── Divider ────────────────────────────────────────────────────────
        Divider(color: Colors.white.withValues(alpha: 0.07), height: 1, indent: 16, endIndent: 16),
        const SizedBox(height: 6),

        // ── Navigation ────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            itemCount: _navGroups.length,
            itemBuilder: (context, gi) {
              final group = _navGroups[gi];
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (group.title != null) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 4),
                    child: Text(
                      group.title!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
                ...group.items.map((item) => _SidebarTile(
                  item: item,
                  isActive: currentRoute.startsWith(item.route) && (item.route != '/dashboard' || currentRoute == '/dashboard'),
                  onTap: () => context.go(item.route),
                )),
              ]);
            },
          ),
        ),

        // ── Bottom divider ─────────────────────────────────────────────────
        Divider(color: Colors.white.withValues(alpha: 0.07), height: 1, indent: 16, endIndent: 16),

        // ── User footer ────────────────────────────────────────────────────
        _SidebarFooter(username: username, role: role, ref: ref),
      ]),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(children: [
        // Logo icon with glow
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 3)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 11),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Balaji Crushers',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
          Text('ERP Management System',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 9.5, letterSpacing: 0.3)),
        ]),
      ]),
    );
  }
}

// ─── Tile ──────────────────────────────────────────────────────────────────────

class _SidebarTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _SidebarTile({required this.item, required this.isActive, required this.onTap});
  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.1)
                  : _hovered
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              border: active
                  ? Border.all(color: AppColors.accent.withValues(alpha: 0.25), width: 0.8)
                  : null,
            ),
            child: Row(children: [
              // Left active bar
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Icon
              Container(
                width: 30,
                height: 30,
                decoration: active
                    ? BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                      )
                    : null,
                child: Icon(
                  widget.item.icon,
                  size: 17,
                  color: active
                      ? AppColors.accent
                      : _hovered
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              // Label
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? Colors.white
                        : _hovered
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              // Active dot
              if (active)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Footer ────────────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  final String username;
  final String role;
  final WidgetRef ref;
  const _SidebarFooter({required this.username, required this.role, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 6)],
            ),
            child: Center(
              child: Text(username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(username,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            Text(role,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 10),
                overflow: TextOverflow.ellipsis),
          ])),
          // Actions
          _FooterIconBtn(icon: Icons.person_outline_rounded, tooltip: 'Profile', onTap: () => context.go('/profile')),
          const SizedBox(width: 2),
          _FooterIconBtn(
              icon: Icons.logout_rounded,
              tooltip: 'Logout',
              color: AppColors.error.withValues(alpha: 0.8),
              onTap: () => _confirmLogout(context)),
        ]),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _FooterIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const _FooterIconBtn({required this.icon, required this.tooltip, required this.onTap, this.color});
  @override
  State<_FooterIconBtn> createState() => _FooterIconBtnState();
}

class _FooterIconBtnState extends State<_FooterIconBtn> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tooltip,
    child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(widget.icon, size: 15,
              color: widget.color ?? Colors.white.withValues(alpha: _hovered ? 0.9 : 0.5)),
        ),
      ),
    ),
  );
}
