import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '/models/employee.dart';
import '/services/employee_service.dart';
import 'widget/search_filter_bar.dart';
import 'utils/app_layout.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  XFile? _imageFile;

  String? _selectedRoleType;
  String? _selectedGender;
  final Map<String, String> _roleTypeOptions = {
    'Manager': 'manager',
    'Employee': 'employee',
  };
  final Map<String, String> _genderOptions = {
    'Male': 'male',
    'Female': 'female',
  };

  final EmployeeService _employeeService = EmployeeService();
  bool _showForm = false;
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = false;

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
    _nameController.dispose();
    _employeeIdController.dispose();
    _jobTitleController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final employees = await _employeeService.getEmployees();
      setState(() {
        _employees = employees;
        _filteredEmployees = employees;
      });
    } catch (e) {
      errorSnackBar('Error', 'Failed to load employees: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromARGB(255, 7, 56, 80),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text =
            "${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    String? imageBase64;
    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    final employeeData = {
      'name': _nameController.text,
      'employee_id': _employeeIdController.text.isEmpty
          ? null
          : _employeeIdController.text,
      'job_title': _jobTitleController.text,
      'dob': _dobController.text,
      'mobile': _mobileController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'role_type': _roleTypeOptions[_selectedRoleType!]!,
      'gender': _genderOptions[_selectedGender!]!,
      if (imageBase64 != null) 'image': imageBase64,
      'password': _passwordController.text,
    };

    try {
      await _employeeService.createEmployee(employeeData);

      successSnackBar('Success', 'Employee created successfully!');
      await _fetchEmployees();
      _formKey.currentState?.reset();
      setState(() {
        _nameController.clear();
        _employeeIdController.clear();
        _jobTitleController.clear();
        _dobController.clear();
        _mobileController.clear();
        _emailController.clear();
        _passwordController.clear();
        _addressController.clear();
        _selectedRoleType = null;
        _selectedGender = null;
        _imageFile = null;
        _showForm = false;
      });
    } catch (e) {
      errorSnackBar('Error', 'Error: $e');
    }
  }

  Future<void> _updateEmployee(Employee employee) async {
    if (!_formKey.currentState!.validate()) return;

    String? imageBase64;
    if (_imageFile != null) {
      final bytes = await _imageFile!.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    final employeeData = {
      'job_title': _jobTitleController.text,
      'mobile': _mobileController.text,
      'email': _emailController.text,
      'address': _addressController.text,
      'role_type': _roleTypeOptions[_selectedRoleType!]!,
      if (imageBase64 != null) 'image': imageBase64,
    };

    try {
      await _employeeService.updateEmployee(employee.id, employeeData);

      successSnackBar('Success', 'Employee updated successfully!');
      await _fetchEmployees();
      _formKey.currentState?.reset();
      setState(() {
        _imageFile = null;
        _nameController.clear();
        _employeeIdController.clear();
        _jobTitleController.clear();
        _dobController.clear();
        _mobileController.clear();
        _emailController.clear();
        _passwordController.clear();
        _addressController.clear();
        _selectedRoleType = null;
        _selectedGender = null;
        _showForm = false;
      });
    } catch (e) {
      errorSnackBar('Error', 'Error: $e');
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete ${employee.name}? This action cannot be undone.'),
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
        successSnackBar('Success', '${employee.name} deleted successfully!');
        await _fetchEmployees();
      } catch (e) {
        errorSnackBar('Error', 'Error: $e');
      }
    }
  }

  void _showEmployeeDetailsDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30.0,
                            ),
                            child: Text(
                              'Job Title:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(child: Text(employee.jobTitle)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30.0,
                            ),
                            child: Text(
                              'Email:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(child: Text(employee.email)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30.0,
                            ),
                            child: Text(
                              'Role :',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _roleTypeOptions.entries
                                .firstWhere(
                                  (entry) => entry.value == employee.roleType,
                                  orElse: () => const MapEntry('N/A', 'N/A'),
                                )
                                .key,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30.0,
                            ),
                            child: Text(
                              'DOB:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(child: Text(employee.dob)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30.0,
                            ),
                            child: Text(
                              'Mobile:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(child: Text(employee.mobile)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30.0,
                            ),
                            child: Text(
                              'Address:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(child: Text(employee.address)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 30.0,
                            ),
                            child: Text(
                              'Gender:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _genderOptions.entries
                                .firstWhere(
                                  (entry) => entry.value == employee.gender,
                                  orElse: () => const MapEntry('N/A', 'N/A'),
                                )
                                .key,
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
      },
    );
  }

  void _filterEmployees() {
    setState(() {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((employee) {
          return employee.name.toLowerCase().contains(query.toLowerCase()) ||
              employee.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
            onPressed: () {
              setState(() {
                _showForm = !_showForm;
                if (!_showForm) {
                  _nameController.clear();
                  _employeeIdController.clear();
                  _jobTitleController.clear();
                  _dobController.clear();
                  _mobileController.clear();
                  _emailController.clear();
                  _passwordController.clear();
                  _addressController.clear();
                  _selectedRoleType = null;
                  _selectedGender = null;
                  _imageFile = null;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_showForm) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _jobTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Job Title',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth (DD-MM-YYYY)',
                          ),
                          onTap: () => _selectDate(context),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Required';
                            }
                            if (value.length < 10) {
                              return 'Please enter exactly 10 digits';
                            }
                            if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                              return 'Please enter exactly 10 digits';
                            }
                            return null;
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) {
                            if (value!.isEmpty) return 'Required';
                            if (!value.toLowerCase().endsWith(
                                  '@dreamwarez.in',
                                )) {
                              return 'Email must end with @dreamwarez.in';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRoleType,
                          decoration: const InputDecoration(
                            labelText: 'Role Type',
                          ),
                          items: _roleTypeOptions.keys.map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleType = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                          ),
                          items: _genderOptions.keys.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12.0,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _pickImage,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(
                                    double.infinity,
                                    36.0,
                                  ),
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.black,
                                  textStyle: const TextStyle(fontSize: 16.0),
                                ),
                                child: Text(
                                  _imageFile == null
                                      ? 'Select Image'
                                      : 'Image Selected',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showForm = false;
                                  _nameController.clear();
                                  _employeeIdController.clear();
                                  _jobTitleController.clear();
                                  _dobController.clear();
                                  _mobileController.clear();
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _addressController.clear();
                                  _selectedRoleType = null;
                                  _selectedGender = null;
                                  _imageFile = null;
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                  Colors.red,
                                ),
                                foregroundColor: WidgetStateProperty.all<Color>(
                                  Colors.white,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _nameController.text.isNotEmpty &&
                                      _emailController.text.isNotEmpty
                                  ? _createEmployee
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  24,
                                  128,
                                  54,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (!_showForm) ...[
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
            ],
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
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Text(
                                                'Job Title:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                                child: Text(employee.jobTitle)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Text(
                                                'Mobile:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                                child: Text(employee.mobile)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Text(
                                                'Email:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                                child: Text(employee.email)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Text(
                                                'Role Type:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                _roleTypeOptions.entries
                                                    .firstWhere(
                                                      (entry) =>
                                                          entry.value ==
                                                          employee.roleType,
                                                      orElse: () =>
                                                          const MapEntry(
                                                              'N/A', 'N/A'),
                                                    )
                                                    .key,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Text(
                                                'Gender:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                _genderOptions.entries
                                                    .firstWhere(
                                                      (entry) =>
                                                          entry.value ==
                                                          employee.gender,
                                                      orElse: () =>
                                                          const MapEntry(
                                                              'N/A', 'N/A'),
                                                    )
                                                    .key,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
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
