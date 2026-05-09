import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ist_date_utils.dart';
import '../providers/employee_provider.dart';

class EmployeeDetailSheet extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;

  const EmployeeDetailSheet({
    super.key,
    required this.employee,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              _DetailHeader(employee: employee, onEdit: onEdit),
              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    children: [
                      _SectionCard(
                        title: 'Employment Info',
                        icon: Icons.work_outline_rounded,
                        children: [
                          _InfoRow(icon: Icons.badge_outlined, label: 'Employee Code', value: employee.employeeCode),
                          _InfoRow(icon: Icons.business_rounded, label: 'Department', value: employee.departmentName ?? 'Not assigned'),
                          _InfoRow(icon: Icons.person_pin_outlined, label: 'Designation', value: employee.designation ?? 'Not set'),
                          _InfoRow(icon: Icons.category_outlined, label: 'Employee Type', value: employee.typeDisplay),
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date of Joining',
                            value: _formatDate(employee.dateOfJoining),
                          ),
                          _StatusRow(isActive: employee.isActive),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Salary & Leaves',
                        icon: Icons.account_balance_wallet_outlined,
                        children: [
                          _SalaryRow(salary: employee.salary),
                          _InfoRow(
                            icon: Icons.event_note_outlined,
                            label: 'Paid Leave Balance',
                            value: '${employee.paidLeaveBalance ?? 15} days',
                          ),
                          _InfoRow(
                            icon: Icons.beach_access_outlined,
                            label: 'Leaves Taken',
                            value: '${employee.leavesTaken ?? 0} days',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (employee.phone != null || employee.email != null)
                        _SectionCard(
                          title: 'Contact',
                          icon: Icons.contact_phone_outlined,
                          children: [
                            if (employee.phone != null) _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: employee.phone!),
                            if (employee.email != null) _InfoRow(icon: Icons.email_outlined, label: 'Email', value: employee.email!),
                            if (employee.address != null) _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: employee.address!),
                          ],
                        ),
                      if (employee.aadhaarNumber != null || employee.panNumber != null || employee.upiId != null || employee.bankAccount != null) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Financial Details',
                          icon: Icons.credit_card_outlined,
                          children: [
                            if (employee.aadhaarNumber != null) _InfoRow(icon: Icons.credit_card, label: 'Aadhaar', value: employee.aadhaarNumber!),
                            if (employee.panNumber != null) _InfoRow(icon: Icons.badge_outlined, label: 'PAN', value: employee.panNumber!),
                            if (employee.upiId != null) _InfoRow(icon: Icons.payments_outlined, label: 'UPI ID', value: employee.upiId!),
                            if (employee.bankAccount != null) _InfoRow(icon: Icons.account_balance_outlined, label: 'Bank Account', value: employee.bankAccount!),
                            if (employee.bankName != null) _InfoRow(icon: Icons.account_balance, label: 'Bank Name', value: employee.bankName!),
                            if (employee.ifscCode != null) _InfoRow(icon: Icons.pin_outlined, label: 'IFSC Code', value: employee.ifscCode!),
                          ],
                        ),
                      ],
                      if (employee.emergencyContactName != null) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Emergency Contact',
                          icon: Icons.emergency_outlined,
                          children: [
                            _InfoRow(icon: Icons.person_outline, label: 'Name', value: employee.emergencyContactName!),
                            if (employee.emergencyContactPhone != null)
                              _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: employee.emergencyContactPhone!),
                            if (employee.emergencyContactRelation != null)
                              _InfoRow(icon: Icons.family_restroom_outlined, label: 'Relation', value: employee.emergencyContactRelation!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      final parsed = appParseIstDate(date);
      return parsed == null ? '-' : DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;

  const _DetailHeader({required this.employee, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(employee.employeeType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight.withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5),
                ),
                child: Center(
                  child: Text(
                    employee.firstName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  employee.typeDisplay,
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            employee.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            employee.designation ?? employee.employeeCode,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
          ),
          const SizedBox(height: 14),
          // Edit button
          SizedBox(
            width: 180,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onEdit();
              },
              icon: const Icon(Icons.edit_rounded, size: 15),
              label: const Text('Edit Employee', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'contract':
        return AppColors.warning;
      case 'daily':
        return AppColors.info;
      default:
        return AppColors.success;
    }
  }
}

// ─── Section Card ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Salary Row ────────────────────────────────────────────────────────────────

class _SalaryRow extends StatelessWidget {
  final double salary;
  const _SalaryRow({required this.salary});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.currency_rupee_outlined, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Monthly Salary', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Row(
                  children: [
                    Text(
                      '₹${fmt.format(salary)}',
                      style: const TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const Text(' /month', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Row ────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final bool isActive;
  const _StatusRow({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: (isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
