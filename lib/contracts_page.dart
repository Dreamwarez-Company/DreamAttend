import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/employee_service.dart';
import '/services/contract_service.dart';
import '/services/api_service.dart';
import '/models/employee.dart';
import '/models/contract_model.dart';
import '/models/salary_structure.dart';
import '/controller/app_constants.dart';
import 'package:table_calendar/table_calendar.dart';
import 'widget/search_filter_bar.dart';
import 'utils/app_layout.dart';

class ContractsPage extends StatefulWidget {
  final bool showDialogOnLoad;

  const ContractsPage({super.key, this.showDialogOnLoad = false});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  final EmployeeService _employeeService = EmployeeService();
  final ContractService _contractService = ContractService();
  final ApiService _apiService = ApiService();
  static const Map<String, int> _contractTypeIdsByCategory = {
    'Permanent': 1,
    'Temporary': 2,
    'Intern': 3,
  };
  static const int _defaultResourceCalendarId = 1;
  List<Employee> _employees = [];
  List<Contract> _contracts = [];
  List<SalaryStructure> _salaryStructures = [];
  String? _selectedEmployee;
  int? _selectedEmployeeId;
  DateTime? _selectedDate;
  DateTime? _selectedEndDate;
  String? _selectedSchedule;
  String? _selectedCategory;
  String? _selectedSalaryStructure;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _wageController = TextEditingController();
  final TextEditingController _hraController = TextEditingController();
  final TextEditingController _daController = TextEditingController();
  final TextEditingController _travelAllowanceController =
      TextEditingController();
  final TextEditingController _mealAllowanceController =
      TextEditingController();
  final TextEditingController _medicalAllowanceController =
      TextEditingController();
  final TextEditingController _overtimeRateController = TextEditingController();
  final TextEditingController _otherAllowanceController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<Contract> get _filteredContracts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _contracts;
    }

    return _contracts
        .where(
          (contract) => contract.employeeName.toLowerCase().contains(query),
        )
        .toList();
  }

  String _normalizeEmployeeName(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  bool _hasDuplicateContract(
    List<Contract> contracts, {
    required int? employeeId,
    required String? employeeName,
  }) {
    final normalizedSelectedName = _normalizeEmployeeName(employeeName);

    return contracts.any((contract) {
      final matchesId = employeeId != null && contract.employeeId == employeeId;
      final matchesName = normalizedSelectedName.isNotEmpty &&
          _normalizeEmployeeName(contract.employeeName) == normalizedSelectedName;
      return matchesId || matchesName;
    });
  }

  void _logError(String context, Object error) {
    debugPrint('$context: $error');
  }

  String _userFriendlyErrorMessage(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final message = error.toString().toLowerCase();

    if (message.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    if (message.contains('failed host lookup') ||
        message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (message.contains('session expired') ||
        message.contains('no valid session') ||
        message.contains('log in')) {
      return 'Your session has expired. Please log in again.';
    }

    return fallback;
  }

  void _showStandardError(
    String context,
    Object error, {
    String title = 'Error',
    String fallback = 'Something went wrong. Please try again.',
  }) {
    _logError(context, error);
    if (!mounted) return;
    errorSnackBar(title, _userFriendlyErrorMessage(error, fallback: fallback));
  }

  Employee? _findEmployeeByName(String? name) {
    if (name == null) return null;

    for (final employee in _employees) {
      if (employee.name == name) {
        return employee;
      }
    }

    return null;
  }

  int? _resolveSalaryStructureId(String? structureName) {
    if (structureName == null) return null;

    for (final structure in _salaryStructures) {
      if (structure.name == structureName) {
        return structure.id;
      }
    }

    return null;
  }

  int? _resolveContractTypeId(String? category) {
    return _contractTypeIdsByCategory[category];
  }

  Future<void> _fetchSalaryStructures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('sessionId');

      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('No valid session found. Please log in.');
      }

      final response = await _apiService.authenticatedGet(
        AppConstants.salaryStructureEndpoint,
        sessionId: sessionId,
        queryParams: const {
          'limit': '100',
          'offset': '0',
          'domain': '[]',
        },
      );

      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] != 'success' || jsonData['data'] is! List) {
        throw Exception('Unexpected salary structure response');
      }

      final structures = (jsonData['data'] as List)
          .map((item) => SalaryStructure.fromJson(item))
          .where((structure) => structure.name.trim().isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _salaryStructures = structures;
        if (_selectedSalaryStructure != null &&
            _resolveSalaryStructureId(_selectedSalaryStructure) == null) {
          _selectedSalaryStructure = null;
        }
      });
    } catch (e) {
      _showStandardError(
        'Fetch salary structures error',
        e,
        fallback: 'Unable to load salary structures right now.',
      );
    }
  }

  Future<Map<String, dynamic>> _buildContractPayload() async {
    final employeeId = _selectedEmployeeId;
    final employeeName = _selectedEmployee;
    final structId = _resolveSalaryStructureId(_selectedSalaryStructure);
    final typeId = _resolveContractTypeId(_selectedCategory);

    if (employeeId == null || employeeName == null) {
      throw StateError('Please select a valid employee.');
    }
    if (structId == null) {
      throw StateError('Please select a valid salary structure.');
    }
    if (typeId == null) {
      throw StateError('Please select a valid employee category.');
    }

    final contractData = {
      'employee_id': employeeId,
      'name': 'Contract for $employeeName',
      'date_start': _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : null,
      'date_end': _selectedEndDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedEndDate!)
          : null,
      'wage': double.tryParse(_wageController.text) ?? 0.0,
      'schedule_pay': _selectedSchedule ?? 'monthly',
      'hra': double.tryParse(_hraController.text) ?? 0.0,
      'da': double.tryParse(_daController.text) ?? 0.0,
      'travel_allowance': double.tryParse(_travelAllowanceController.text) ?? 0.0,
      'meal_allowance': double.tryParse(_mealAllowanceController.text) ?? 0.0,
      'medical_allowance':
          double.tryParse(_medicalAllowanceController.text) ?? 0.0,
      'overtime_rate': double.tryParse(_overtimeRateController.text) ?? 0.0,
      'other_allowance': double.tryParse(_otherAllowanceController.text) ?? 0.0,
      'state': 'draft',
      'struct_id': structId,
      // TODO: Replace this fallback once calendar config is exposed by the API.
      'resource_calendar_id': _defaultResourceCalendarId,
      'type_id': typeId,
    };

    debugPrint('Creating contract payload: $contractData');
    return contractData;
  }

  Future<void> _submitContract() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    if (_employees.isEmpty) {
      errorSnackBar(
        'Error',
        'No employees are available. Please add an employee first.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final latestContracts = await _contractService.getContracts();
      if (!mounted) return;

      final alreadyExists = _hasDuplicateContract(
        latestContracts,
        employeeId: _selectedEmployeeId,
        employeeName: _selectedEmployee,
      );

      if (alreadyExists) {
        setState(() {
          _contracts = latestContracts;
        });
        errorSnackBar(
          'Oops!',
          'Contract already exists for this employee.',
        );
        return;
      }

      final contractData = await _buildContractPayload();
      await _contractService.createContract(contractData);
      if (!mounted) return;

      setState(() {
        _clearForm();
      });
      successSnackBar(
        'Success',
        'Contract created successfully',
      );

      Navigator.pop(context);
      await _fetchContracts();
    } catch (e) {
      _showStandardError(
        'Create contract error',
        e,
        fallback: 'Unable to create the contract right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchContracts();
    _fetchSalaryStructures();
    if (widget.showDialogOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showAddContractScreen();
      });
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final employees = await _employeeService.getEmployees();
      if (!mounted) return;
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      _showStandardError(
        'Fetch employees error',
        e,
        fallback: 'Unable to load employees right now.',
      );
    }
  }

  Future<void> _fetchContracts() async {
    try {
      final contracts = await _contractService.getContracts();
      if (!mounted) return;
      setState(() {
        _contracts = contracts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showStandardError(
        'Fetch contracts error',
        e,
        fallback: 'Unable to load contracts right now.',
      );
    }
  }

  Future<void> _setContractRunning(int contractId) async {
    try {
      await _contractService.setContractRunning(contractId);
      if (!mounted) return;
      successSnackBar('Success', 'Contract set to running state successfully');
      await _fetchContracts();
    } catch (e) {
      _showStandardError(
        'Set contract running error',
        e,
        fallback: 'Unable to update the contract status right now.',
      );
    }
  }

  Future<void> _showContractDetails(Contract contract) async {
    try {
      final detailedContract =
          await _contractService.getContractDetails(contract.id);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(detailedContract.name),
              backgroundColor: const Color.fromARGB(255, 7, 56, 80),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
            ),
            backgroundColor: const Color(0xFFF1F6F9),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'Employee',
                              detailedContract.employeeName,
                              Icons.person_outline,
                            ),
                            _buildDetailRow(
                              'State',
                              detailedContract.state == 'draft'
                                  ? 'New'
                                  : detailedContract.state == 'open'
                                      ? 'Running'
                                      : detailedContract.state,
                              Icons.flag_outlined,
                              isState: true,
                            ),
                            _buildDetailRow(
                              'Start Date',
                              detailedContract.dateStart != null
                                  ? DateFormat('dd MMM yyyy')
                                      .format(detailedContract.dateStart!)
                                  : 'N/A',
                              Icons.calendar_today_outlined,
                            ),
                            _buildDetailRow(
                              'End Date',
                              detailedContract.dateEnd != null
                                  ? DateFormat('dd MMM yyyy')
                                      .format(detailedContract.dateEnd!)
                                  : 'N/A',
                              Icons.calendar_today_outlined,
                            ),
                            _buildDetailRow(
                              'Wage',
                              '₹${detailedContract.wage.toStringAsFixed(2)}',
                              Icons.attach_money_outlined,
                            ),
                            _buildDetailRow(
                              'Schedule',
                              detailedContract.schedulePay ?? 'N/A',
                              Icons.schedule_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allowances',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF073850),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            _buildAllowanceRow(
                              'HRA',
                              detailedContract.hra?.toStringAsFixed(2) ??
                                  '0.00',
                            ),
                            _buildAllowanceRow(
                              'DA',
                              detailedContract.da?.toStringAsFixed(2) ?? '0.00',
                            ),
                            _buildAllowanceRow(
                              'Travel',
                              detailedContract.travelAllowance
                                      ?.toStringAsFixed(2) ??
                                  '0.00',
                            ),
                            _buildAllowanceRow(
                              'Meal',
                              detailedContract.mealAllowance
                                      ?.toStringAsFixed(2) ??
                                  '0.00',
                            ),
                            _buildAllowanceRow(
                              'Medical',
                              detailedContract.medicalAllowance
                                      ?.toStringAsFixed(2) ??
                                  '0.00',
                            ),
                            _buildAllowanceRow(
                              'Overtime Rate',
                              '${detailedContract.overtimeRate?.toStringAsFixed(2) ?? '0.00'}/hr',
                            ),
                            _buildAllowanceRow(
                              'Other',
                              detailedContract.otherAllowance
                                      ?.toStringAsFixed(2) ??
                                  '0.00',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'Type',
                              detailedContract.typeName ?? 'N/A',
                              Icons.category_outlined,
                            ),
                            _buildDetailRow(
                              'Salary Structure',
                              detailedContract.structName ?? 'N/A',
                              Icons.account_balance_wallet_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (detailedContract.state == 'draft')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await _setContractRunning(detailedContract.id);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Set Contract to Running',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      _showStandardError(
        'Fetch contract details error',
        e,
        fallback: 'Unable to load contract details right now.',
      );
    }
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {bool isState = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF073850),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isState
                        ? value == 'New'
                            ? Colors.orange
                            : value == 'Running'
                                ? Colors.green
                                : const Color(0xFF073850)
                        : const Color(0xFF073850),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF073850),
            ),
          ),
          Text(
            '₹$value',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF073850),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String label, {
    IconData? icon,
    VoidCallback? onTap,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF073850)),
      floatingLabelStyle: const TextStyle(color: Color(0xFF073850)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF073850), width: 2),
      ),
      suffixIcon: icon != null
          ? IconButton(
              icon: Icon(icon, color: const Color(0xFF073850)),
              onPressed: onTap,
            )
          : null,
      prefixText: prefixText,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF073850),
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAllowanceField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: _buildInputDecoration(
          label,
          prefixText: '₹ ',
          suffixText: label == 'Overtime Rate' ? '/hr' : '/month',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value != null &&
              value.isNotEmpty &&
              double.tryParse(value) == null) {
            return 'Please enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  void _clearForm() {
    _selectedEmployee = null;
    _selectedEmployeeId = null;
    _selectedDate = null;
    _selectedEndDate = null;
    _selectedSchedule = null;
    _selectedCategory = null;
    _selectedSalaryStructure = null;
    _dateController.clear();
    _endDateController.clear();
    _wageController.clear();
    _hraController.clear();
    _daController.clear();
    _travelAllowanceController.clear();
    _mealAllowanceController.clear();
    _medicalAllowanceController.clear();
    _overtimeRateController.clear();
    _otherAllowanceController.clear();
  }

  Future<void> _showAddContractScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Create New Contract'),
            backgroundColor: const Color.fromARGB(255, 7, 56, 80),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
                if (!mounted) return;
                setState(() {
                  _clearForm();
                });
              },
            ),
          ),
          backgroundColor: const Color(0xFFF1F6F9),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildFormField(
                              label: 'Employee Name',
                              child: DropdownButtonFormField<String>(
                                value: _selectedEmployee,
                                decoration:
                                    _buildInputDecoration('Select employee'),
                                items: _employees.map((employee) {
                                  return DropdownMenuItem<String>(
                                    value: employee.name,
                                    child: Text(
                                      employee.name,
                                      style: const TextStyle(
                                        color: Color(0xFF073850),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  final employee = _findEmployeeByName(value);
                                  setState(() {
                                    _selectedEmployee = value;
                                    _selectedEmployeeId = employee?.id;
                                  });

                                  if (value != null && employee == null) {
                                    errorSnackBar(
                                      'Error',
                                      'Selected employee could not be found.',
                                    );
                                  }
                                },
                                validator: (value) => value == null
                                    ? 'Please select an employee'
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Color(0xFF073850)),
                                style: const TextStyle(
                                  color: Color(0xFF073850),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildFormField(
                              label: 'Contract Start Date',
                              child: TextFormField(
                                controller: _dateController,
                                decoration: _buildInputDecoration(
                                  'Select start date',
                                  icon: Icons.calendar_today,
                                  onTap: () =>
                                      _showCalendarDialog(isStartDate: true),
                                ),
                                readOnly: true,
                                onTap: () =>
                                    _showCalendarDialog(isStartDate: true),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please select a start date'
                                        : null,
                              ),
                            ),
                            _buildFormField(
                              label: 'Contract End Date',
                              child: TextFormField(
                                controller: _endDateController,
                                decoration: _buildInputDecoration(
                                  'Select end date',
                                  icon: Icons.calendar_today,
                                  onTap: () =>
                                      _showCalendarDialog(isStartDate: false),
                                ),
                                readOnly: true,
                                onTap: () =>
                                    _showCalendarDialog(isStartDate: false),
                                validator: (value) => value == null ||
                                        value.isEmpty
                                    ? 'Please select an end date'
                                    : _selectedEndDate != null &&
                                            _selectedDate != null &&
                                            _selectedEndDate!
                                                .isBefore(_selectedDate!)
                                        ? 'End date must be after start date'
                                        : null,
                              ),
                            ),
                            _buildFormField(
                              label: 'Working Schedule',
                              child: DropdownButtonFormField<String>(
                                value: _selectedSchedule,
                                decoration:
                                    _buildInputDecoration('Select schedule'),
                                items: ['monthly', 'weekly', 'bi-weekly']
                                    .map((schedule) {
                                  return DropdownMenuItem<String>(
                                    value: schedule,
                                    child: Text(
                                      schedule,
                                      style: const TextStyle(
                                        color: Color(0xFF073850),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSchedule = value;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Please select a schedule'
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Color(0xFF073850)),
                                style: const TextStyle(
                                  color: Color(0xFF073850),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildFormField(
                              label: 'Employee Category',
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration:
                                    _buildInputDecoration('Select category'),
                                items: ['Permanent', 'Temporary', 'Intern']
                                    .map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: Color(0xFF073850),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Please select a category'
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Color(0xFF073850)),
                                style: const TextStyle(
                                  color: Color(0xFF073850),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildFormField(
                              label: 'Salary Structure',
                              child: DropdownButtonFormField<String>(
                                value: _selectedSalaryStructure,
                                decoration: _buildInputDecoration(
                                    'Select salary structure'),
                                items: _salaryStructures.map((structure) {
                                   return DropdownMenuItem<String>(
                                     value: structure.name,
                                     child: Text(
                                       structure.name,
                                       style: const TextStyle(
                                         color: Color(0xFF073850),
                                       ),
                                     ),
                                   );
                                 }).toList(),
                                onChanged: _salaryStructures.isEmpty
                                    ? null
                                    : (value) {
                                   setState(() {
                                     _selectedSalaryStructure = value;
                                   });
                                 },
                                validator: (value) => value == null
                                    ? _salaryStructures.isEmpty
                                        ? 'Salary structures are unavailable'
                                        : 'Please select a salary structure'
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Color(0xFF073850)),
                                style: const TextStyle(
                                  color: Color(0xFF073850),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            _buildFormField(
                              label: 'Wage',
                              child: TextFormField(
                                controller: _wageController,
                                decoration: _buildInputDecoration(
                                  'Enter wage amount',
                                  prefixText: '₹ ',
                                  suffixText: '/month',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a wage';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Allowances & Benefits',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: const Color(0xFF073850),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            _buildAllowanceField(
                              label: 'HRA',
                              controller: _hraController,
                            ),
                            _buildAllowanceField(
                              label: 'DA',
                              controller: _daController,
                            ),
                            _buildAllowanceField(
                              label: 'Travel Allowance',
                              controller: _travelAllowanceController,
                            ),
                            _buildAllowanceField(
                              label: 'Meal Allowance',
                              controller: _mealAllowanceController,
                            ),
                            _buildAllowanceField(
                              label: 'Medical Allowance',
                              controller: _medicalAllowanceController,
                            ),
                            _buildAllowanceField(
                              label: 'Overtime Rate',
                              controller: _overtimeRateController,
                            ),
                            _buildAllowanceField(
                              label: 'Other Allowance',
                              controller: _otherAllowanceController,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                      Navigator.pop(context);
                      if (!mounted) return;
                      setState(() {
                        _clearForm();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitContract,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Contract',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCalendarDialog({required bool isStartDate}) async {
    DateTime? tempSelectedDate = isStartDate ? _selectedDate : _selectedEndDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        firstDay: DateTime(2000, 1, 1),
                        lastDay: DateTime(2100, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(tempSelectedDate, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setDialogState(() {
                            tempSelectedDate = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF073850),
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: Color(0xFF073850),
                            size: 28,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: Color(0xFF073850),
                            size: 28,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        calendarStyle: const CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: Color.fromARGB(255, 7, 56, 80),
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          weekendTextStyle: TextStyle(
                            color: Colors.black87,
                          ),
                          outsideTextStyle: TextStyle(
                            color: Colors.grey,
                          ),
                          defaultTextStyle: TextStyle(
                            color: Color(0xFF073850),
                          ),
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            color: Color(0xFF073850),
                            fontWeight: FontWeight.w600,
                          ),
                          weekendStyle: TextStyle(
                            color: Color(0xFF073850),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (tempSelectedDate != null) {
                                if (!mounted) return;
                                setState(() {
                                  if (isStartDate) {
                                    _selectedDate = tempSelectedDate;
                                    _dateController.text =
                                        DateFormat('dd-MM-yyyy')
                                            .format(tempSelectedDate!);
                                  } else {
                                    _selectedEndDate = tempSelectedDate;
                                    _endDateController.text =
                                        DateFormat('dd-MM-yyyy')
                                            .format(tempSelectedDate!);
                                  }
                                });
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 7, 56, 80),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _endDateController.dispose();
    _wageController.dispose();
    _hraController.dispose();
    _daController.dispose();
    _travelAllowanceController.dispose();
    _mealAllowanceController.dispose();
    _medicalAllowanceController.dispose();
    _overtimeRateController.dispose();
    _otherAllowanceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContracts = _filteredContracts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Contracts'),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF1F6F9),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF073850),
                ),
              )
            : _contracts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 24),
                        Text(
                          'No Contracts Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF073850),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add a new contract to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchFilterBar(
                        controller: _searchController,
                        hintText: 'Search by employee name',
                        padding: const EdgeInsets.only(bottom: 16),
                        onChanged: () {
                          setState(() {});
                        },
                      ),
                      Text(
                        'Active Contracts (${filteredContracts.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF073850),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredContracts.isEmpty
                            ? const Center(
                                child: Text(
                                  'No contracts match this employee',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredContracts.length,
                                itemBuilder: (context, index) {
                                  final contract = filteredContracts[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _showContractDetails(contract),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    contract.name,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF073850),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: contract.state ==
                                                              'draft'
                                                          ? Colors.orange[50]
                                                          : Colors.green[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        16,
                                                      ),
                                                      border: Border.all(
                                                        color: contract.state ==
                                                                'draft'
                                                            ? Colors.orange
                                                            : Colors.green,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      contract.state == 'draft'
                                                          ? 'NEW'
                                                          : contract.state ==
                                                                  'open'
                                                              ? 'RUNNING'
                                                              : contract.state
                                                                  .toUpperCase(),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: contract.state ==
                                                                'draft'
                                                            ? Colors.orange[800]
                                                            : Colors.green[800],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              contract.employeeName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                _buildContractDate(
                                                  icon: Icons
                                                      .calendar_today_outlined,
                                                  label: 'Start',
                                                  date: contract.dateStart,
                                                ),
                                                const SizedBox(width: 24),
                                                _buildContractDate(
                                                  icon: Icons
                                                      .calendar_today_outlined,
                                                  label: 'End',
                                                  date: contract.dateEnd,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContractScreen,
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildContractDate({
    required IconData icon,
    required String label,
    required DateTime? date,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF073850),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              date != null
                  ? DateFormat('dd MMM yyyy').format(date)
                  : 'Not specified',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF073850),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
