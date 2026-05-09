import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/employee_provider.dart';
import 'employee_card.dart';
import 'employee_filters.dart';
import 'employee_search_bar.dart';

class EmployeesTab extends ConsumerStatefulWidget {
  final bool isSmallScreen;
  final String selectedDepartment;
  final ValueChanged<String> onDepartmentChanged;
  final Function(Employee) onEmployeeTap;
  final Function(Employee) onEditEmployee;

  const EmployeesTab({
    super.key,
    required this.isSmallScreen,
    required this.selectedDepartment,
    required this.onDepartmentChanged,
    required this.onEmployeeTap,
    required this.onEditEmployee,
  });

  @override
  ConsumerState<EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends ConsumerState<EmployeesTab> {
  String _searchQuery = '';

  List<Employee> _filterEmployees(List<Employee> employees) {
    var filtered = employees;

    if (widget.selectedDepartment != 'all') {
      filtered = filtered.where((e) => e.departmentName == widget.selectedDepartment).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.fullName.toLowerCase().contains(q) ||
            e.employeeCode.toLowerCase().contains(q) ||
            (e.designation?.toLowerCase().contains(q) ?? false) ||
            (e.phone?.contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeeProvider);
    final filteredEmployees = _filterEmployees(state.employees);

    if (state.isLoading && state.employees.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        EmployeeSearchBar(
          onChanged: (q) => setState(() => _searchQuery = q),
        ),
        const SizedBox(height: 10),
        EmployeeFilters(
          departments: state.departments,
          selectedDepartment: widget.selectedDepartment,
          onDepartmentChanged: widget.onDepartmentChanged,
        ),
        const SizedBox(height: 10),
        if (filteredEmployees.isEmpty)
          Expanded(child: _buildEmptyState(_searchQuery.isNotEmpty ? 'No employees match your search' : 'No employees found'))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: filteredEmployees.length,
              itemBuilder: (context, index) {
                final employee = filteredEmployees[index];
                return EmployeeCard(
                  employee: employee,
                  isSmallScreen: widget.isSmallScreen,
                  onTap: () => widget.onEmployeeTap(employee),
                  onEdit: () => widget.onEditEmployee(employee),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}