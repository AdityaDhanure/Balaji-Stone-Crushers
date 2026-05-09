import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_refresh_provider.dart';
import '../providers/maintenance_provider.dart';
import '../widgets/maintenance_stats_card.dart';
import '../widgets/records_tab.dart';
import '../widgets/equipment_tab.dart';
import '../widgets/vendors_tab.dart';
import '../widgets/sheets/add_maintenance_sheet.dart';
import '../widgets/sheets/add_equipment_sheet.dart';
import '../widgets/sheets/add_vendor_sheet.dart';
import '../widgets/sheets/record_detail_sheet.dart';
import '../widgets/sheets/equipment_detail_sheet.dart';
import '../widgets/sheets/vendor_detail_sheet.dart';

class MaintenanceListScreen extends ConsumerStatefulWidget {
  const MaintenanceListScreen({super.key});

  @override
  ConsumerState<MaintenanceListScreen> createState() =>
      _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    Future.microtask(() {
      ref.read(maintenanceProvider.notifier).loadAllData();
    });

    ref.listenManual(appRefreshProvider, (prev, next) {
      ref.read(maintenanceProvider.notifier).loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(maintenanceProvider.notifier).loadAllData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner
              if (state.error != null && state.error!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(state.error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              MaintenanceStatsCard(
                stats: state.stats,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 20),
              _MaintenanceTabSection(
                tabController: _tabController,
                state: state,
                isSmallScreen: isSmallScreen,
                onRecordTap: _showRecordDetail,
                onEditRecord: _showEditRecordDialog,
                onDeleteRecord: _showDeleteRecordDialog,
                onEquipmentTap: _showEquipmentDetail,
                onEditEquipment: _showEquipmentDetail,
                onDeleteEquipment: _showDeleteEquipmentDialog,
                onVendorTap: _showVendorDetail,
                onEditVendor: _showVendorDetail,
                onDeleteVendor: _showDeleteVendorDialog,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _AddFAB(
        onAddRecord: _showAddDialog,
        onAddEquipment: _showAddEquipmentDialog,
        onAddVendor: _showAddVendorDialog,
      ),
    );
  }

  // ─── Record actions ───────────────────────────────────────────────────────

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMaintenanceSheet(
        onSave: (data) async {
          final ok =
              await ref.read(maintenanceProvider.notifier).createRecord(data);
          if (ok && mounted) {
            Navigator.pop(context);
            _showSnackBar('Maintenance record added', AppColors.success);
          }
        },
      ),
    );
  }

  void _showEditRecordDialog(MaintenanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMaintenanceSheet(
        existingRecord: record,
        onSave: (data) async {
          final ok = await ref
              .read(maintenanceProvider.notifier)
              .updateRecord(record.id, data);
          if (ok && mounted) {
            Navigator.pop(context);
            _showSnackBar('Record updated', AppColors.success);
          }
        },
      ),
    );
  }

