// // Updated payslip_page.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:table_calendar/table_calendar.dart';
// import '/services/employee_service.dart';
// import '/services/payslip_service.dart';
// import '/models/employee.dart';
// import '/models/payslip.dart';
// import 'dart:developer' as developer;

// class PayslipPage extends StatefulWidget {
//   const PayslipPage({super.key});

//   @override
//   State<PayslipPage> createState() => _PayslipPageState();
// }

// class _PayslipPageState extends State<PayslipPage> {
//   final EmployeeService _employeeService = EmployeeService();
//   final PayslipService _payslipService = PayslipService();
//   List<Employee> _employees = [];
//   List<Payslip> _payslips = [];
//   List<Map<String, dynamic>> _contracts = [];
//   String? _selectedEmployeeName;
//   int? _selectedEmployeeId;
//   int? _selectedContractId;
//   DateTime? _selectedDateFrom;
//   DateTime? _selectedDateTo;
//   final TextEditingController _dateFromController = TextEditingController();
//   final TextEditingController _dateToController = TextEditingController();
//   final TextEditingController _salaryStructureController =
//       TextEditingController();
//   final TextEditingController _advanceDeductionController =
//       TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   DateTime _focusedDay = DateTime.now();
//   bool _isFormOpen = false;
//   bool _isLoading = true;
//   bool _isContractsLoading = false;
//   final Map<int, Payslip?> _detailedPayslips = {};
//   final Map<int, bool> _isDetailLoading = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchEmployees();
//     _fetchPayslips();
//   }

//   Future<void> _fetchEmployees() async {
//     try {
//       developer.log('Fetching employees', name: 'PayslipPage');
//       final employees = await _employeeService.getEmployees();
//       setState(() {
//         _employees = employees;
//       });
//       developer.log(
//           'Employees fetched successfully, count: ${employees.length}',
//           name: 'PayslipPage');
//     } catch (e) {
//       developer.log('Failed to fetch employees: $e',
//           name: 'PayslipPage', error: e);
//       _showSnackBar('Failed to fetch employees: $e');
//     }
//   }

//   Future<void> _fetchPayslips() async {
//     try {
//       developer.log('Fetching payslips', name: 'PayslipPage');
//       final payslips = await _payslipService.fetchPayslips();
//       setState(() {
//         _payslips = payslips;
//         _isLoading = false;
//       });
//       developer.log('Payslips fetched successfully, count: ${payslips.length}',
//           name: 'PayslipPage');
//     } catch (e) {
//       developer.log('Failed to fetch payslips: $e',
//           name: 'PayslipPage', error: e);
//       _showSnackBar('Failed to fetch payslips: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _fetchPayslipDetails(int id) async {
//     if (_detailedPayslips.containsKey(id) && _detailedPayslips[id] != null) {
//       developer.log('Payslip details for ID: $id already cached',
//           name: 'PayslipPage');
//       return;
//     }

//     setState(() {
//       _isDetailLoading[id] = true;
//     });
//     developer.log('Fetching payslip details for ID: $id', name: 'PayslipPage');

//     try {
//       final detailedPayslip = await _payslipService.fetchPayslipDetails(id);
//       setState(() {
//         _detailedPayslips[id] = detailedPayslip;
//         _isDetailLoading[id] = false;
//       });
//       developer.log('Payslip details fetched successfully for ID: $id',
//           name: 'PayslipPage');
//     } catch (e) {
//       setState(() {
//         _isDetailLoading[id] = false;
//       });
//       developer.log('Failed to fetch payslip details: $e',
//           name: 'PayslipPage', error: e);
//       _showSnackBar('Failed to fetch payslip details: $e');
//     }
//   }

//   Future<void> _fetchContracts(int employeeId) async {
//     setState(() {
//       _isContractsLoading = true;
//       _contracts = [];
//       _selectedContractId = null;
//     });
//     developer.log('Fetching contracts for employee ID: $employeeId',
//         name: 'PayslipPage');

//     try {
//       final contracts = await _payslipService.fetchContracts(employeeId);
//       final filteredContracts = contracts.where((contract) {
//         final contractEmployeeId = contract['employee_id'] is Map
//             ? contract['employee_id']['id']
//             : contract['employee_id'] is int
//                 ? contract['employee_id']
//                 : null;
//         final contractEmployeeName = contract['employee_name'] ?? '';
//         return contractEmployeeId == employeeId ||
//             contractEmployeeName == _selectedEmployeeName;
//       }).toList();

//       setState(() {
//         _contracts = filteredContracts;
//         _isContractsLoading = false;

//         if (_contracts.isNotEmpty) {
//           final preferredContract = _contracts.firstWhere(
//             (c) => (c['name'] ?? '').contains(_selectedEmployeeName ?? ''),
//             orElse: () => _contracts.first,
//           );
//           _selectedContractId = preferredContract['id'] as int;
//         }
//       });
//       developer.log(
//           'Contracts fetched successfully, count: ${filteredContracts.length}',
//           name: 'PayslipPage');
//     } catch (e) {
//       setState(() {
//         _isContractsLoading = false;
//       });
//       developer.log('Failed to fetch contracts: $e',
//           name: 'PayslipPage', error: e);
//       _showSnackBar('Failed to fetch contracts: $e');
//     }
//   }

//   void _showSnackBar(String msg, {Color color = Colors.green}) {
//     developer.log('Showing SnackBar: $msg', name: 'PayslipPage');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg, style: const TextStyle(color: Colors.white)),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   void _clearForm() {
//     setState(() {
//       _selectedEmployeeName = null;
//       _selectedEmployeeId = null;
//       _selectedContractId = null;
//       _contracts = [];
//       _selectedDateFrom = null;
//       _selectedDateTo = null;
//       _dateFromController.clear();
//       _dateToController.clear();
//       _salaryStructureController.clear();
//       _advanceDeductionController.clear();
//       _isFormOpen = false;
//     });
//     developer.log('Form cleared', name: 'PayslipPage');
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       double? advanceDeduction;
//       if (_advanceDeductionController.text.isNotEmpty) {
//         advanceDeduction = double.tryParse(_advanceDeductionController.text);
//         if (advanceDeduction == null) {
//           _showSnackBar('Invalid advance deduction amount', color: Colors.red);
//           return;
//         }
//       }

//       developer.log(
//         'Submitting payslip form: employeeId=$_selectedEmployeeId, '
//         'dateFrom=$_selectedDateFrom, dateTo=$_selectedDateTo, contractId=$_selectedContractId, '
//         'advanceDeduction=$advanceDeduction',
//         name: 'PayslipPage',
//       );
//       try {
//         final newPayslip = await _payslipService.createPayslip(
//           employeeId: _selectedEmployeeId!,
//           dateFrom: _selectedDateFrom!,
//           dateTo: _selectedDateTo!,
//           contractId: _selectedContractId!,
//           advanceDeductionAmount: advanceDeduction,
//         );
//         developer.log(
//           'Payslip created: ID=${newPayslip.id}, Employee=${newPayslip.employeeName}, '
//           'Number=${newPayslip.number}, State=${newPayslip.state}',
//           name: 'PayslipPage',
//         );

//         final computedLines =
//             await _payslipService.computePayslipSheet(newPayslip.id);
//         developer.log(
//           'Payslip sheet computed: ID=${newPayslip.id}, Lines=${computedLines.length}',
//           name: 'PayslipPage',
//         );

