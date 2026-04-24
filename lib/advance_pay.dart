import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '/services/employee_service.dart';
import '/models/employee.dart';
import '/services/advance_pay_service.dart';
import '/models/advance_pay_model.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'utils/app_layout.dart';
import 'widget/search_filter_bar.dart';

class AdvancePayPage extends StatefulWidget {
  const AdvancePayPage({super.key});

  @override
  State<AdvancePayPage> createState() => _AdvancePayPageState();
}

class _AdvancePayPageState extends State<AdvancePayPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Employee> _employees = [];
  Employee? _selectedEmployee;
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _showForm = false;
  bool _groupByEmployee = false;
  List<AdvancePayData> _advancePayRecords = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAdvancePayRecords();
  }

  Future<void> _loadAdvancePayRecords() async {
    setState(() => _isLoading = true);
    try {
      final service = AdvancePayService();
      final response =
          await service.getAdvancePayList(groupByEmployee: _groupByEmployee);

      if (response.status == 'success') {
        if (response.data is List) {
          if (_groupByEmployee) {
            final groupedData = (response.data as List)
                .map((item) => AdvancePayGroupedData.fromJson(item))
                .toList();
            setState(() {
              _advancePayRecords = groupedData
                  .expand((groupItem) =>
                      groupItem.records.map((record) => AdvancePayData(
                            id: record.id,
                            employeeId: groupItem.employeeId,
                            employeeName: groupItem.employeeName,
                            amount: record.amount,
                            date: record.date,
                            notes: null,
                          )))
                  .toList();
            });
          } else {
                      setState(() {
            _advancePayRecords = (response.data as List)
                .map((item) => AdvancePayData.fromJson(item))
                .toList();

            // 👉 ADD THIS LINE
            _advancePayRecords.sort((a, b) =>
                DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));
          });
          }
        } else {
          _showErrorSnackbar('Invalid response format: Expected a list');
        }
      } else {
        _showErrorSnackbar(response.message ?? 'Failed to load records');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final service = EmployeeService();
      final employees = await service.getEmployees();
      setState(() => _employees = employees);
    } catch (e) {
      _showErrorSnackbar('Error fetching employees: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green, // Selected date highlight
              onPrimary: Colors.white, // Text color on selected date
              onSurface: Colors.black, // Default text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.grey; // Disabled button color
                    }
                    // Detect if it's the "Cancel" button based on the context
                    final isCancel = states.contains(WidgetState.error);
                    return isCancel ? Colors.red : Colors.green;
                  },
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _submitAdvancePay() async {
    if (!_formKey.currentState!.validate() || _selectedEmployee == null) return;

    setState(() => _isSubmitting = true);
    try {
      final service = AdvancePayService();
      final response = await service.createAdvancePay(
        employeeId: _selectedEmployee!.id,
        amount: double.parse(_amountController.text),
        date: _dateController.text,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (response.status == 'success') {
        _showSuccessSnackbar('Advance pay created successfully');
        _resetForm();
        await _loadAdvancePayRecords();
        setState(() => _showForm = false);
      } else {
        _showErrorSnackbar(response.message ?? 'Failed to create advance pay');
      }
    } catch (e) {
      _showErrorSnackbar('Error: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _amountController.clear();
    _dateController.clear();
    _notesController.clear();
    setState(() => _selectedEmployee = null);
  }

  void _toggleForm() {
    setState(() {
      _showForm = !_showForm;
      if (_showForm && _employees.isEmpty) _fetchEmployees();
    });
  }

  void _toggleGroupByEmployee() {
    setState(() {
      _groupByEmployee = !_groupByEmployee;
      _loadAdvancePayRecords();
    });
  }

  void _showErrorSnackbar(String message) {
    errorSnackBar('Error', message);
  }

  void _showSuccessSnackbar(String message) {
    successSnackBar('Success', message);
  }

  String _formatDate(String dateStr) {
    try {
      DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advance Pay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF073850),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAdvancePayRecords,
          ),
          IconButton(
            icon: Icon(
              _groupByEmployee ? Icons.group : Icons.list,
              color: Colors.white,
            ),
            onPressed: _toggleGroupByEmployee,
            tooltip: _groupByEmployee ? 'Show ungrouped' : 'Show grouped',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advance Pay Records${_groupByEmployee ? ' (Grouped)' : ''}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SearchFilterBar(
                  controller: _searchController,
                  hintText: 'Search by employee name...',
                  onChanged: () {
                    setState(() {
                      _searchQuery = _searchController.text.toLowerCase();
                    });
                  },
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Builder(
                          builder: (context) {
                            final filtered = _searchQuery.isEmpty
                                ? _advancePayRecords
                                : _advancePayRecords
                                    .where((r) => r.employeeName
                                        .toLowerCase()
                                        .contains(_searchQuery))
                                    .toList();
                            if (filtered.isEmpty) {
                              return const Center(
                                  child: Text('No records found'));
                            }
                            return ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final record = filtered[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      record.employeeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Amount: ₹${record.amount.toStringAsFixed(2)}'),
                                        Text(
                                            'Date: ${_formatDate(record.date)}'),
                                        if (record.notes != null &&
                                            record.notes!.isNotEmpty)
                                          Text('Notes: ${record.notes}'),
                                      ],
                                    ),
                                    trailing: Text(
                                      'ID: ${record.id}',
                                      style: const TextStyle(
                                          color: Colors.grey),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_showForm) _buildForm(),
        ],
      ),
      floatingActionButton: _showForm
          ? null
          : FloatingActionButton(
              onPressed: _toggleForm,
              backgroundColor: const Color(0xFF073850),
              tooltip: 'Add advance pay',
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildForm() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Advance Pay',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _resetForm();
                        setState(() => _showForm = false);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownSearch<Employee>(
                  items: _employees
                    ..sort((a, b) =>
                        a.name.compareTo(b.name)), // sort alphabetically
                  itemAsString: (Employee e) => e.name,
                  selectedItem: _selectedEmployee,
                  onChanged: (value) =>
                      setState(() => _selectedEmployee = value),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: const TextFieldProps(
                      decoration: InputDecoration(
                        labelText: "Search employee",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    itemBuilder: (context, item, isSelected) {
                      int index = _employees.indexOf(item);
                      String firstLetter = item.name.isNotEmpty
                          ? item.name[0].toUpperCase()
                          : '';
                      bool showHeader = index == 0 ||
                          _employees[index - 1].name[0].toUpperCase() !=
                              firstLetter;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              color: Colors.grey.shade300,
                              child: Text(
                                firstLetter,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ListTile(
                            title: Text(item.name),
                            selected: isSelected,
                          ),
                        ],
                      );
                    },
                  ),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Employee',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  validator: (value) =>
                      value == null ? 'Please select an employee' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please select a date'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _isSubmitting ? null : _resetForm,
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF073850),
                      ),
                      onPressed: _isSubmitting ? null : _submitAdvancePay,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(255, 149, 58, 58)),

                              // AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
