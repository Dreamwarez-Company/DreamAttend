import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '/models/employee.dart';
import '/services/employee_service.dart';
import 'create_employee.dart';
import 'utils/app_layout.dart';
import 'widget/search_filter_bar.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _roleTypeOptions = {
    'Manager': 'manager',
    'Employee': 'employee',
  };
  final Map<String, String> _genderOptions = {
    'Male': 'male',
    'Female': 'female',
  };

  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEmployees);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final employees = await _employeeService.getEmployees();
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
      });
    } catch (e) {
      if (!mounted) return;
      errorSnackBar('Error', 'Failed to load employees: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateEmployeePage() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEmployeePage(),
      ),
    );

    if (created == true) {
      await _fetchEmployees();
    }
  }

  Uint8List? _decodeEmployeeImage(String? imageData) {
    if (imageData == null || imageData.trim().isEmpty) {
      return null;
    }

    try {
      return base64Decode(imageData);
    } catch (_) {
      return null;
    }
  }

  Widget _buildEmployeeImagePreview(Employee employee) {
    final imageBytes = _decodeEmployeeImage(employee.image);

    if (imageBytes != null) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Image.memory(
            imageBytes,
            height: 200,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildMissingProfilePlaceholder();
            },
          ),
        ),
      );
    }

    return _buildMissingProfilePlaceholder();
  }

  Widget _buildMissingProfilePlaceholder() {
    return Center(
      child: Container(
        height: 200,
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE8F1F5),
              Color(0xFFD6E5EC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFB8CED8),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 54,
                color: Color(0xFF073850),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Profile Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF073850),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No profile image inserted',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF5D7682),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete ${employee.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _employeeService.archiveEmployee(employee.id);
        if (!mounted) return;
        successSnackBar('Success', '${employee.name} deleted successfully!');
        await _fetchEmployees();
      } catch (e) {
        if (!mounted) return;
        errorSnackBar('Error', 'Error: $e');
      }
    }
  }

  void _showEmployeeDetailsDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Scaffold(
            appBar: AppBar(
              title: Text(employee.name),
              backgroundColor: const Color.fromARGB(255, 7, 56, 80),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _deleteEmployee(employee);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildEmployeeImagePreview(employee),
                    const SizedBox(height: 60),
                    _buildDetailRow('Job Title:', employee.jobTitle),
                    const SizedBox(height: 16),
                    _buildDetailRow('Email:', employee.email),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Role:',
                      _roleTypeOptions.entries
                          .firstWhere(
                            (entry) => entry.value == employee.roleType,
                            orElse: () => const MapEntry('N/A', 'N/A'),
                          )
                          .key,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('DOB:', employee.dob),
                    const SizedBox(height: 16),
                    _buildDetailRow('Mobile:', employee.mobile),
                    const SizedBox(height: 16),
                    _buildDetailRow('Address:', employee.address),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Gender:',
                      _genderOptions.entries
                          .firstWhere(
                            (entry) => entry.value == employee.gender,
                            orElse: () => const MapEntry('N/A', 'N/A'),
                          )
                          .key,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  void _filterEmployees() {
    setState(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((employee) {
          return employee.name.toLowerCase().contains(query) ||
              employee.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Widget _buildEmployeeSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Employees'),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openCreateEmployeePage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchFilterBar(
              controller: _searchController,
              hintText: 'Search by Employee name or email',
              onChanged: _filterEmployees,
              padding: const EdgeInsets.only(bottom: 16),
              borderSide: const BorderSide(color: Colors.transparent),
              enabledBorderSide: const BorderSide(
                color: Colors.transparent,
              ),
              focusedBorderSide: const BorderSide(
                color: Color(0xFF073850),
                width: 2,
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? const Center(child: Text('No employees found'))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = _filteredEmployees[index];
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showEmployeeDetailsDialog(employee),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildEmployeeSummaryRow(
                                          'Job Title:',
                                          employee.jobTitle,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildEmployeeSummaryRow(
                                          'Mobile:',
                                          employee.mobile,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildEmployeeSummaryRow(
                                          'Email:',
                                          employee.email,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildEmployeeSummaryRow(
                                          'Role Type:',
                                          _roleTypeOptions.entries
                                              .firstWhere(
                                                (entry) =>
                                                    entry.value ==
                                                    employee.roleType,
                                                orElse: () =>
                                                    const MapEntry(
                                                  'N/A',
                                                  'N/A',
                                                ),
                                              )
                                              .key,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildEmployeeSummaryRow(
                                          'Gender:',
                                          _genderOptions.entries
                                              .firstWhere(
                                                (entry) =>
                                                    entry.value ==
                                                    employee.gender,
                                                orElse: () =>
                                                    const MapEntry(
                                                  'N/A',
                                                  'N/A',
                                                ),
                                              )
                                              .key,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteEmployee(employee),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
