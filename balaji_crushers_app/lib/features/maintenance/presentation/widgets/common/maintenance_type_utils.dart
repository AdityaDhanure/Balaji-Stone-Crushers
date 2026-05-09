import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

IconData getMaintenanceTypeIcon(String type) {
  switch (type) {
    case 'repair':
      return Icons.build_rounded;
    case 'service':
      return Icons.handyman_rounded;
    case 'inspection':
      return Icons.search_rounded;
    case 'oil_change':
      return Icons.opacity_rounded;
    case 'replacement':
      return Icons.swap_horiz_rounded;
    default:
      return Icons.build_outlined;
  }
}

Color getMaintenanceTypeColor(String type) {
  switch (type) {
    case 'repair':
      return AppColors.error;
    case 'service':
      return AppColors.primary;
    case 'inspection':
      return AppColors.info;
    case 'oil_change':
      return Colors.amber;
    case 'replacement':
      return AppColors.accent;
    default:
      return AppColors.primary;
  }
}

IconData getEquipmentIcon(String type) {
  switch (type) {
    case 'crusher':
      return Icons.precision_manufacturing;
    case 'screen':
      return Icons.grid_view_rounded;
    case 'conveyor':
      return Icons.linear_scale_rounded;
    case 'generator':
      return Icons.electric_bolt;
    case 'hopper':
      return Icons.inventory_2;
    case 'feedertoggle':
      return Icons.toggle_on;
    case 'vibratingfeeder':
      return Icons.vibration;
    default:
      return Icons.construction;
  }
}

String getEquipmentTypeDisplayName(String type) {
  switch (type) {
    case 'crusher':
      return 'Crusher';
    case 'screen':
      return 'Screen';
    case 'conveyor':
      return 'Conveyor';
    case 'generator':
      return 'Generator';
    case 'hopper':
      return 'Hopper';
    case 'feedertoggle':
      return 'Feeder Toggle';
    case 'vibratingfeeder':
      return 'Vibrating Feeder';
    default:
      return type;
  }
}
