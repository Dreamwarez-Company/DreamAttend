import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/models/employee.dart';
import '/models/task_request.dart';
import '/services/task_service.dart';
import 'utils/app_layout.dart';

class CreateTaskScreen extends StatefulWidget {
  final List<String> groups;
  final String currentUserName;
  final VoidCallback onTaskCreated;

  const CreateTaskScreen({
    super.key,
    required this.groups,
    required this.currentUserName,
    required this.onTaskCreated,
  });

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  DateTime? startDate;
  DateTime? deadline;
  final TextEditingController _employeeController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  List<Employee> _employees = [];
  String? _selectedEmployee;
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  @override
  void dispose() {
    _employeeController.dispose();
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final employees = await _taskService.fetchAssignableEmployees();
      if (!mounted) return;
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      _showNotification('Failed to load employees. Please try again.', isError: true);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) =>
          Theme(data: ThemeData.light(), child: child!),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      setState(() {
        if (isStartDate) {
          startDate = pickedDate;
        } else {
          deadline = pickedDate;
        }
      });
    }
  }

 Future<void> _submitTask() async {
  // 🔴 1. Trim inputs
  final taskName = _taskNameController.text.trim();
  final description = _descriptionController.text.trim();

  // 🔴 2. Required field validation
  if (_selectedEmployee == null) {
    _showNotification('Please select an employee.', isError: true);
    return;
  }

  if (taskName.isEmpty) {
    _showNotification('Task name is required.', isError: true);
    return;
  }

  if (deadline == null) {
    _showNotification('Please select a deadline.', isError: true);
    return;
  }

  // 🔴 3. Date validation
  if (startDate != null && deadline!.isBefore(startDate!)) {
    _showNotification('Deadline cannot be before start date.', isError: true);
    return;
  }

  // 🔴 4. Optional: description length check
  if (description.length > 200) {
    _showNotification('Description should be under 200 characters.', isError: true);
    return;
  }

  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    final selectedEmployee = _employees.firstWhere(
      (emp) => emp.id.toString() == _selectedEmployee,
      orElse: () => throw Exception('Employee not found'),
    );

    final task = TaskRequest(
      taskId: 0,
      employeeId: selectedEmployee.id.toString(),
      assignBy: widget.currentUserName,
      name: taskName, // ✅ trimmed
      startDate: startDate != null
          ? DateFormat('yyyy-MM-dd').format(startDate!)
          : null,
      endDate: null,
      deadline: DateFormat('yyyy-MM-dd').format(deadline!),
      description: description.isEmpty ? null : description, // ✅ clean
      state: 'pending',
      assignedToName: selectedEmployee.name,
      assignedByName: widget.currentUserName,
    );

    await _taskService.createTask(task);

    if (!mounted) return;

    _showNotification('Task created successfully.');

    _clearForm();
    widget.onTaskCreated();
    Navigator.pop(context);

  } catch (e) {
    if (!mounted) return;

    // 🔴 5. Clean generic error message
    _showNotification(
      'Failed to create task. Please try again.',
      isError: true,
    );
  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      errorSnackBar('Error', message);
      return;
    }
    successSnackBar('Success', message);
  }

  void _clearForm() {
    _taskNameController.clear();
    _descriptionController.clear();
    setState(() {
      startDate = null;
      deadline = null;
      _selectedEmployee = null;
    });
  }

  Widget _buildEmployeeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assigned To',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF073850))),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: _isLoading || _employees.isEmpty,
          child: DropdownButtonFormField<String>(
            value: _selectedEmployee,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Select employee',
              filled: true,
              fillColor: Colors.white,
            ),
            items: _employees
                .map((e) => DropdownMenuItem(
                    value: e.id.toString(), child: Text(e.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedEmployee = v),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool multiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF073850))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: multiline ? 3 : 1,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter ${label.toLowerCase()}',
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? date, bool isStartDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF073850))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isStartDate),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date != null
                    ? DateFormat('dd-MM-yyyy').format(date)
                    : 'Select Date'),
                const Icon(Icons.calendar_today, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create New Task',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF073850),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildEmployeeDropdown(),
            const SizedBox(height: 20),
            _buildTextField('Task Name', _taskNameController),
            const SizedBox(height: 20),
            _buildDateField('Start Date', startDate, true),
            const SizedBox(height: 20),
            _buildDateField('Deadline', deadline, false),
            const SizedBox(height: 20),
            _buildTextField('Description', _descriptionController,
                multiline: true),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _clearForm();
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF073850),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Create Task',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
