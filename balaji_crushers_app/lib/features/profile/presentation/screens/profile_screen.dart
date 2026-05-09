import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/profile_avatar_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/change_password_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool _profileLoading = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    // Restore profile data on open. Uses addPostFrameCallback so Riverpod
    // is safe to read and the widget tree is fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) {
        setState(() => _profileLoading = false);
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileLoading = false;
          _profileError = e.toString().replaceAll('Exception: ', '');
        });
        _fadeCtrl.forward(from: 0);
      }
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _openEditProfile(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        user: user,
        onSave: (data) async {
          await ref.read(authProvider.notifier).updateProfile(data);
          if (mounted) {
            _showSnack('Profile updated successfully', AppColors.success);
          }
        },
      ),
    );
  }

  void _openChangePassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePasswordSheet(
        onSave: (current, newPass) async {
          await ref
              .read(authProvider.notifier)
              .changePassword(current, newPass);
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ref.listen is intentionally NOT used here because it only fires on
    // state changes AFTER the widget mounts, never for the current state.
    // _loadProfile() handles the initial reveal via addPostFrameCallback.

    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Gradient avatar header ────────────────────────────────────
              ProfileAvatarHeader(user: user),

              // ── Profile load error banner ─────────────────────────────────
              if (_profileError != null)
                _ProfileErrorBanner(
                  message: _profileError!,
                  onRetry: _loadProfile,
                ),

              // ── Loading shimmer ───────────────────────────────────────────
              if (_profileLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                  ),
                )
              else
                FadeTransition(
                  opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information card
                      ProfileInfoCard(
                        title: 'Personal Information',
                        icon: Icons.person_rounded,
                        accentColor: AppColors.primary,
                        trailing: _EditButton(
                            onTap: () => _openEditProfile(user)),
                        rows: [
                          ProfileInfoRow(
                            icon: Icons.badge_rounded,
                            label: 'Full Name',
                            value: user['name'] ?? '',
                          ),
                          ProfileInfoRow(
                            icon: Icons.email_rounded,
                            label: 'Email Address',
                            value: user['email'] ?? '',
                          ),
                          ProfileInfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Phone Number',
                            value: user['phone'] ?? '',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Work Information card
                      ProfileInfoCard(
                        title: 'Work Information',
                        icon: Icons.business_center_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                        rows: [
                          ProfileInfoRow(
                            icon: Icons.work_rounded,
                            label: 'Designation',
                            value: user['designation'] ?? '',
                          ),
                          ProfileInfoRow(
                            icon: Icons.apartment_rounded,
                            label: 'Department',
                            value: user['department'] ?? '',
                          ),
                          ProfileInfoRow(
                            icon: Icons.shield_rounded,
                            label: 'Role',
                            value: (user['role'] as String? ?? '').toUpperCase(),
                            badge: _roleBadge(user['role']),
                            badgeColor: _roleColor(user['role']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Account card
                      ProfileInfoCard(
                        title: 'Account Details',
                        icon: Icons.manage_accounts_rounded,
                        accentColor: AppColors.info,
                        rows: [
                          ProfileInfoRow(
                            icon: Icons.alternate_email_rounded,
                            label: 'Username',
                            value: user['username'] ?? '',
                          ),
                          ProfileInfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Member Since',
                            value: _formatDate(user['created_at']),
                          ),
                          ProfileInfoRow(
                            icon: Icons.login_rounded,
                            label: 'Last Login',
                            value: _formatDate(user['last_login']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Action Buttons ─────────────────────────────────────
                      _ActionTile(
                        icon: Icons.lock_reset_rounded,
                        label: 'Change Password',
                        subtitle: 'Update your account password',
                        color: const Color(0xFFEF4444),
                        onTap: _openChangePassword,
                      ),
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        subtitle: 'Sign out of your account',
                        color: AppColors.error,
                        onTap: _logout,
                        isDanger: true,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = appParseIstDateTime(raw);
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String? _roleBadge(dynamic role) {
    final r = (role as String? ?? '').toUpperCase();
    return r.isNotEmpty ? r : null;
  }

  Color _roleColor(dynamic role) {
    switch ((role as String? ?? '').toLowerCase()) {
      case 'admin':   return const Color(0xFFEF4444);
      case 'manager': return const Color(0xFF8B5CF6);
      default:        return AppColors.info;
    }
  }
}

// ── Edit button (compact, shown in card header) ───────────────────────────────

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, size: 13, color: AppColors.primary),
            SizedBox(width: 5),
            Text('Edit',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ── Action tile (change password / logout) ────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDanger
          ? color.withValues(alpha: 0.05)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDanger
                  ? color.withValues(alpha: 0.25)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDanger ? color : AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile error banner ──────────────────────────────────────────────────────

class _ProfileErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              textStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
