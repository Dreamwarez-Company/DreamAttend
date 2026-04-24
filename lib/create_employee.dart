import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '/services/employee_service.dart';
import 'utils/app_layout.dart';

class CreateEmployeePage extends StatefulWidget {
  const CreateEmployeePage({super.key});

  @override
  State<CreateEmployeePage> createState() => _CreateEmployeePageState();
}

class _CreateEmployeePageState extends State<CreateEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _dobController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final EmployeeService _employeeService = EmployeeService();

  final Map<String, String> _roleTypeOptions = {
    'Manager': 'manager',
    'Employee': 'employee',
  };
  final Map<String, String> _genderOptions = {
    'Male': 'male',
    'Female': 'female',
  };

  String? _selectedRoleType;
  String? _selectedGender;
  XFile? _imageFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
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

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
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
            '${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    setState(() {
      _imageFile = pickedFile;
    });
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
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

      await _employeeService.createEmployee(employeeData);
      if (!mounted) return;
      successSnackBar('Success', 'Employee created successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      errorSnackBar('Error', 'Error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Employee'),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
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
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _employeeIdController,
                    decoration: const InputDecoration(
                      labelText: 'Employee ID',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _jobTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Job Title',
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth (DD-MM-YYYY)',
                    ),
                    onTap: () => _selectDate(context),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
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
                      if (!value.toLowerCase().endsWith('@dreamwarez.in')) {
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
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRoleType,
                    decoration: const InputDecoration(
                      labelText: 'Role Type',
                    ),
                    items: _roleTypeOptions.keys.map((role) {
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
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                    ),
                    items: _genderOptions.keys.map((gender) {
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
                    validator: (value) => value == null ? 'Required' : null,
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
                            minimumSize: const Size(double.infinity, 36.0),
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(fontSize: 16.0),
                          ),
                          child: Text(
                            _imageFile == null ? 'Select Image' : 'Image Selected',
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
                        onPressed: () => Navigator.pop(context),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all<Color>(Colors.red),
                          foregroundColor:
                              WidgetStateProperty.all<Color>(Colors.white),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _createEmployee,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 24, 128, 54),
                          foregroundColor: Colors.white,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