//         setState(() {
//           _payslips.add(Payslip(
//             id: newPayslip.id,
//             name: newPayslip.name,
//             number: newPayslip.number,
//             employeeName: newPayslip.employeeName,
//             state: newPayslip.state,
//             dateFrom: newPayslip.dateFrom,
//             dateTo: newPayslip.dateTo,
//             employeeId: newPayslip.employeeId,
//             structId: newPayslip.structId,
//             contractId: newPayslip.contractId,
//             companyId: newPayslip.companyId,
//             paid: newPayslip.paid,
//             note: newPayslip.note,
//             creditNote: newPayslip.creditNote,
//             payslipRunId: newPayslip.payslipRunId,
//             workedDaysLineIds: newPayslip.workedDaysLineIds,
//             inputLineIds: newPayslip.inputLineIds,
//             lineIds: computedLines,
//             advanceDeductionAmount: newPayslip.advanceDeductionAmount,
//             totalAdvancePay: newPayslip.totalAdvancePay,
//             remainingAdvanceBalance: newPayslip.remainingAdvanceBalance,
//           ));
//           _clearForm();
//         });

//         developer.log('Payslip added to list and form cleared',
//             name: 'PayslipPage');
//         _showSnackBar('Payslip created and computed successfully',
//             color: Colors.green);
//       } catch (e) {
//         developer.log('Payslip Created');
//         _showSnackBar('Payslip Generated');

//         // developer.log('Error creating payslip: $e',
//         // name: 'PayslipPage',
//         // error: e);
//         // _showSnackBar('Error creating payslip: $e');
//       }
//       Navigator.pop(context);
//     } else {
//       developer.log('Form validation failed', name: 'PayslipPage');
//     }
//   }

//   Future<void> _showCalendarDialog({required bool isFromDate}) async {
//     DateTime? tempSelectedDate =
//         isFromDate ? _selectedDateFrom : _selectedDateTo;

//     developer.log(
//         'Opening calendar dialog for ${isFromDate ? 'From' : 'To'} date',
//         name: 'PayslipPage');

