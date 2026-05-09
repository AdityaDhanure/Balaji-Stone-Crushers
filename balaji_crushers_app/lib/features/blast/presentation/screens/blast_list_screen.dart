import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../providers/blast_provider.dart';
import '../widgets/active_blast_card.dart';

const _kAccent = Color(0xFFE67E22);
const _kAccentDark = Color(0xFFD35400);

class BlastListScreen extends ConsumerStatefulWidget {
  const BlastListScreen({super.key});

  @override
  ConsumerState<BlastListScreen> createState() => _BlastListScreenState();
}

class _BlastListScreenState extends ConsumerState<BlastListScreen> {
  int _lastRefresh = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(blastProvider.notifier).loadBlasts();
      ref.read(blastProvider.notifier).loadActiveBlast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final refresh = ref.watch(appRefreshProvider);
    final state = ref.watch(blastProvider);
    final isSmall = MediaQuery.of(context).size.width < 800;

    if (refresh != _lastRefresh) {
      _lastRefresh = refresh;
      Future.microtask(() {
        ref.read(blastProvider.notifier).loadBlasts();
        ref.read(blastProvider.notifier).loadActiveBlast();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // ── Active blast hero card ──────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, isSmall ? 12 : 20, isSmall ? 12 : 20, 0),
          child: state.activeBlast == null
              ? NoActiveBlastCard(isSmallScreen: isSmall, onStartBlast: () => context.push('/blast/new'))
              : ActiveBlastCard(
                  blast: state.activeBlast!,
                  isCompleted: state.activeBlast!['status'] == 'completed',
                  isSmallScreen: isSmall,
                  onViewDetails: () {
                    final id = _safeId(state.activeBlast!['id']);
                    if (id != null) context.push('/blast/detail/$id');
                  },
                  onToggleStatus: () {
                    final id = _safeId(state.activeBlast!['id']);
                    if (id == null) return;
                    if (state.activeBlast!['status'] == 'completed') {
                      _showReopenDialog(id);
                    } else {
                      _showCompleteDialog(id);
                    }
                  },
                ),
        ),
        const SizedBox(height: 14),
        // ── Section header ──────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20),
          child: Row(children: [
            const Text('All Blasts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
            const Spacer(),
            if (state.isLoading) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: _kAccent)),
            if (!state.isLoading) Text('${state.blasts.length} total', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        const SizedBox(height: 8),
        // ── Blast list ──────────────────────────────────────────────────────
        Expanded(
          child: state.blasts.isEmpty
              ? const BlastEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(isSmall ? 12 : 20, 0, isSmall ? 12 : 20, 100),
                  itemCount: state.blasts.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BlastListItem(
                      blast: state.blasts[i],
                      isSmallScreen: isSmall,
                      onTap: () {
                        final id = _safeId(state.blasts[i]['id']);
                        if (id != null) context.push('/blast/detail/$id');
                      },
                    ),
                  ),
                ),
        ),
      ]),
      floatingActionButton: _BlastFAB(onPressed: () => context.push('/blast/new')),
    );
  }

  /// Safely extracts an [int] id from a dynamic value that may be
  /// an [int], a numeric [String], or null.
  int? _safeId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  void _showCompleteDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20), SizedBox(width: 8), Text('Complete Blast')]),
        content: const Text('Mark this blast as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(blastProvider.notifier).completeBlast(id);
            },
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReopenDialog(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.refresh_rounded, color: AppColors.warning, size: 20), SizedBox(width: 8), Text('Reopen Blast')]),
        content: const Text('Mark this blast as active again?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(blastProvider.notifier).reopenBlast(id);
            },
            child: const Text('Reopen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BlastFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _BlastFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_kAccent, _kAccentDark]),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Material(
      color: Colors.transparent, borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed, borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('New Blast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
        ),
      ),
    ),
  );
}