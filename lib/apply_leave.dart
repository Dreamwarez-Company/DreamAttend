import 'dart:async';

import 'package:flutter/material.dart';
import '/models/leave_request.dart';
import '/services/leave_service.dart';
import 'widget/search_filter_bar.dart';
import 'utils/app_layout.dart';

class ApplyLeave extends StatefulWidget {
  final String userRole;
  final String currentUserName;

  const ApplyLeave({
    super.key,
    required this.userRole,
    required this.currentUserName,
  });

  @override
  State<ApplyLeave> createState() => _ApplyLeaveState();
}

class _ApplyLeaveState extends State<ApplyLeave> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final LeaveService _leaveService = LeaveService();

  bool _isLoading = false;
  bool _isFetching = false;
  bool _showForm = false;
  bool _showFilter = false;

  String? _selectedStatus = 'submitted';
  String? _selectedLeaveType;
  String? _selectedHalfDayType;
  String? _selectedLeaveSubType;
  String? _selectedFilterStatus = 'all';
  String? _tempFilterStatus = 'all';

  List<LeaveRequest> _leaveRequests = [];
  final ValueNotifier<List<LeaveRequest>> _filteredNotifier =
      ValueNotifier<List<LeaveRequest>>([]);
  Timer? _debounce;
  Map<String, int>? _cachedStats;
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _fetchLeaveRequests();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _filteredNotifier.dispose();
    _loadingNotifier.dispose();
    _searchController.dispose();
    _reasonController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeaveRequests() async {
    if (_isFetching) return;

    setState(() => _isFetching = true);
    try {
      final requests = await _leaveService.getLeaveRequests();
      List<LeaveRequest> filteredRequests;
      if (widget.userRole == 'admin') {
        filteredRequests = requests;
      } else {
        filteredRequests = requests
            .where((request) => request.employeeName == widget.currentUserName)
            .toList();
      }
      // Sort by startDate descending (latest first)
      filteredRequests.sort((a, b) {
        final dateA = a.parsedStartDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.parsedStartDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      setState(() {
        _leaveRequests = filteredRequests;
        _updateStats();
      });
      _filterRequests();
    } catch (e) {
      _showResultDialog('Error', 'Unable to load leave requests.', false);
    } finally {
      if (!mounted) return;

      setState(() => _isFetching = false);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 300), _filterRequests);
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) =>
          Theme(data: ThemeData.light(), child: child!),
    );

    setState(() {
      controller.text =
          "${pickedDate?.day.toString().padLeft(2, '0')}-${pickedDate?.month.toString().padLeft(2, '0')}-${pickedDate?.year}";
      if (_selectedLeaveType == 'half_day' &&
          controller == _startDateController) {
        _endDateController.text = controller.text;
      }
    });
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    if (isSuccess) {
      if (message.contains('rejected')) {
        errorSnackBar(title, message);
      } else {
        successSnackBar(title, message);
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _reasonController.clear();
        _startDateController.clear();
        _endDateController.clear();
        setState(() {
          _selectedStatus = 'submitted';
          _selectedLeaveType = null;
          _selectedHalfDayType = null;
          _selectedLeaveSubType = null;
          _showForm = false;
        });
        _fetchLeaveRequests();
      });
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _applyLeave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeaveType == 'half_day' &&
        _startDateController.text != _endDateController.text) {
      _showResultDialog(
        'Error',
        'Half-day requests require same start and end date.',
        false,
      );
      return;
    }

    if (_selectedLeaveType == 'leave' && _selectedLeaveSubType == null) {
      _showResultDialog(
        'Error',
        'Please choose Sick or Casual leave type.',
        false,
      );
      return;
    }

    _loadingNotifier.value = true;

    try {
      final leaveRequest = LeaveRequest(
        employeeName: widget.currentUserName,
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        reason: _reasonController.text.trim(),
        status: _selectedStatus,
        leaveType: _selectedLeaveType,
        halfDayType: _selectedHalfDayType,
        leaveSubType: _selectedLeaveSubType,
      );

      await _leaveService.applyLeave(leaveRequest);

      _showResultDialog('Success', 'Leave application submitted', true);
    } catch (e) {
      _showResultDialog('Error', 'Failed to submit leave application.', false);
    } finally {
      _loadingNotifier.value = false;
    }
  }

  Future<void> _approveLeave(int leaveId) async {
    setState(() => _isLoading = true);
    try {
      await _leaveService.approveLeave(leaveId);
      _showResultDialog('Success', 'Leave application approved!', true);
    } catch (e) {
      _showResultDialog('Error', 'Failed to approve leave request.', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectLeave(int leaveId) async {
    setState(() => _isLoading = true);
    try {
      await _leaveService.rejectLeave(leaveId);
      _showResultDialog('Success', 'Leave application rejected!', true);
    } catch (e) {
      _showResultDialog('Error', 'Failed to reject leave request.', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) return 'Please select a date';
    try {
      final parts = value.split('-');
      if (parts.length != 3) throw const FormatException();
      DateTime.parse('${parts[2]}-${parts[1]}-${parts[0]}');
      return null;
    } catch (_) {
      return 'Invalid date format (DD-MM-YYYY)';
    }
  }

  InputDecoration _buildInputDecoration(
    String label, {
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF073850)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: icon != null
          ? IconButton(
              icon: Icon(icon, color: const Color(0xFF073850)),
              onPressed: onTap,
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBorderColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'submitted':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _filterRequests() {
    final query = _searchController.text.trim().toLowerCase();
    Iterable<LeaveRequest> filtered = _leaveRequests;

    if (_selectedFilterStatus != 'all') {
      filtered = filtered.where(
        (request) => request.status == _selectedFilterStatus,
      );
    }

    if (query.isNotEmpty) {
      filtered = filtered.where(
        (request) => request.employeeName.toLowerCase().contains(query),
      );
    }

    _filteredNotifier.value = List<LeaveRequest>.unmodifiable(filtered);
  }

  void _showFilterDialog() {
    setState(() {
      _showFilter = !_showFilter;
      _tempFilterStatus = _selectedFilterStatus;
    });
  }

  Widget _buildFilterUI() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF073850),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a status to filter leave requests:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF073850),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _tempFilterStatus == 'all',
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
                labelStyle: TextStyle(
                  color: _tempFilterStatus == 'all'
                      ? Colors.blue
                      : const Color(0xFF073850),
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (selected) {
                  setState(() {
                    _tempFilterStatus = selected ? 'all' : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('Submitted'),
                selected: _tempFilterStatus == 'submitted',
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
                labelStyle: TextStyle(
                  color: _tempFilterStatus == 'submitted'
                      ? Colors.orange
                      : const Color(0xFF073850),
                  fontWeight: FontWeight.w600,
                ),
                avatar: CircleAvatar(
                  backgroundColor: _getStatusColor('submitted'),
                  radius: 8,
                ),
                onSelected: (selected) {
                  setState(() {
                    _tempFilterStatus = selected ? 'submitted' : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('Approved'),
                selected: _tempFilterStatus == 'approved',
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
                labelStyle: TextStyle(
                  color: _tempFilterStatus == 'approved'
                      ? Colors.green
                      : const Color(0xFF073850),
                  fontWeight: FontWeight.w600,
                ),
                avatar: CircleAvatar(
                  backgroundColor: _getStatusColor('approved'),
                  radius: 8,
                ),
                onSelected: (selected) {
                  setState(() {
                    _tempFilterStatus = selected ? 'approved' : null;
                  });
                },
              ),
              FilterChip(
                label: const Text('Rejected'),
                selected: _tempFilterStatus == 'rejected',
                selectedColor: Colors.red.withOpacity(0.2),
                checkmarkColor: Colors.red,
                labelStyle: TextStyle(
                  color: _tempFilterStatus == 'rejected'
                      ? Colors.red
                      : const Color(0xFF073850),
                  fontWeight: FontWeight.w600,
                ),
                avatar: CircleAvatar(
                  backgroundColor: _getStatusColor('rejected'),
                  radius: 8,
                ),
                onSelected: (selected) {
                  setState(() {
                    _tempFilterStatus = selected ? 'rejected' : null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilterStatus = 'all';
                    _tempFilterStatus = 'all';
                    _showFilter = false;
                  });
                  _filterRequests();
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilterStatus = _tempFilterStatus;
                    _showFilter = false;
                  });
                  _filterRequests();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF073850),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, int> _calculateLeaveStats() {
    final stats = {'submitted': 0, 'approved': 0, 'rejected': 0};
    for (var request in _leaveRequests) {
      stats[request.status ?? 'submitted'] =
          (stats[request.status ?? 'submitted'] ?? 0) + 1;
    }
    return stats;
  }

  void _updateStats() {
    _cachedStats = _calculateLeaveStats();
  }

  Widget _buildStatCircle(String label, double percent, Color color) {
    return Column(
      children: [
        Container(
          width: 70, // Reduced size
          height: 70, // Reduced size
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF073850),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLeaveStats() {
    final stats = _cachedStats ?? const {'submitted': 0, 'approved': 0, 'rejected': 0};
    final total = stats.values.fold(0, (sum, count) => sum + count);
    if (total == 0) {
      return const SizedBox.shrink();
    }

    final submittedPercent = (stats['submitted']! / total) * 100;
    final approvedPercent = (stats['approved']! / total) * 100;
    final rejectedPercent = (stats['rejected']! / total) * 100;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCircle(
                    'Submitted', submittedPercent, Colors.orange.shade400),
                _buildStatCircle(
                    'Approved', approvedPercent, Colors.green.shade400),
                _buildStatCircle(
                    'Rejected', rejectedPercent, Colors.red.shade400),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Leave Request Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF073850),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveList() {
    return Expanded(
      child: ValueListenableBuilder<List<LeaveRequest>>(
        valueListenable: _filteredNotifier,
        builder: (context, requests, _) {
          if (requests.isEmpty) {
            return Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.userRole == 'admin'
                        ? 'No leave applications available.'
                        : 'No leave applications found.',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF073850),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            cacheExtent: 500,
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildLeaveCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRequest request) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusBorderColor(request.status),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey(request.id ?? '${request.employeeName}-${request.startDate}'),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              request.employeeName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF073850),
              ),
            ),
            Chip(
              label: Text(
                request.status?.toUpperCase() ?? 'SUBMITTED',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _getStatusColor(request.status),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ],
        ),
        subtitle: Text(
          request.leaveType == 'leave'
              ? 'Leave (${request.leaveSubType == 'sick' ? 'Sick' : 'Casual'})'
              : request.leaveType == 'wfh'
                  ? 'Work From Home'
                  : 'Half Day${request.halfDayType != null ? ' (${request.halfDayType == 'first_half' ? 'First Half' : 'Second Half'})' : ''}',
          style: const TextStyle(
            color: Color(0xFF073850),
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeaveDetailRow('From:', request.startDate),
                const SizedBox(height: 8),
                _buildLeaveDetailRow('To:', request.endDate),
                const SizedBox(height: 8),
                _buildLeaveDetailRow('Reason:', request.reason, expanded: true),
                if (widget.userRole == 'admin' &&
                    request.status == 'submitted' &&
                    request.id != null) ...[
                  const Divider(height: 8, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : () => _approveLeave(request.id!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Approve',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : () => _rejectLeave(request.id!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reject',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveDetailRow(String label, String value, {bool expanded = false}) {
    final valueWidget = Text(
      value,
      style: const TextStyle(
        color: Color(0xFF073850),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF073850),
            ),
          ),
        ),
        if (expanded) Expanded(child: valueWidget) else valueWidget,
      ],
    );
  }

  Widget _buildLeaveForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF073850),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.currentUserName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF073850),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Start Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF073850),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _startDateController,
                    readOnly: true,
                    decoration: _buildInputDecoration(
                      'Start date (DD-MM-YYYY)',
                      icon: Icons.calendar_today,
                      onTap: () => _selectDate(context, _startDateController),
                    ),
                    validator: _validateDate,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'End Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF073850),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _endDateController,
                    readOnly: true,
                    decoration: _buildInputDecoration(
                      'End date (DD-MM-YYYY)',
                      icon: Icons.calendar_today,
                      onTap: () => _selectDate(context, _endDateController),
                    ),
                    validator: _validateDate,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason for Leave',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF073850),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: _buildInputDecoration('Enter reason for leave'),
                    validator: (value) =>
                        (value?.isEmpty ?? true) ? 'Required field' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Leave Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF073850),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLeaveType,
                    decoration: _buildInputDecoration('Select leave type'),
                    items: const [
                      DropdownMenuItem(value: 'leave', child: Text('Leave')),
                      // DropdownMenuItem(
                      //   value: 'wfh',
                      //   child: Text('Work From Home'),
                      // ),
                      DropdownMenuItem(
                        value: 'half_day',
                        child: Text('Half Day'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveType = value;
                        _selectedHalfDayType = null;
                        _selectedLeaveSubType = null;
                        if (value == 'half_day' &&
                            _startDateController.text.isNotEmpty) {
                          _endDateController.text = _startDateController.text;
                        }
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a leave type' : null,
                  ),
                  if (_selectedLeaveType == 'half_day') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Half Day Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF073850),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedHalfDayType,
                      decoration: _buildInputDecoration('Select half day type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'first_half',
                          child: Text('First Half'),
                        ),
                        DropdownMenuItem(
                          value: 'second_half',
                          child: Text('Second Half'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedHalfDayType = value),
                      validator: (value) => value == null
                          ? 'Please select a half day type'
                          : null,
                    ),
                  ],
                  if (_selectedLeaveType == 'leave') ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Leave Sub-Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF073850),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLeaveSubType,
                      decoration: _buildInputDecoration(
                        'Select leave sub-type',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'sick', child: Text('Sick')),
                        DropdownMenuItem(
                          value: 'casual',
                          child: Text('Casual'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedLeaveSubType = value),
                      validator: (value) => value == null
                          ? 'Please select a leave sub-type'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() => _showForm = false);
                                _reasonController.clear();
                                _startDateController.clear();
                                _endDateController.clear();
                                setState(() {
                                  _selectedStatus = 'submitted';
                                  _selectedLeaveType = null;
                                  _selectedHalfDayType = null;
                                  _selectedLeaveSubType = null;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _loadingNotifier,
                        builder: (context, isLoading, _) {
                          return ElevatedButton(
                            onPressed: isLoading ? null : _applyLeave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF073850),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          );
                        },
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

  Widget _buildAdminWarning() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Admins can only view and manage leave applications.\nApplying for leave is restricted to employees.',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF073850),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leave Applications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF073850),
      ),
      backgroundColor: const Color(0xFFF1F6F9),
      body: _showForm
          ? (widget.userRole == 'employee'
              ? _buildLeaveForm()
              : _buildAdminWarning())
          : Column(
              children: [
                if (widget.userRole == 'admin') _buildLeaveStats(),
                if (_showFilter) _buildFilterUI(),
                SearchFilterBar(
                  controller: _searchController,
                  hintText: 'Search by Employee name',
                  onChanged: _onSearchChanged,
                  showFilter: _showFilter,
                  onFilterPressed: _showFilterDialog,
                ),
                _isFetching
                    ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildLeaveList(),
              ],
            ),
      floatingActionButton: _showForm || widget.userRole != 'employee'
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _showForm = true),
              backgroundColor: const Color(0xFF073850),
              child: const Icon(Icons.add, color: Colors.orange),
            ),
    );
  }
}
