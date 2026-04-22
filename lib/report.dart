import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // Added for persistent storage
import '/models/attendance.dart';
import '/models/attendance_report.dart';
import '/services/attendance_services.dart';
import '/services/employee_service.dart';
import 'utils/app_layout.dart';

class UserReportPage extends StatefulWidget {
  final AttendanceReport attendanceReport;
  final String currentUserName;

  const UserReportPage({
    super.key,
    required this.attendanceReport,
    required this.currentUserName,
  });

  @override
  State<UserReportPage> createState() => _UserReportPageState();
}

class _UserReportPageState extends State<UserReportPage> {
  final AttendanceService _attendanceService = AttendanceService();
  AttendanceReport? _currentReport;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    showStatusSnackBar(
      message,
      color: backgroundColor,
      duration: duration,
    );
  }

  @override
  void initState() {
    super.initState();
    _currentReport = widget.attendanceReport;
    try {
      _selectedMonth = int.parse(widget.attendanceReport.month);
      _selectedYear = widget.attendanceReport.year;
    } catch (e) {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  bool _hasNoData(AttendanceReport? report) {
    if (report == null) return true;
    return report.daysPresent == 0 &&
        report.totalHours == '00:00:00' &&
        report.fullLeaveDays == 0 &&
        report.halfLeaveDays == 0 &&
        report.wfhDays == 0;
  }

  Future<void> _showMonthPicker() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == _selectedMonth;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _updateMonth(month);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 7, 56, 80)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(255, 7, 56, 80)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getMonthName(month).substring(0, 3),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showYearPicker() async {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - 5;
    final endYear = currentYear + 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: endYear - startYear + 1,
              itemBuilder: (context, index) {
                final year = startYear + index;
                final isSelected = year == _selectedYear;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _updateYear(year);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color.fromARGB(255, 7, 56, 80)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(255, 7, 56, 80)
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        year.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _updateMonth(int month) {
    if (month != _selectedMonth) {
      setState(() {
        _selectedMonth = month;
      });
      _fetchReportForSelectedDate();
    }
  }

  void _updateYear(int year) {
    if (year != _selectedYear) {
      setState(() {
        _selectedYear = year;
      });
      _fetchReportForSelectedDate();
    }
  }

  Future<void> _fetchReportForSelectedDate() async {
    setState(() => _isLoading = true);
    try {
      final month = _selectedMonth.toString().padLeft(2, '0');
      final year = _selectedYear;

      final reports = await _attendanceService
          .fetchAllEmployeesAttendanceReport(month: month, year: year);

      final userReport = reports.firstWhere(
        (report) =>
            report.employeeName.toLowerCase() ==
            widget.currentUserName.toLowerCase(),
        orElse: () => AttendanceReport(
          employeeId: 0,
          employeeName: widget.currentUserName,
          month: month,
          year: year,
          daysPresent: 0,
          totalHours: '00:00:00',
          fullLeaveDays: 0,
          halfLeaveDays: 0,
          wfhDays: 0,
          department: '',
          totalLunchDuration: '',
        ),
      );

      setState(() {
        _currentReport = userReport;
      });
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message:
            "Unable to load report for ${_getMonthName(_selectedMonth)} $_selectedYear: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
      setState(() {
        final month = _selectedMonth.toString().padLeft(2, '0');
        _currentReport = AttendanceReport(
          employeeId: 0,
          employeeName: widget.currentUserName,
          month: month,
          year: _selectedYear,
          daysPresent: 0,
          totalHours: '00:00:00',
          fullLeaveDays: 0,
          halfLeaveDays: 0,
          wfhDays: 0,
          department: '',
          totalLunchDuration: '',
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${_currentReport?.employeeName ?? widget.currentUserName}'s Performance",
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        elevation: 4,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F6F9), Color(0xFFE5EAF0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 7, 56, 80)),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _showMonthPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _getMonthName(_selectedMonth),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showYearPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _selectedYear.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _hasNoData(_currentReport)
                          ? Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No attendance data available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'for ${_getMonthName(_selectedMonth)} $_selectedYear',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        7,
                                        56,
                                        80,
                                      ),
                                      child: Text(
                                        (_currentReport?.employeeName ??
                                                widget.currentUserName)[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _currentReport?.employeeName ??
                                          widget.currentUserName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_currentReport?.department.isNotEmpty ??
                                        false)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _currentReport!.department,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    const SizedBox(height: 24),
                                    _buildReportItem(
                                      icon: Icons.check_circle,
                                      color: Colors.green[700]!,
                                      label: "Days Present",
                                      value: (_currentReport?.daysPresent ?? 0)
                                          .toString(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.access_time,
                                      color: Colors.orange[700]!,
                                      label: "Total Hours",
                                      value: _currentReport?.totalHours ??
                                          '00:00:00',
                                    ),
                                    // const SizedBox(height: 16),
                                    // _buildReportItem(
                                    //   icon: Icons.home_work,
                                    //   color: Colors.purple[700]!,
                                    //   label: "Work From Home",
                                    //   value: (_currentReport?.wfhDays ?? 0)
                                    //       .toString(),
                                    // ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.timelapse,
                                      color: Colors.teal[700]!,
                                      label: "Half Days",
                                      value:
                                          (_currentReport?.halfLeaveDays ?? 0)
                                              .toString(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.event_busy,
                                      color: Colors.red[700]!,
                                      label: "Full Leave Days",
                                      value:
                                          (_currentReport?.fullLeaveDays ?? 0)
                                              .toString(),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildReportItem(
                                      icon: Icons.lunch_dining,
                                      color: Colors.blueGrey,
                                      label: "Total Lunch Duration",
                                      value:
                                          _currentReport?.totalLunchDuration ??
                                              '00:00:00',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 20),
                        label: const Text(
                          "Back to Attendance Hub",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildReportItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
