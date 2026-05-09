import 'package:flutter/material.dart';
import 'package:balaji_crushers_app/core/constants/app_colors.dart';
import 'package:balaji_crushers_app/features/salary/data/models/salary_models.dart';

class SalaryFilters extends StatelessWidget {
  final List<EmployeeSalary> employees;
  final List<Department> departments;
  final EmployeeSalary? selectedEmployee;
  final Department? selectedDepartment;
  final String selectedStatus;
  final ValueChanged<EmployeeSalary?> onEmployeeChanged;
  final ValueChanged<Department?> onDepartmentChanged;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onApply;

  const SalaryFilters({
    super.key,
    required this.employees,
    required this.departments,
    required this.selectedEmployee,
    required this.selectedDepartment,
    required this.selectedStatus,
    required this.onEmployeeChanged,
    required this.onDepartmentChanged,
    required this.onStatusChanged,
    required this.onApply,
  });

  static const _statuses = [
    ('all', 'All', null),
    ('draft', 'Draft', AppColors.textSecondary),
    ('pending', 'Pending', AppColors.warning),
    ('paid', 'Paid', AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Employee filter
            _FilterDropdown<EmployeeSalary?>(
              width: 190,
              label: 'Employee',
              icon: Icons.person_outline,
              value: selectedEmployee,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Employees')),
                ...employees.map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.fullName, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: onEmployeeChanged,
            ),
            const SizedBox(width: 8),

            // Department filter
            _FilterDropdown<Department?>(
              width: 160,
              label: 'Department',
              icon: Icons.business_outlined,
              value: selectedDepartment,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Departments')),
                ...departments.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.name, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: onDepartmentChanged,
            ),
            const SizedBox(width: 12),

            // Status chips
            const Text(
              'Status:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            ...(_statuses.map((s) {
              final isSelected = selectedStatus == s.$1;
              final chipColor = s.$3 ?? AppColors.primary;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onStatusChanged(s.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? chipColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? chipColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      s.$2,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            })),

            const SizedBox(width: 8),
            // Apply button
            ElevatedButton.icon(
              onPressed: onApply,
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final double width;
  final String label;
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.width,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          isDense: true,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}