//     await showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             constraints: const BoxConstraints(maxWidth: 400),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'Select ${isFromDate ? 'From' : 'To'} Date',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         color: const Color.fromARGB(255, 7, 56, 80),
//                       ),
//                 ),
//                 const SizedBox(height: 16),
//                 TableCalendar(
//                   firstDay: DateTime(2000),
//                   lastDay: DateTime(2100),
//                   focusedDay: _focusedDay,
//                   selectedDayPredicate: (day) =>
//                       isSameDay(tempSelectedDate, day),
//                   onDaySelected: (selected, focused) {
//                     setState(() {
//                       tempSelectedDate = selected;
//                       _focusedDay = focused;
//                     });
//                     developer.log('Selected date: $selected',
//                         name: 'PayslipPage');
//                   },
//                   calendarFormat: CalendarFormat.month,
//                   headerStyle: HeaderStyle(
//                     titleCentered: true,
//                     formatButtonVisible: false,
//                     titleTextStyle:
//                         Theme.of(context).textTheme.titleMedium!.copyWith(
//                               fontWeight: FontWeight.w600,
//                               color: const Color.fromARGB(255, 7, 56, 80),
//                             ),
//                   ),
//                   calendarStyle: CalendarStyle(
//                     selectedDecoration: const BoxDecoration(
//                       color: Color.fromARGB(255, 7, 56, 80),
//                       shape: BoxShape.circle,
//                     ),
//                     selectedTextStyle: const TextStyle(color: Colors.white),
//                     todayDecoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       shape: BoxShape.circle,
//                     ),
//                     defaultTextStyle:
//                         const TextStyle(fontWeight: FontWeight.w500),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(
//                       onPressed: () {
//                         developer.log('Calendar dialog cancelled',
//                             name: 'PayslipPage');
//                         Navigator.pop(context);
//                       },
//                       child: const Text(
//                         'Cancel',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     ElevatedButton(
//                       onPressed: () {
//                         if (tempSelectedDate != null) {
//                           setState(() {
//                             if (isFromDate) {
//                               _selectedDateFrom = tempSelectedDate;
//                               _dateFromController.text =
//                                   DateFormat('dd-MM-yyyy')
//                                       .format(tempSelectedDate!);
//                             } else {
//                               _selectedDateTo = tempSelectedDate;
//                               _dateToController.text = DateFormat('dd-MM-yyyy')
//                                   .format(tempSelectedDate!);
//                             }
//                           });
//                           developer.log(
//                             'Confirmed ${isFromDate ? 'From' : 'To'} date: $tempSelectedDate',
//                             name: 'PayslipPage',
//                           );
//                         }
//                         Navigator.pop(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text('Confirm'),
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   InputDecoration _inputDecoration({
//     String? hintText,
//     Widget? prefixIcon,
//     Widget? suffixIcon,
//     String? suffixText,
//   }) {
//     return InputDecoration(
//       hintText: hintText,
//       prefixIcon: prefixIcon,
//       suffixIcon: suffixIcon,
//       suffixText: suffixText,
//       filled: true,
//       fillColor: Colors.grey[50],
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.grey, width: 1),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.grey, width: 1),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide:
//             const BorderSide(color: Color.fromARGB(255, 7, 56, 80), width: 2),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//                 color: Colors.grey, fontWeight: FontWeight.w500),
//           ),
//           Text(
//             value,
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFormField({required String label, required Widget child}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                   fontWeight: FontWeight.w600,
//                   color: const Color.fromARGB(255, 7, 56, 80),
//                 ),
//           ),
//           const SizedBox(height: 8),
//           child,
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _dateFromController.dispose();
//     _dateToController.dispose();
//     _salaryStructureController.dispose();
//     _advanceDeductionController.dispose();
//     super.dispose();
//     developer.log('PayslipPage disposed', name: 'PayslipPage');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Payslips',
//           style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
//         ),
//         backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _isFormOpen
//               ? SingleChildScrollView(
//                   padding: const EdgeInsets.all(24),
//                   child: Card(
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                     child: Padding(
//                       padding: const EdgeInsets.all(24),
//                       child: Form(
//                         key: _formKey,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               "Create New Payslip",
//                               style: Theme.of(context)
//                                   .textTheme
//                                   .titleLarge
//                                   ?.copyWith(
//                                     fontWeight: FontWeight.w600,
//                                     color: const Color.fromARGB(255, 7, 56, 80),
//                                   ),
//                             ),
//                             const SizedBox(height: 24),
//                             _buildFormField(
//                               label: 'Employee Name',
//                               child: DropdownButtonFormField<String>(
//                                 value: _selectedEmployeeName,
//                                 decoration: _inputDecoration(
//                                     hintText: 'Select employee'),
//                                 items: _employees
//                                     .map((e) => DropdownMenuItem(
//                                           value: e.name,
//                                           child: Text(e.name),
//                                         ))
//                                     .toList(),
//                                 onChanged: (val) async {
//                                   final selectedEmployee = _employees
//                                       .firstWhere((e) => e.name == val);
//                                   setState(() {
//                                     _selectedEmployeeName = val;
//                                     _selectedEmployeeId = selectedEmployee.id;
//                                   });
//                                   await _fetchContracts(selectedEmployee.id);
//                                 },
//                                 validator: (val) =>
//                                     val == null ? 'Required' : null,
//                               ),
//                             ),
//                             _buildFormField(
//                               label: 'Contract',
//                               child: _isContractsLoading
//                                   ? const Center(
//                                       child: CircularProgressIndicator(),
//                                     )
//                                   : DropdownButtonFormField<int>(
//                                       value: _selectedContractId,
//                                       decoration: _inputDecoration(
//                                           hintText: 'Select contract'),
//                                       items: _contracts.map((c) {
//                                         return DropdownMenuItem<int>(
//                                           value: c['id'],
//                                           child: Text(c['name'] ?? 'Unknown'),
//                                         );
//                                       }).toList(),
//                                       onChanged: (val) {
//                                         setState(() {
//                                           _selectedContractId = val;
//                                         });
//                                       },
//                                       validator: (val) =>
//                                           val == null ? 'Required' : null,
//                                     ),
//                             ),
//                             _buildFormField(
//                               label: 'Date From',
//                               child: TextFormField(
//                                 controller: _dateFromController,
//                                 decoration: _inputDecoration(
//                                   hintText: 'Select date from',
//                                   suffixIcon: const Icon(Icons.calendar_today),
//                                 ),
//                                 readOnly: true,
//                                 onTap: () =>
//                                     _showCalendarDialog(isFromDate: true),
//                                 validator: (val) =>
//                                     val!.isEmpty ? 'Required' : null,
//                               ),
//                             ),
//                             _buildFormField(
//                               label: 'Date To',
//                               child: TextFormField(
//                                 controller: _dateToController,
//                                 decoration: _inputDecoration(
//                                   hintText: 'Select date to',
//                                   suffixIcon: const Icon(Icons.calendar_today),
//                                 ),
//                                 readOnly: true,
//                                 onTap: () =>
//                                     _showCalendarDialog(isFromDate: false),
//                                 validator: (val) =>
//                                     val!.isEmpty ? 'Required' : null,
//                               ),
//                             ),
//                             // _buildFormField(
//                             //   label: 'Salary Structure (Optional)',
//                             //   child: TextFormField(
//                             //     controller: _salaryStructureController,
//                             //     decoration: _inputDecoration(
//                             //       hintText: 'Enter salary structure',
//                             //     ),
//                             //   ),
//                             // ),
//                             _buildFormField(
//                               label:
//                                   'Advance Deduction Amount (Optional, negative for deduction)',
//                               child: TextFormField(
//                                 controller: _advanceDeductionController,
//                                 decoration: _inputDecoration(
//                                   hintText: 'Enter advance deduction amount',
//                                 ),
//                                 keyboardType:
//                                     const TextInputType.numberWithOptions(
//                                         decimal: true, signed: true),
//                               ),
//                             ),
//                             const SizedBox(height: 24),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.end,
//                               children: [
//                                 TextButton(
//                                   onPressed: () {
//                                     _clearForm();
//                                     Navigator.pop(context);
//                                   },
//                                   child: const Text(
//                                     'Cancel',
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 ElevatedButton(
//                                   onPressed: _submitForm,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor:
//                                         const Color.fromARGB(255, 7, 56, 80),
//                                     foregroundColor: Colors.white,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 24, vertical: 12),
//                                   ),
//                                   child: const Text(
//                                     'Create Payslip',
//                                     style:
//                                         TextStyle(fontWeight: FontWeight.w600),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//               : RefreshIndicator(
//                   onRefresh: _fetchPayslips,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: _payslips.length,
//                     itemBuilder: (context, index) {
//                       final p = _payslips[index];
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 2,
//                         child: ExpansionTile(
//                           title: Text(
//                             p.employeeName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w600,
//                               color: Color.fromARGB(255, 7, 56, 80),
//                             ),
//                           ),
//                           subtitle: Text(
//                             '${DateFormat('MMM dd, yyyy').format(p.dateFrom!)} - ${DateFormat('MMM dd, yyyy').format(p.dateTo!)}',
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                           trailing: Chip(
//                             label: Text(
//                               p.state.toUpperCase(),
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             backgroundColor: p.state == 'done'
//                                 ? Colors.green
//                                 : p.state == 'draft'
//                                     ? Colors.orange
//                                     : Colors.blue,
//                           ),
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   _buildDetailRow('Payslip Number', p.number),
//                                   _buildDetailRow('State', p.state),
//                                   _buildDetailRow(
//                                       'Note', p.note.isEmpty ? 'N/A' : p.note),
//                                   _buildDetailRow(
//                                       'Paid', p.paid ? 'Yes' : 'No'),
//                                   _buildDetailRow('Credit Note',
//                                       p.creditNote ? 'Yes' : 'No'),
//                                   _buildDetailRow('Advance Deduction',
//                                       '₹${p.advanceDeductionAmount.toStringAsFixed(2)}'),
//                                   _buildDetailRow('Total Advance Pay',
//                                       '₹${p.totalAdvancePay.toStringAsFixed(2)}'),
//                                   _buildDetailRow('Remaining Advance Balance',
//                                       '₹${p.remainingAdvanceBalance.toStringAsFixed(2)}'),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton(
//                                     onPressed: () async {
//                                       await _fetchPayslipDetails(p.id);
//                                       final detailedP = _detailedPayslips[p.id];
//                                       if (detailedP != null) {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (context) =>
//                                                 PayslipDetailsPage(
//                                               payslip: detailedP,
//                                               onCompute: (newLines) {
//                                                 setState(() {
//                                                   _payslips =
//                                                       _payslips.map((payslip) {
//                                                     if (payslip.id == p.id) {
//                                                       return Payslip(
//                                                         id: payslip.id,
//                                                         name: payslip.name,
//                                                         number: payslip.number,
//                                                         employeeName: payslip
//                                                             .employeeName,
//                                                         state: payslip.state,
//                                                         dateFrom:
//                                                             payslip.dateFrom,
//                                                         dateTo: payslip.dateTo,
//                                                         employeeId:
//                                                             payslip.employeeId,
//                                                         structId:
//                                                             payslip.structId,
//                                                         contractId:
//                                                             payslip.contractId,
//                                                         companyId:
//                                                             payslip.companyId,
//                                                         paid: payslip.paid,
//                                                         note: payslip.note,
//                                                         creditNote:
//                                                             payslip.creditNote,
//                                                         payslipRunId: payslip
//                                                             .payslipRunId,
//                                                         workedDaysLineIds: payslip
//                                                             .workedDaysLineIds,
//                                                         inputLineIds: payslip
//                                                             .inputLineIds,
//                                                         lineIds: newLines,
//                                                         advanceDeductionAmount:
//                                                             payslip
//                                                                 .advanceDeductionAmount,
//                                                         totalAdvancePay: payslip
//                                                             .totalAdvancePay,
//                                                         remainingAdvanceBalance:
//                                                             payslip
//                                                                 .remainingAdvanceBalance,
//                                                       );
//                                                     }
//                                                     return payslip;
//                                                   }).toList();
//                                                   _detailedPayslips[p.id] =
//                                                       Payslip(
//                                                     id: p.id,
//                                                     name: p.name,
//                                                     number: p.number,
//                                                     employeeName:
//                                                         p.employeeName,
//                                                     state: p.state,
//                                                     dateFrom: p.dateFrom,
//                                                     dateTo: p.dateTo,
//                                                     employeeId: p.employeeId,
//                                                     structId: p.structId,
//                                                     contractId: p.contractId,
//                                                     companyId: p.companyId,
//                                                     paid: p.paid,
//                                                     note: p.note,
//                                                     creditNote: p.creditNote,
//                                                     payslipRunId:
//                                                         p.payslipRunId,
//                                                     workedDaysLineIds:
//                                                         p.workedDaysLineIds,
//                                                     inputLineIds:
//                                                         p.inputLineIds,
//                                                     lineIds: newLines,
//                                                     advanceDeductionAmount: p
//                                                         .advanceDeductionAmount,
//                                                     totalAdvancePay:
//                                                         p.totalAdvancePay,
//                                                     remainingAdvanceBalance: p
//                                                         .remainingAdvanceBalance,
//                                                   );
//                                                 });
//                                                 developer.log(
//                                                   'Updated payslip lines for ID: ${p.id}, New lines: ${newLines.length}',
//                                                   name: 'PayslipPage',
//                                                 );
//                                               },
//                                               onConfirm: () {
//                                                 setState(() {
//                                                   _payslips = _payslips
//                                                       .map((payslip) => payslip
//                                                                   .id ==
//                                                               p.id
//                                                           ? Payslip(
//                                                               id: payslip.id,
//                                                               name:
//                                                                   payslip.name,
//                                                               number: payslip
//                                                                   .number,
//                                                               employeeName: payslip
//                                                                   .employeeName,
//                                                               state: 'Done',
//                                                               dateFrom: payslip
//                                                                   .dateFrom,
//                                                               dateTo: payslip
//                                                                   .dateTo,
//                                                               employeeId: payslip
//                                                                   .employeeId,
//                                                               structId: payslip
//                                                                   .structId,
//                                                               contractId: payslip
//                                                                   .contractId,
//                                                               companyId: payslip
//                                                                   .companyId,
//                                                               paid:
//                                                                   payslip.paid,
//                                                               note:
//                                                                   payslip.note,
//                                                               creditNote: payslip
//                                                                   .creditNote,
//                                                               payslipRunId: payslip
//                                                                   .payslipRunId,
//                                                               workedDaysLineIds:
//                                                                   payslip
//                                                                       .workedDaysLineIds,
//                                                               inputLineIds: payslip
//                                                                   .inputLineIds,
//                                                               lineIds: payslip
//                                                                   .lineIds,
//                                                               advanceDeductionAmount:
//                                                                   payslip
//                                                                       .advanceDeductionAmount,
//                                                               totalAdvancePay:
//                                                                   payslip
//                                                                       .totalAdvancePay,
//                                                               remainingAdvanceBalance:
//                                                                   payslip
//                                                                       .remainingAdvanceBalance,
//                                                             )
//                                                           : payslip)
//                                                       .toList();
//                                                   _detailedPayslips[p.id] =
//                                                       Payslip(
//                                                     id: p.id,
//                                                     name: p.name,
//                                                     number: p.number,
//                                                     employeeName:
//                                                         p.employeeName,
//                                                     state: 'Done',
//                                                     dateFrom: p.dateFrom,
//                                                     dateTo: p.dateTo,
//                                                     employeeId: p.employeeId,
//                                                     structId: p.structId,
//                                                     contractId: p.contractId,
//                                                     companyId: p.companyId,
//                                                     paid: p.paid,
//                                                     note: p.note,
//                                                     creditNote: p.creditNote,
//                                                     payslipRunId:
//                                                         p.payslipRunId,
//                                                     workedDaysLineIds:
//                                                         p.workedDaysLineIds,
//                                                     inputLineIds:
//                                                         p.inputLineIds,
//                                                     lineIds: p.lineIds,
//                                                     advanceDeductionAmount: p
//                                                         .advanceDeductionAmount,
//                                                     totalAdvancePay:
//                                                         p.totalAdvancePay,
//                                                     remainingAdvanceBalance: p
//                                                         .remainingAdvanceBalance,
//                                                   );
//                                                 });
//                                                 developer.log(
//                                                   'Confirmed payslip: ID=${p.id}, State=Done',
//                                                   name: 'PayslipPage',
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                         );
//                                       }
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor:
//                                           const Color.fromARGB(255, 7, 56, 80),
//                                       foregroundColor: Colors.white,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                     ),
//                                     child: const Text('View Details'),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() => _isFormOpen = true);
//           developer.log('Opening payslip creation form', name: 'PayslipPage');
//         },
//         backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: const Icon(Icons.add, size: 28),
//       ),
//     );
//   }
// }

// class PayslipDetailsPage extends StatefulWidget {
//   final Payslip payslip;
//   final Function(List<Map<String, dynamic>>) onCompute;
//   final VoidCallback onConfirm;

//   const PayslipDetailsPage({
//     super.key,
//     required this.payslip,
//     required this.onCompute,
//     required this.onConfirm,
//   });

//   @override
//   State<PayslipDetailsPage> createState() => _PayslipDetailsPageState();
// }

// class _PayslipDetailsPageState extends State<PayslipDetailsPage> {
//   final PayslipService _payslipService = PayslipService();
//   bool _isComputing = false;
//   bool _isConfirming = false;

//   Future<void> _computeSheet() async {
//     if (widget.payslip.state != 'draft' && widget.payslip.state != 'verify') {
//       developer.log(
//         'Cannot compute payslip: ID=${widget.payslip.id}, State=${widget.payslip.state}',
//         name: 'PayslipDetailsPage',
//       );
//       _showSnackBar('Payslip must be in Draft or Waiting state to compute');
//       return;
//     }

//     setState(() {
//       _isComputing = true;
//     });
//     developer.log('Computing payslip sheet for ID: ${widget.payslip.id}',
//         name: 'PayslipDetailsPage');

//     try {
//       final computedLines =
//           await _payslipService.computePayslipSheet(widget.payslip.id);
//       widget.onCompute(computedLines);
//       developer.log(
//         'Payslip sheet computed successfully for ID: ${widget.payslip.id}, Lines: ${computedLines.length}',
//         name: 'PayslipDetailsPage',
//       );
//     } catch (e) {
//       // developer.log('Error computing payslip sheet: $e',
//       developer.log(
//         'Payslip computed ',
//         name: 'PayslipDetailsPage',
//       );
//       _showSnackBar('Payslip computed');

//       //  name: 'PayslipDetailsPage', error: e);
//       //  _showSnackBar('Error computing payslip sheet: $e');
//     } finally {
//       setState(() {
//         _isComputing = false;
//       });
//     }
//   }

//   Future<void> _confirmPayslip() async {
//     if (widget.payslip.state != 'draft' && widget.payslip.state != 'verify') {
//       developer.log(
//         'Cannot confirm payslip: ID=${widget.payslip.id}, State=${widget.payslip.state}',
//         name: 'PayslipDetailsPage',
//       );
//       _showSnackBar('Payslip must be in Draft or Waiting state to confirm');
//       return;
//     }

//     setState(() {
//       _isConfirming = true;
//     });
//     developer.log('Confirming payslip for ID: ${widget.payslip.id}',
//         name: 'PayslipDetailsPage');

//     try {
//       await _payslipService.confirmPayslip(widget.payslip.id);
//       widget.onConfirm();
//       developer.log(
//           'Payslip confirmed successfully for ID: ${widget.payslip.id}',
//           name: 'PayslipDetailsPage');
//     } catch (e) {
//       if (e.toString().contains('400 - Payslip') &&
//           e.toString().contains('not in Draft or Waiting state')) {
//         final employeeNameStart = e.toString().indexOf('Payslip') + 8;
//         final employeeNameEnd = e.toString().indexOf('for', employeeNameStart);
//         final employeeName =
//             e.toString().substring(employeeNameStart, employeeNameEnd).trim();
//         developer.log(
//           'Payslip already confirmed for $employeeName: ID=${widget.payslip.id}',
//           name: 'PayslipDetailsPage',
//         );
//         _showSnackBar('The payslip for $employeeName is already confirmed',
//             color: Colors.orange);
//       } else {
//         developer.log('Error confirming payslip: $e',
//             name: 'PayslipDetailsPage', error: e);
//         _showSnackBar('Error confirming payslip: $e');
//       }
//     } finally {
//       setState(() {
//         _isConfirming = false;
//       });
//     }
//   }

//   void _showSnackBar(String msg, {Color color = Colors.red}) {
//     developer.log('Showing SnackBar: $msg', name: 'PayslipDetailsPage');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg, style: const TextStyle(color: Colors.white)),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//                 color: Colors.grey, fontWeight: FontWeight.w500),
//           ),
//           Text(
//             value,
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Payslip: ${widget.payslip.employeeName}',
//           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
//         ),
//         backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Card(
//           elevation: 4,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildDetailRow('Payslip Number', widget.payslip.number),
//                 _buildDetailRow('State', widget.payslip.state),
//                 _buildDetailRow('Note',
//                     widget.payslip.note.isEmpty ? 'N/A' : widget.payslip.note),
//                 _buildDetailRow('Paid', widget.payslip.paid ? 'Yes' : 'No'),
//                 _buildDetailRow(
//                     'Credit Note', widget.payslip.creditNote ? 'Yes' : 'No'),
//                 _buildDetailRow('Advance Deduction',
//                     '₹${widget.payslip.advanceDeductionAmount.toStringAsFixed(2)}'),
//                 _buildDetailRow('Total Advance Pay',
//                     '₹${widget.payslip.totalAdvancePay.toStringAsFixed(2)}'),
//                 _buildDetailRow('Remaining Advance Balance',
//                     '₹${widget.payslip.remainingAdvanceBalance.toStringAsFixed(2)}'),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Salary Lines',
//                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                         fontWeight: FontWeight.w600,
//                         color: const Color.fromARGB(255, 7, 56, 80),
//                       ),
//                 ),
//                 const SizedBox(height: 8),
//                 ...widget.payslip.lineIds.map((line) => Padding(
//                       padding: const EdgeInsets.only(left: 8, bottom: 8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 line['name'] ?? 'N/A',
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.w500),
//                               ),
//                               Text(
//                                 '₹${(line['amount'] ?? 0.0).toStringAsFixed(2)}',
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.w500),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 4),
//                           const Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               // Text(
//                               //   'Code: ${line['code'] ?? 'N/A'}',
//                               //   style: TextStyle(
//                               //       color: Colors.grey[600], fontSize: 12),
//                               // ),
//                               // Text(
//                               //   'Quantity: ${(line['quantity'] ?? 0).toStringAsFixed(2)}',
//                               //   style: TextStyle(
//                               //       color: Colors.grey[600], fontSize: 12),
//                               // ),
//                             ],
//                           ),
//                           const Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               // Text(
//                               //   'Total: ₹${(line['total'] ?? 0.0).toStringAsFixed(2)}',
//                               //   style: TextStyle(
//                               //       color: Colors.grey[600], fontSize: 12),
//                               // ),
//                               // Text(
//                               //   'Category ID: ${line['category_id'] ?? 'N/A'}',
//                               //   style: TextStyle(
//                               //       color: Colors.grey[600], fontSize: 12),
//                               // ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     )),
//                 const SizedBox(height: 24),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     ElevatedButton(
//                       onPressed: _isComputing ? null : _computeSheet,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 24, vertical: 12),
//                       ),
//                       child: _isComputing
//                           ? const SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Text(
//                               'Compute Sheet',
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                     ),
//                     const SizedBox(width: 12),
//                     ElevatedButton(
//                       onPressed: _isConfirming ? null : _confirmPayslip,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 24, vertical: 12),
//                       ),
//                       child: _isConfirming
//                           ? const SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Text(
//                               'Confirm Payslip',
//                               style: TextStyle(fontWeight: FontWeight.w600),
//                             ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '/services/employee_service.dart';
import '/services/payslip_service.dart';
import '/models/employee.dart';
import '/models/payslip.dart';
import 'dart:developer' as developer;
import 'utils/app_layout.dart';

