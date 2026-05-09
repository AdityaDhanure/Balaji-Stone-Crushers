import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/maintenance_provider.dart';
import 'vendor_card.dart';
import 'common/empty_state.dart';

class VendorsTab extends ConsumerWidget {
  final bool isSmallScreen;
  final void Function(Vendor) onVendorTap;
  final void Function(Vendor) onEditVendor;
  final void Function(int, String) onDeleteVendor;

  const VendorsTab({
    super.key,
    this.isSmallScreen = false,
    required this.onVendorTap,
    required this.onEditVendor,
    required this.onDeleteVendor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceProvider);

    if (state.isLoading && state.vendors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.vendors.isEmpty) {
      return const MaintenanceEmptyState(
        message: 'No vendors added',
        subtitle: 'Add service providers and repair shops',
        icon: Icons.business_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemCount: state.vendors.length,
      itemBuilder: (_, i) {
        final vendor = state.vendors[i];
        return VendorCard(
          vendor: vendor,
          onTap: () => onVendorTap(vendor),
          onEdit: () => onEditVendor(vendor),
          onDelete: () => onDeleteVendor(vendor.id, vendor.name),
        );
      },
    );
  }
}