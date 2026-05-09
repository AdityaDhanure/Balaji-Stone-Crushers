import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/settings_service.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final SettingsService _service = SettingsService();
  final _formKey = GlobalKey<FormState>();

  Map<String, String> _settings = {};
  Map<String, String> _original = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool get _hasChanges => _settings.toString() != _original.toString();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadSettings();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getAllSettings();
      if (mounted) {
        setState(() {
          _settings = data;
          _original = Map.from(data);
          _isLoading = false;
        });
        _fadeCtrl.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_hasChanges) {
      _showSnackBar('No changes to save', isInfo: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final result = await _service.bulkUpdateSettings(_settings);
      if (mounted) {
        if (result.errors.isEmpty) {
          setState(() => _original = Map.from(_settings));
          _showSnackBar('Settings saved successfully');
        } else {
          _showSnackBar(
            'Saved ${result.updatedCount} settings with ${result.errors.length} error(s)',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _discardChanges() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Discard Changes?',
        message: 'All unsaved changes will be lost.',
        confirmLabel: 'Discard',
        confirmColor: AppColors.error,
      ),
    );
    if (confirm == true && mounted) {
      setState(() => _settings = Map.from(_original));
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Reset to Defaults?',
        message:
            'All settings will be reset to factory defaults. This cannot be undone.',
        confirmLabel: 'Reset',
        confirmColor: AppColors.error,
      ),
    );
    if (confirm == true && mounted) {
      try {
        await _service.resetToDefaults();
        if (mounted) {
          _showSnackBar('Settings reset to defaults');
          _loadSettings();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            e.toString().replaceAll('Exception: ', ''),
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _exportSettings() async {
    try {
      final data = await _service.exportSettings();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.upload_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Export Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: 480,
            height: 320,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(data),
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<void> _importSettings() async {
    final controller = TextEditingController();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Import Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Paste exported JSON here...',
              filled: true,
              fillColor: AppColors.background,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              try {
                final data = json.decode(controller.text);
                Navigator.pop(context, data);
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid JSON')),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        await _service.importSettings(result);
        if (mounted) {
          _showSnackBar('Settings imported successfully');
          _loadSettings();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            e.toString().replaceAll('Exception: ', ''),
            isError: true,
          );
        }
      }
    }
  }

  void _showSnackBar(String message,
      {bool isError = false, bool isInfo = false}) {
    final color = isError
        ? AppColors.error
        : isInfo
            ? AppColors.info
            : AppColors.success;
    final icon = isError
        ? Icons.error_outline_rounded
        : isInfo
            ? Icons.info_outline_rounded
            : Icons.check_circle_outline_rounded;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage company info, invoice & alert preferences',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          if (!_isLoading) ...[
            if (_hasChanges) ...[
              _HeaderButton(
                label: 'Discard',
                icon: Icons.undo_rounded,
                onTap: _discardChanges,
                outlined: true,
              ),
              const SizedBox(width: 8),
            ],
            _HeaderButton(
              label: _isSaving ? 'Saving…' : 'Save',
              icon: _isSaving ? Icons.hourglass_top_rounded : Icons.save_rounded,
              onTap: _isSaving ? null : _saveSettings,
              highlighted: _hasChanges,
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Reset to Defaults',
              child: IconButton(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.restore_rounded,
                    color: Colors.white70, size: 20),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
          String value, IconData icon, String label, Color color) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading settings…',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    if (_error != null && _settings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load settings',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Form(
        key: _formKey,
        child: RefreshIndicator(
          onRefresh: _loadSettings,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unsaved changes banner
                if (_hasChanges) _UnsavedBanner(onSave: _saveSettings),
                if (_hasChanges) const SizedBox(height: 16),

                CompanyInfoSection(
                  settings: _settings,
                  onSettingsChanged: (v) => setState(() => _settings = v),
                ),
                const SizedBox(height: 16),
                InvoiceSettingsSection(
                  settings: _settings,
                  onSettingsChanged: (v) => setState(() => _settings = v),
                ),
                const SizedBox(height: 16),
                AlertThresholdsSection(
                  settings: _settings,
                  onSettingsChanged: (v) => setState(() => _settings = v),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header Button ─────────────────────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;
  final bool highlighted;

  const _HeaderButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.outlined = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white30),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            highlighted ? AppColors.accent : Colors.white.withValues(alpha: 0.15),
        foregroundColor: Colors.white,
        elevation: highlighted ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ── Unsaved Banner ────────────────────────────────────────────────────────────

class _UnsavedBanner extends StatelessWidget {
  final VoidCallback onSave;

  const _UnsavedBanner({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded,
              color: AppColors.accent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'You have unsaved changes',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent),
            ),
          ),
          TextButton(
            onPressed: onSave,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.4))),
            ),
            child: const Text('Save Now',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Confirm Dialog ────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text(message,
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}