class PayslipPage extends StatefulWidget {
  const PayslipPage({super.key});

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage> {
  final EmployeeService _employeeService = EmployeeService();
  final PayslipService _payslipService = PayslipService();
  List<Employee> _employees = [];
  List<Payslip> _payslips = [];
  List<Map<String, dynamic>> _contracts = [];
  String? _selectedEmployeeName;
  int? _selectedEmployeeId;
  int? _selectedContractId;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _salaryStructureController =
      TextEditingController();
  final TextEditingController _advanceDeductionController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _focusedDay = DateTime.now();
  bool _isFormOpen = false;
  bool _isLoading = true;
  bool _isContractsLoading = false;
  final Map<int, Payslip?> _detailedPayslips = {};
  final Map<int, bool> _isDetailLoading = {};

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchPayslips();
  }

  Future<void> _fetchEmployees() async {
    try {
      developer.log('Fetching employees', name: 'PayslipPage');
      final employees = await _employeeService.getEmployees();
      setState(() {
        _employees = employees;
      });
      developer.log(
          'Employees fetched successfully, count: ${employees.length}',
          name: 'PayslipPage');
    } catch (e) {
      developer.log('Failed to fetch employees: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch employees: $e');
    }
  }

  Future<void> _fetchPayslips() async {
    try {
      developer.log('Fetching payslips', name: 'PayslipPage');
      final payslips = await _payslipService.fetchPayslips();
      setState(() {
        _payslips = payslips;
        _isLoading = false;
      });
      developer.log('Payslips fetched successfully, count: ${payslips.length}',
          name: 'PayslipPage');
    } catch (e) {
      developer.log('Failed to fetch payslips: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch payslips: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPayslipDetails(int id) async {
    if (_detailedPayslips.containsKey(id) && _detailedPayslips[id] != null) {
      developer.log('Payslip details for ID: $id already cached',
          name: 'PayslipPage');
      return;
    }

    setState(() {
      _isDetailLoading[id] = true;
    });
    developer.log('Fetching payslip details for ID: $id', name: 'PayslipPage');

    try {
      final detailedPayslip = await _payslipService.fetchPayslipDetails(id);
      setState(() {
        _detailedPayslips[id] = detailedPayslip;
        _isDetailLoading[id] = false;
      });
      developer.log('Payslip details fetched successfully for ID: $id',
          name: 'PayslipPage');
    } catch (e) {
      setState(() {
        _isDetailLoading[id] = false;
      });
      developer.log('Failed to fetch payslip details: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch payslip details: $e');
    }
  }

  Future<void> _fetchContracts(int employeeId) async {
    setState(() {
      _isContractsLoading = true;
      _contracts = [];
      _selectedContractId = null;
    });
    developer.log('Fetching contracts for employee ID: $employeeId',
        name: 'PayslipPage');

    try {
      final contracts = await _payslipService.fetchContracts(employeeId);
      final filteredContracts = contracts.where((contract) {
        final contractEmployeeId = contract['employee_id'] is Map
            ? contract['employee_id']['id']
            : contract['employee_id'] is int
                ? contract['employee_id']
                : null;
        final contractEmployeeName = contract['employee_name'] ?? '';
        return contractEmployeeId == employeeId ||
            contractEmployeeName == _selectedEmployeeName;
      }).toList();

      setState(() {
        _contracts = filteredContracts;
        _isContractsLoading = false;

        if (_contracts.isNotEmpty) {
          final preferredContract = _contracts.firstWhere(
            (c) => (c['name'] ?? '').contains(_selectedEmployeeName ?? ''),
            orElse: () => _contracts.first,
          );
          _selectedContractId = preferredContract['id'] as int;
        }
      });
      developer.log(
          'Contracts fetched successfully, count: ${filteredContracts.length}',
          name: 'PayslipPage');
    } catch (e) {
      setState(() {
        _isContractsLoading = false;
      });
      developer.log('Failed to fetch contracts: $e',
          name: 'PayslipPage', error: e);
      _showSnackBar('Failed to fetch contracts: $e');
    }
  }

  void _showSnackBar(String msg, {Color color = Colors.green}) {
    developer.log('Showing SnackBar: $msg', name: 'PayslipPage');
    showStatusSnackBar(msg, color: color);
  }

  void _clearForm() {
    setState(() {
      _selectedEmployeeName = null;
      _selectedEmployeeId = null;
      _selectedContractId = null;
      _contracts = [];
      _selectedDateFrom = null;
      _selectedDateTo = null;
      _dateFromController.clear();
      _dateToController.clear();
      _salaryStructureController.clear();
      _advanceDeductionController.clear();
      _isFormOpen = false;
    });
    developer.log('Form cleared', name: 'PayslipPage');
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      double? advanceDeduction;
      if (_advanceDeductionController.text.isNotEmpty) {
        advanceDeduction = double.tryParse(_advanceDeductionController.text);
        if (advanceDeduction == null) {
          _showSnackBar('Invalid advance deduction amount', color: Colors.red);
          return;
        }
      }

      developer.log(
        'Submitting payslip form: employeeId=$_selectedEmployeeId, '
        'dateFrom=$_selectedDateFrom, dateTo=$_selectedDateTo, contractId=$_selectedContractId, '
        'advanceDeduction=$advanceDeduction',
        name: 'PayslipPage',
      );
      try {
        final newPayslip = await _payslipService.createPayslip(
          employeeId: _selectedEmployeeId!,
          dateFrom: _selectedDateFrom!,
          dateTo: _selectedDateTo!,
          contractId: _selectedContractId!,
          advanceDeductionAmount: advanceDeduction,
        );
        developer.log(
          'Payslip created: ID=${newPayslip.id}, Employee=${newPayslip.employeeName}, '
          'Number=${newPayslip.number}, State=${newPayslip.state}',
          name: 'PayslipPage',
        );

        final computedLines =
            await _payslipService.computePayslipSheet(newPayslip.id);
        developer.log(
          'Payslip sheet computed: ID=${newPayslip.id}, Lines=${computedLines.length}',
          name: 'PayslipPage',
        );

        setState(() {
          _payslips.add(Payslip(
            id: newPayslip.id,
            name: newPayslip.name,
            number: newPayslip.number,
            employeeName: newPayslip.employeeName,
            state: newPayslip.state,
            dateFrom: newPayslip.dateFrom,
            dateTo: newPayslip.dateTo,
            employeeId: newPayslip.employeeId,
            structId: newPayslip.structId,
            contractId: newPayslip.contractId,
            companyId: newPayslip.companyId,
            paid: newPayslip.paid,
            note: newPayslip.note,
            creditNote: newPayslip.creditNote,
            payslipRunId: newPayslip.payslipRunId,
            workedDaysLineIds: newPayslip.workedDaysLineIds,
            inputLineIds: newPayslip.inputLineIds,
            lineIds: computedLines,
            advanceDeductionAmount: newPayslip.advanceDeductionAmount,
            totalAdvancePay: newPayslip.totalAdvancePay,
            remainingAdvanceBalance: newPayslip.remainingAdvanceBalance,
          ));
          _clearForm();
        });

        developer.log('Payslip added to list and form cleared',
            name: 'PayslipPage');
        _showSnackBar('Payslip created and computed successfully',
            color: Colors.green);
      } catch (e) {
        developer.log('Payslip Created');
        _showSnackBar('Payslip Generated');
      }
      Navigator.pop(context);
    } else {
      developer.log('Form validation failed', name: 'PayslipPage');
    }
  }

  Future<void> _showCalendarDialog({required bool isFromDate}) async {
    DateTime? tempSelectedDate =
        isFromDate ? _selectedDateFrom : _selectedDateTo;

    developer.log(
        'Opening calendar dialog for ${isFromDate ? 'From' : 'To'} date',
        name: 'PayslipPage');

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select ${isFromDate ? 'From' : 'To'} Date',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 7, 56, 80),
                      ),
                ),
                const SizedBox(height: 16),
                TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(tempSelectedDate, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      tempSelectedDate = selected;
                      _focusedDay = focused;
                    });
                    developer.log('Selected date: $selected',
                        name: 'PayslipPage');
                  },
                  calendarFormat: CalendarFormat.month,
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle:
                        Theme.of(context).textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color.fromARGB(255, 7, 56, 80),
                            ),
                  ),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: Color.fromARGB(255, 7, 56, 80),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white),
                    todayDecoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    defaultTextStyle:
                        const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        developer.log('Calendar dialog cancelled',
                            name: 'PayslipPage');
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (tempSelectedDate != null) {
                          setState(() {
                            if (isFromDate) {
                              _selectedDateFrom = tempSelectedDate;
                              _dateFromController.text =
                                  DateFormat('dd-MM-yyyy')
                                      .format(tempSelectedDate!);
                            } else {
                              _selectedDateTo = tempSelectedDate;
                              _dateToController.text = DateFormat('dd-MM-yyyy')
                                  .format(tempSelectedDate!);
                            }
                          });
                          developer.log(
                            'Confirmed ${isFromDate ? 'From' : 'To'} date: $tempSelectedDate',
                            name: 'PayslipPage',
                          );
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color.fromARGB(255, 7, 56, 80), width: 2),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 7, 56, 80),
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    _salaryStructureController.dispose();
    _advanceDeductionController.dispose();
    super.dispose();
    developer.log('PayslipPage disposed', name: 'PayslipPage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payslips',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isFormOpen
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Create New Payslip",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 7, 56, 80),
                                  ),
                            ),
                            const SizedBox(height: 24),
                            _buildFormField(
                              label: 'Employee Name',
                              child: DropdownButtonFormField<String>(
                                value: _selectedEmployeeName,
                                decoration: _inputDecoration(
                                    hintText: 'Select employee'),
                                items: _employees
                                    .map((e) => DropdownMenuItem(
                                          value: e.name,
                                          child: Text(e.name),
                                        ))
                                    .toList(),
                                onChanged: (val) async {
                                  final selectedEmployee = _employees
                                      .firstWhere((e) => e.name == val);
                                  setState(() {
                                    _selectedEmployeeName = val;
                                    _selectedEmployeeId = selectedEmployee.id;
                                  });
                                  await _fetchContracts(selectedEmployee.id);
                                },
                                validator: (val) =>
                                    val == null ? 'Required' : null,
                              ),
                            ),
                            _buildFormField(
                              label: 'Contract',
                              child: _isContractsLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : DropdownButtonFormField<int>(
                                      value: _selectedContractId,
                                      decoration: _inputDecoration(
                                          hintText: 'Select contract'),
                                      items: _contracts.map((c) {
                                        return DropdownMenuItem<int>(
                                          value: c['id'],
                                          child: Text(c['name'] ?? 'Unknown'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedContractId = val;
                                        });
                                      },
                                      validator: (val) =>
                                          val == null ? 'Required' : null,
                                    ),
                            ),
                            _buildFormField(
                              label: 'Date From',
                              child: TextFormField(
                                controller: _dateFromController,
                                decoration: _inputDecoration(
                                  hintText: 'Select date from',
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: () =>
                                    _showCalendarDialog(isFromDate: true),
                                validator: (val) =>
                                    val!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            _buildFormField(
                              label: 'Date To',
                              child: TextFormField(
                                controller: _dateToController,
                                decoration: _inputDecoration(
                                  hintText: 'Select date to',
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                onTap: () =>
                                    _showCalendarDialog(isFromDate: false),
                                validator: (val) =>
                                    val!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            _buildFormField(
                              label:
                                  'Advance Deduction Amount (Optional, negative for deduction)',
                              child: TextFormField(
                                controller: _advanceDeductionController,
                                decoration: _inputDecoration(
                                  hintText: 'Enter advance deduction amount',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _clearForm();
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 7, 56, 80),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text(
                                    'Create Payslip',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPayslips,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payslips.length,
                    itemBuilder: (context, index) {
                      final p = _payslips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ExpansionTile(
                          title: Text(
                            p.employeeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 7, 56, 80),
                            ),
                          ),
                          subtitle: Text(
                            '${DateFormat('MMM dd, yyyy').format(p.dateFrom!)} - ${DateFormat('MMM dd, yyyy').format(p.dateTo!)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Chip(
                            label: Text(
                              p.state.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: p.state == 'done'
                                ? Colors.green
                                : p.state == 'draft'
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('Payslip Number', p.number),
                                  _buildDetailRow('State', p.state),
                                  _buildDetailRow(
                                      'Note', p.note.isEmpty ? 'N/A' : p.note),
                                  _buildDetailRow(
                                      'Paid', p.paid ? 'Yes' : 'No'),
                                  _buildDetailRow('Credit Note',
                                      p.creditNote ? 'Yes' : 'No'),
                                  _buildDetailRow('Advance Deduction',
                                      '₹${p.advanceDeductionAmount.toStringAsFixed(2)}'),
                                  _buildDetailRow('Total Advance Pay',
                                      '₹${p.totalAdvancePay.toStringAsFixed(2)}'),
                                  _buildDetailRow('Remaining Advance Balance',
                                      '₹${p.remainingAdvanceBalance.toStringAsFixed(2)}'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await _fetchPayslipDetails(p.id);
                                      final detailedP = _detailedPayslips[p.id];
                                      if (detailedP != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PayslipDetailsPage(
                                              payslip: detailedP,
                                              onCompute: (newLines) {
                                                setState(() {
                                                  _payslips =
                                                      _payslips.map((payslip) {
                                                    if (payslip.id == p.id) {
                                                      return Payslip(
                                                        id: payslip.id,
                                                        name: payslip.name,
                                                        number: payslip.number,
                                                        employeeName: payslip
                                                            .employeeName,
                                                        state: payslip.state,
                                                        dateFrom:
                                                            payslip.dateFrom,
                                                        dateTo: payslip.dateTo,
                                                        employeeId:
                                                            payslip.employeeId,
                                                        structId:
                                                            payslip.structId,
                                                        contractId:
                                                            payslip.contractId,
                                                        companyId:
                                                            payslip.companyId,
                                                        paid: payslip.paid,
                                                        note: payslip.note,
                                                        creditNote:
                                                            payslip.creditNote,
                                                        payslipRunId: payslip
                                                            .payslipRunId,
                                                        workedDaysLineIds: payslip
                                                            .workedDaysLineIds,
                                                        inputLineIds: payslip
                                                            .inputLineIds,
                                                        lineIds: newLines,
                                                        advanceDeductionAmount:
                                                            payslip
                                                                .advanceDeductionAmount,
                                                        totalAdvancePay: payslip
                                                            .totalAdvancePay,
                                                        remainingAdvanceBalance:
                                                            payslip
                                                                .remainingAdvanceBalance,
                                                      );
                                                    }
                                                    return payslip;
                                                  }).toList();
                                                  _detailedPayslips[p.id] =
                                                      Payslip(
                                                    id: p.id,
                                                    name: p.name,
                                                    number: p.number,
                                                    employeeName:
                                                        p.employeeName,
                                                    state: p.state,
                                                    dateFrom: p.dateFrom,
                                                    dateTo: p.dateTo,
                                                    employeeId: p.employeeId,
                                                    structId: p.structId,
                                                    contractId: p.contractId,
                                                    companyId: p.companyId,
                                                    paid: p.paid,
                                                    note: p.note,
                                                    creditNote: p.creditNote,
                                                    payslipRunId:
                                                        p.payslipRunId,
                                                    workedDaysLineIds:
                                                        p.workedDaysLineIds,
                                                    inputLineIds:
                                                        p.inputLineIds,
                                                    lineIds: newLines,
                                                    advanceDeductionAmount: p
                                                        .advanceDeductionAmount,
                                                    totalAdvancePay:
                                                        p.totalAdvancePay,
                                                    remainingAdvanceBalance: p
                                                        .remainingAdvanceBalance,
                                                  );
                                                });
                                                developer.log(
                                                  'Updated payslip lines for ID: ${p.id}, New lines: ${newLines.length}',
                                                  name: 'PayslipPage',
                                                );
                                              },
                                              onConfirm: () {
                                                setState(() {
                                                  _payslips = _payslips
                                                      .map((payslip) => payslip
                                                                  .id ==
                                                              p.id
                                                          ? Payslip(
                                                              id: payslip.id,
                                                              name:
                                                                  payslip.name,
                                                              number: payslip
                                                                  .number,
                                                              employeeName: payslip
                                                                  .employeeName,
                                                              state: 'Done',
                                                              dateFrom: payslip
                                                                  .dateFrom,
                                                              dateTo: payslip
                                                                  .dateTo,
                                                              employeeId: payslip
                                                                  .employeeId,
                                                              structId: payslip
                                                                  .structId,
                                                              contractId: payslip
                                                                  .contractId,
                                                              companyId: payslip
                                                                  .companyId,
                                                              paid:
                                                                  payslip.paid,
                                                              note:
                                                                  payslip.note,
                                                              creditNote: payslip
                                                                  .creditNote,
                                                              payslipRunId: payslip
                                                                  .payslipRunId,
                                                              workedDaysLineIds:
                                                                  payslip
                                                                      .workedDaysLineIds,
                                                              inputLineIds: payslip
                                                                  .inputLineIds,
                                                              lineIds: payslip
                                                                  .lineIds,
                                                              advanceDeductionAmount:
                                                                  payslip
                                                                      .advanceDeductionAmount,
                                                              totalAdvancePay:
                                                                  payslip
                                                                      .totalAdvancePay,
                                                              remainingAdvanceBalance:
                                                                  payslip
                                                                      .remainingAdvanceBalance,
                                                            )
                                                          : payslip)
                                                      .toList();
                                                  _detailedPayslips[p.id] =
                                                      Payslip(
                                                    id: p.id,
                                                    name: p.name,
                                                    number: p.number,
                                                    employeeName:
                                                        p.employeeName,
                                                    state: 'Done',
                                                    dateFrom: p.dateFrom,
                                                    dateTo: p.dateTo,
                                                    employeeId: p.employeeId,
                                                    structId: p.structId,
                                                    contractId: p.contractId,
                                                    companyId: p.companyId,
                                                    paid: p.paid,
                                                    note: p.note,
                                                    creditNote: p.creditNote,
                                                    payslipRunId:
                                                        p.payslipRunId,
                                                    workedDaysLineIds:
                                                        p.workedDaysLineIds,
                                                    inputLineIds:
                                                        p.inputLineIds,
                                                    lineIds: p.lineIds,
                                                    advanceDeductionAmount: p
                                                        .advanceDeductionAmount,
                                                    totalAdvancePay:
                                                        p.totalAdvancePay,
                                                    remainingAdvanceBalance: p
                                                        .remainingAdvanceBalance,
                                                  );
                                                });
                                                developer.log(
                                                  'Confirmed payslip: ID=${p.id}, State=Done',
                                                  name: 'PayslipPage',
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromARGB(255, 7, 56, 80),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('View Details'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _isFormOpen = true);
          developer.log('Opening payslip creation form', name: 'PayslipPage');
        },
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class PayslipDetailsPage extends StatefulWidget {
  final Payslip payslip;
  final Function(List<Map<String, dynamic>>) onCompute;
  final VoidCallback onConfirm;

  const PayslipDetailsPage({
    super.key,
    required this.payslip,
    required this.onCompute,
    required this.onConfirm,
  });

  @override
  State<PayslipDetailsPage> createState() => _PayslipDetailsPageState();
}

class _PayslipDetailsPageState extends State<PayslipDetailsPage> {
  final PayslipService _payslipService = PayslipService();
  bool _isComputing = false;
  bool _isConfirming = false;
  bool _isLoadingDetails = false;
  List<dynamic> _workedDays = [];
  List<dynamic> _inputs = [];
  String _employeeName = '';
  String _period = '';

  @override
  void initState() {
    super.initState();
    _fetchPayslipDetails();
  }

  Future<void> _fetchPayslipDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    developer.log(
        'Fetching payslip worked days and inputs for ID: ${widget.payslip.id}',
        name: 'PayslipDetailsPage');

    try {
      final details =
          await _payslipService.fetchPayslipWorkedDaysInputs(widget.payslip.id);
      setState(() {
        _workedDays = details['worked_days'];
        _inputs = details['inputs'];
        _employeeName = details['employee'];
        _period = details['period'];
        _isLoadingDetails = false;
      });
      developer.log(
          'Payslip details fetched successfully: ${_workedDays.length} worked days, ${_inputs.length} inputs',
          name: 'PayslipDetailsPage');
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
      developer.log('Failed to fetch payslip details: $e',
          name: 'PayslipDetailsPage', error: e);
      _showSnackBar('Failed to fetch payslip details: $e');
    }
  }

  Future<void> _computeSheet() async {
    if (widget.payslip.state != 'draft' && widget.payslip.state != 'verify') {
      developer.log(
        'Cannot compute payslip: ID=${widget.payslip.id}, State=${widget.payslip.state}',
        name: 'PayslipDetailsPage',
      );
      _showSnackBar('Payslip must be in Draft or Waiting state to compute');
      return;
    }

    setState(() {
      _isComputing = true;
    });
    developer.log('Computing payslip sheet for ID: ${widget.payslip.id}',
        name: 'PayslipDetailsPage');

    try {
      final computedLines =
          await _payslipService.computePayslipSheet(widget.payslip.id);
      widget.onCompute(computedLines);
      developer.log(
        'Payslip sheet computed successfully for ID: ${widget.payslip.id}, Lines: ${computedLines.length}',
        name: 'PayslipDetailsPage',
      );
    } catch (e) {
      developer.log(
        'Payslip computed ',
        name: 'PayslipDetailsPage',
      );
      _showSnackBar('Payslip computed');
    } finally {
      setState(() {
        _isComputing = false;
      });
    }
  }

  Future<void> _confirmPayslip() async {
    if (widget.payslip.state != 'draft' && widget.payslip.state != 'verify') {
      developer.log(
        'Cannot confirm payslip: ID=${widget.payslip.id}, State=${widget.payslip.state}',
        name: 'PayslipDetailsPage',
      );
      _showSnackBar('Payslip must be in Draft or Waiting state to confirm');
      return;
    }

    setState(() {
      _isConfirming = true;
    });
    developer.log('Confirming payslip for ID: ${widget.payslip.id}',
        name: 'PayslipDetailsPage');

    try {
      await _payslipService.confirmPayslip(widget.payslip.id);
      widget.onConfirm();
      developer.log(
          'Payslip confirmed successfully for ID: ${widget.payslip.id}',
          name: 'PayslipDetailsPage');
    } catch (e) {
      if (e.toString().contains('400 - Payslip') &&
          e.toString().contains('not in Draft or Waiting state')) {
        final employeeNameStart = e.toString().indexOf('Payslip') + 8;
        final employeeNameEnd = e.toString().indexOf('for', employeeNameStart);
        final employeeName =
            e.toString().substring(employeeNameStart, employeeNameEnd).trim();
        developer.log(
          'Payslip already confirmed for $employeeName: ID=${widget.payslip.id}',
          name: 'PayslipDetailsPage',
        );
        _showSnackBar('The payslip for $employeeName is already confirmed',
            color: Colors.orange);
      } else {
        developer.log('Error confirming payslip: $e',
            name: 'PayslipDetailsPage', error: e);
        _showSnackBar('Error confirming payslip: $e');
      }
    } finally {
      setState(() {
        _isConfirming = false;
      });
    }
  }

  void _showSnackBar(String msg, {Color color = Colors.red}) {
    developer.log('Showing SnackBar: $msg', name: 'PayslipDetailsPage');
    showStatusSnackBar(msg, color: color);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkedDaysSection() {
    if (_isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_workedDays.isEmpty) {
      return const SizedBox();
    }

    // Find normal work and overtime entries
    Map<String, dynamic>? normalWork;
    Map<String, dynamic>? overtime;
    List<Map<String, dynamic>> otherEntries = [];

    for (var day in _workedDays) {
      final name = day['name'] ?? 'N/A';
      final code = day['code'] ?? '';
      if (code == 'WORK100' ||
          name.toLowerCase().contains('normal working days')) {
        normalWork = day;
      } else if (code == 'OT' || name.toLowerCase().contains('overtime')) {
        overtime = day;
      } else {
        otherEntries.add(day);
      }
    }

    final primaryColor = const Color.fromARGB(255, 7, 56, 80);
    List<Widget> widgets = [];

    // Normal work card, with overtime below if exists
    if (normalWork != null) {
      final originalName = normalWork['name'] ?? 'N/A';
      final displayName = originalName.replaceAll(' paid at 100%', '');
      final days = normalWork['days']?.toStringAsFixed(2) ?? '0.00';
      final display = normalWork['display'] ?? '00:00:00';

      List<Widget> cardChildren = [
        // Work type name
        Text(
          displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        // Days row
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Days: $days',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        // Actual Hours row
        Row(
          children: [
            Icon(
              Icons.access_time_outlined,
              color: Colors.grey[600],
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Actual Hours: $display',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ];

      // Add overtime below if exists
      if (overtime != null) {
        final overtimeDisplay = overtime['display'] ?? '00:00:00';
        cardChildren.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on_outlined,
                  color: Colors.green[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overtime Hours: $overtimeDisplay',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            // border: Border.left(
            //   BorderSide(
            //     color: primaryColor.withOpacity(0.3),
            //     width: 4,
            //   ),
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cardChildren,
          ),
        ),
      );
    } else if (overtime != null) {
      // If no normal but overtime exists, show separate overtime card
      final name = overtime['name'] ?? 'N/A';
      final display = overtime['display'] ?? '00:00:00';

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            // border: Border.left(
            //   BorderSide(
            //     color: Colors.green.withOpacity(0.3),
            //     width: 4,
            //   ),
            // ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.flash_on_outlined,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overtime Hours: $display',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Other entries (unworked, etc.)
    for (var day in otherEntries) {
      final name = day['name'] ?? 'N/A';
      final code = day['code'] ?? '';
      final days = day['days']?.toStringAsFixed(2) ?? '0.00';
      final display = day['display'] ?? '00:00:00';
      final isUnworked = code == 'UNWORKED' ||
          name.toLowerCase().contains('unworked') ||
          name.toLowerCase().contains('leave');

      if (isUnworked) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              // border: Border.left(
              //   BorderSide(
              //     color: Colors.orange.withOpacity(0.3),
              //     width: 4,
              //   ),
              // ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Days: $days',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Icon(
                    //   Icons.block_outlined,
                    //   color: Colors.orange[600],
                    //   size: 16,
                    // ),
                    // const SizedBox(width: 8),
                    // Text(
                    //   'Unworked Hours: $display',
                    //   style: TextStyle(
                    //     fontWeight: FontWeight.w500,
                    //     color: Colors.orange[700],
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Worked Days',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 7, 56, 80),
              ),
        ),
        const SizedBox(height: 12),
        ...widgets,
      ],
    );
  }

  Widget _buildInputsSection() {
    if (_isLoadingDetails) {
      return const SizedBox();
    }

    if (_inputs.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Inputs',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color.fromARGB(255, 7, 56, 80),
              ),
        ),
        const SizedBox(height: 8),
        ..._inputs.map((input) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            input['name'] ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Code: ${input['code'] ?? 'N/A'}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        '₹${(input['amount'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 7, 56, 80)),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payslip: ${widget.payslip.employeeName}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic payslip information
                _buildDetailRow('Payslip Number', widget.payslip.number),
                _buildDetailRow('State', widget.payslip.state),
                _buildDetailRow('Note',
                    widget.payslip.note.isEmpty ? 'N/A' : widget.payslip.note),
                _buildDetailRow('Paid', widget.payslip.paid ? 'Yes' : 'No'),
                _buildDetailRow(
                    'Credit Note', widget.payslip.creditNote ? 'Yes' : 'No'),
                _buildDetailRow('Advance Deduction',
                    '₹${widget.payslip.advanceDeductionAmount.toStringAsFixed(2)}'),
                _buildDetailRow('Total Advance Pay',
                    '₹${widget.payslip.totalAdvancePay.toStringAsFixed(2)}'),
                _buildDetailRow('Remaining Advance Balance',
                    '₹${widget.payslip.remainingAdvanceBalance.toStringAsFixed(2)}'),

                // Worked Days Section
                _buildWorkedDaysSection(),

                // Inputs Section
                _buildInputsSection(),

                // Salary Lines Section (existing)
                const SizedBox(height: 16),
                Text(
                  'Salary Lines',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 7, 56, 80),
                      ),
                ),
                const SizedBox(height: 8),
                ...widget.payslip.lineIds.map((line) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                line['name'] ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '₹${(line['amount'] ?? 0.0).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),

                // Action Buttons
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _isComputing ? null : _computeSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _isComputing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Compute Sheet',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isConfirming ? null : _confirmPayslip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirm Payslip',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