  void _showDeleteRecordDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteDialog(
        title: 'Delete Record',
        message: 'Delete "$name"?',
        onConfirm: () async {
          final ok = await ref.read(maintenanceProvider.notifier).deleteRecord(id);
          if (ok && mounted) {
            _showSnackBar('Record deleted', AppColors.error);
          }
        },
      ),
    );
  }

  void _showRecordDetail(MaintenanceRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordDetailSheet(
        record: record,
        onEdit: () => _showEditRecordDialog(record),
      ),
    );
  }

  // ─── Equipment actions ────────────────────────────────────────────────────

  void _showEquipmentDetail(Equipment equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EquipmentDetailSheet(
        equipment: equipment,
        onUpdate: () {
          _showSnackBar('Equipment updated', AppColors.success);
        },
      ),
    );
  }

  void _showDeleteEquipmentDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteDialog(
        title: 'Delete Equipment',
        message: 'Delete "$name"?',
        onConfirm: () async {
          final ok = await ref.read(maintenanceProvider.notifier).deleteEquipment(id);
          if (ok && mounted) {
            _showSnackBar('Equipment deleted', AppColors.error);
          }
        },
      ),
    );
  }

  void _showAddEquipmentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEquipmentSheet(
        onSave: (data) async {
          final ok = await ref
              .read(maintenanceProvider.notifier)
              .createEquipment(data);
          if (ok && mounted) {
            Navigator.pop(context);
            _showSnackBar('Equipment added', AppColors.success);
          }
        },
      ),
    );
  }

  // ─── Vendor actions ───────────────────────────────────────────────────────

  void _showVendorDetail(Vendor vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VendorDetailSheet(
        vendor: vendor,
        onUpdate: () {
          _showSnackBar('Vendor updated', AppColors.success);
        },
      ),
    );
  }

  void _showDeleteVendorDialog(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteDialog(
        title: 'Delete Vendor',
        message: 'Delete "$name"?',
        onConfirm: () async {
          final ok = await ref.read(maintenanceProvider.notifier).deleteVendor(id);
          if (ok && mounted) {
            _showSnackBar('Vendor deleted', AppColors.error);
          }
        },
      ),
    );
  }

  void _showAddVendorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddVendorSheet(
        onSave: (data) async {
          await ref.read(maintenanceProvider.notifier).createVendor(data);
          if (mounted) {
            Navigator.pop(context);
            _showSnackBar('Vendor added', AppColors.success);
          }
        },
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─── Tab Section ──────────────────────────────────────────────────────────────

class _MaintenanceTabSection extends StatelessWidget {
  final TabController tabController;
  final MaintenanceState state;
  final bool isSmallScreen;
  final void Function(MaintenanceRecord) onRecordTap;
  final void Function(MaintenanceRecord) onEditRecord;
  final void Function(int, String) onDeleteRecord;
  final void Function(Equipment) onEquipmentTap;
  final void Function(Equipment) onEditEquipment;
  final void Function(int, String) onDeleteEquipment;
  final void Function(Vendor) onVendorTap;
  final void Function(Vendor) onEditVendor;
  final void Function(int, String) onDeleteVendor;

  const _MaintenanceTabSection({
    required this.tabController,
    required this.state,
    required this.isSmallScreen,
    required this.onRecordTap,
    required this.onEditRecord,
    required this.onDeleteRecord,
    required this.onEquipmentTap,
    required this.onEditEquipment,
    required this.onDeleteEquipment,
    required this.onVendorTap,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Styled tab bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicator: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 12),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal, fontSize: 12),
            padding: const EdgeInsets.all(4),
            tabs: [
              _TabItem(
                label: 'Records',
                count: state.records.length,
                icon: Icons.assignment_rounded,
              ),
              _TabItem(
                label: 'Equipment',
                count: state.equipment.length,
                icon: Icons.precision_manufacturing_rounded,
              ),
              _TabItem(
                label: 'Vendors',
                count: state.vendors.length,
                icon: Icons.business_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab content
        SizedBox(
          height: 580,
          child: TabBarView(
            controller: tabController,
            children: [
              RecordsTab(
                isSmallScreen: isSmallScreen,
                onRecordTap: onRecordTap,
                onEditRecord: onEditRecord,
                onDeleteRecord: onDeleteRecord,
              ),
              EquipmentTab(
                isSmallScreen: isSmallScreen,
                onEquipmentTap: onEquipmentTap,
                onEditEquipment: onEditEquipment,
                onDeleteEquipment: onDeleteEquipment,
              ),
              VendorsTab(
                isSmallScreen: isSmallScreen,
                onVendorTap: onVendorTap,
                onEditVendor: onEditVendor,
                onDeleteVendor: onDeleteVendor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab Item ─────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _TabItem({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Flexible(
              child: Text(label, overflow: TextOverflow.ellipsis)),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _AddFAB extends StatelessWidget {
  final VoidCallback onAddRecord;
  final VoidCallback onAddEquipment;
  final VoidCallback onAddVendor;

  const _AddFAB({
    required this.onAddRecord,
    required this.onAddEquipment,
    required this.onAddVendor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        switch (v) {
          case 'record':
            onAddRecord();
          case 'equipment':
            onAddEquipment();
          case 'vendor':
            onAddVendor();
        }
      },
      itemBuilder: (_) => [
        _menuItem('record', Icons.build_rounded, 'Maintenance Record'),
        _menuItem('equipment', Icons.precision_manufacturing_rounded, 'Equipment'),
        _menuItem('vendor', Icons.business_rounded, 'Vendor'),
      ],
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
          String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}

// ─── Delete Dialog ────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;

  const _DeleteDialog({
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}