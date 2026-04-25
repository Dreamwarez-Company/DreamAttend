class LeaveRequest {
  final int? id;
  final String employeeName;
  final String startDate;
  final String endDate;
  final String reason;
  final String? status;
  final String? leaveType;
  final String? halfDayType;
  final String? leaveSubType;
  final DateTime? parsedStartDate;
  final DateTime? parsedEndDate;

  LeaveRequest({
    this.id,
    required this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'submitted',
    this.leaveType,
    this.halfDayType,
    this.leaveSubType,
    this.parsedStartDate,
    this.parsedEndDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': employeeName,
    'start_date': startDate,
    'end_date': endDate,
    'reason': reason,
    'state': status,
    'leave_type': leaveType,
    'half_day_type': halfDayType,
    'leave_sub_type': leaveSubType,
  };

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json');

    DateTime? parseDateValue(dynamic date) {
      if (date == null) return null;
      if (date is DateTime) return date;
      if (date is String) {
        final trimmedDate = date.trim();
        if (trimmedDate.isEmpty) return null;

        try {
          if (trimmedDate.contains('-') && trimmedDate.split('-').length == 3) {
            final parts = trimmedDate.split('-');
            final isDisplayFormat =
                parts[0].length == 2 && parts[1].length == 2 && parts[2].length == 4;

            if (isDisplayFormat) {
              return DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
            }
          }

          return DateTime.tryParse(trimmedDate);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    String formatDate(dynamic date) {
      if (date == null) return '';
      final parsedDate = parseDateValue(date);
      if (parsedDate == null) {
        return date.toString();
      }
      return _formatDisplayDate(parsedDate);
    }

    String? safeString(dynamic value, String fieldName) {
      if (value == null || value is String) {
        return value;
      }
      print(
        'Warning: Unexpected type for $fieldName: ${value.runtimeType}, value: $value',
      );
      return null;
    }

    return LeaveRequest(
      id: json['id'],
      employeeName:
          json['employee_id'] is List
              ? json['employee_id'][1] ?? ''
              : json['employee_id']?['name'] ??
                  json['employee_name'] ??
                  json['employee'] ??
                  '',
      startDate: formatDate(json['start_date']),
      endDate: formatDate(json['end_date']),
      reason: json['reason'] ?? '',
      status: safeString(json['state'], 'state'),
      leaveType: safeString(json['leave_type'], 'leave_type'),
      halfDayType: safeString(json['half_day_type'], 'half_day_type'),
      leaveSubType: safeString(json['leave_sub_type'], 'leave_sub_type'),
      parsedStartDate: parseDateValue(json['start_date']),
      parsedEndDate: parseDateValue(json['end_date']),
    );
  }

  static String _formatDisplayDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }
}

// class LeaveRequest {
//   final int? id;
//   final String employeeName;
//   final String startDate;
//   final String endDate;
//   final String reason;
//   final String? status;
//   final String? leaveType;
//   final String? halfDayType;
//   final String? leaveSubType;

//   LeaveRequest({
//     this.id,
//     required this.employeeName,
//     required this.startDate,
//     required this.endDate,
//     required this.reason,
//     this.status = 'submitted',
//     this.leaveType,
//     this.halfDayType,
//     this.leaveSubType,
//   });

//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'name': employeeName,
//     'start_date': startDate,
//     'end_date': endDate,
//     'reason': reason,
//     'state': status,
//     'leave_type': leaveType,
//     'half_day_type': halfDayType,
//     'leave_sub_type': leaveSubType,
//   };

//   factory LeaveRequest.fromJson(Map<String, dynamic> json) {
//     print('Parsing JSON: $json');

//     String formatDate(dynamic date) {
//       if (date == null) return '';

//       DateTime? dateTime;
//       if (date is DateTime) {
//         dateTime = date;
//       } else if (date is String) {
//         try {
//           dateTime = DateTime.parse(date);
//         } catch (e) {
//           try {
//             dateTime = DateTime.parse(date.replaceAll('T', ' '));
//           } catch (e) {
//             print('Failed to parse date: $date, error: $e');
//             return '';
//           }
//         }
//       } else {
//         return '';
//       }

//       return "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}";
//     }

//     String? safeString(dynamic value, String fieldName) {
//       if (value == null || value is String) {
//         return value;
//       }
//       print(
//         'Warning: Unexpected type for $fieldName: ${value.runtimeType}, value: $value',
//       );
//       return null;
//     }

//     return LeaveRequest(
//       id: json['id'],
//       employeeName:
//           json['employee_id'] is List
//               ? json['employee_id'][1] ?? ''
//               : json['employee_id']?['name'] ??
//                   json['employee_name'] ??
//                   json['employee'] ??
//                   '',
//       startDate: formatDate(json['start_date']),
//       endDate: formatDate(json['end_date']),
//       reason: json['reason'] ?? '',
//       status: safeString(json['state'], 'state'),
//       leaveType: safeString(json['leave_type'], 'leave_type'),
//       halfDayType: safeString(json['half_day_type'], 'half_day_type'),
//       leaveSubType: safeString(json['leave_sub_type'], 'leave_sub_type'),
//     );
//   }

//   @override
//   String toString() {
//     return 'LeaveRequest(id: $id, employeeName: $employeeName, startDate: $startDate, endDate: $endDate, reason: $reason, status: $status, leaveType: $leaveType, halfDayType: $halfDayType, leaveSubType: $leaveSubType)';
//   }
// }
