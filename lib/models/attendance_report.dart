
class AttendanceReport {
  final int employeeId;
  final String employeeName;
  final String month;
  final int year;
  final int daysPresent;
  final String totalHours;
  final double fullLeaveDays;
  final double halfLeaveDays;
  final double wfhDays;
  final String department;
  final String totalLunchDuration;

  AttendanceReport({
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.year,
    required this.daysPresent,
    required this.totalHours,
    required this.fullLeaveDays,
    required this.halfLeaveDays,
    required this.wfhDays,
    required this.department,
    required this.totalLunchDuration,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name'] ?? '',
      month: json['month'] ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      daysPresent: (json['days_present'] as num?)?.toInt() ?? 0,
      totalHours: json['total_hours_display'] as String? ?? '00:00:00',
      fullLeaveDays: (json['full_leave_days'] as num?)?.toDouble() ?? 0.0,
      halfLeaveDays: (json['half_leave_days'] as num?)?.toDouble() ?? 0.0,
      wfhDays: (json['wfh_days'] as num?)?.toDouble() ?? 0.0,
      department: json['department'] ?? '',
      totalLunchDuration:
          json['total_lunch_duration_display'] as String? ?? '00:00:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'month': month,
      'year': year,
      'days_present': daysPresent,
      'total_hours_display': totalHours,
      'full_leave_days': fullLeaveDays,
      'half_leave_days': halfLeaveDays,
      'wfh_days': wfhDays,
      'department': department,
      'total_lunch_duration_display': totalLunchDuration,
    };
  }
}
