import 'package:intl/intl.dart';

class TaskRequest {
  final int taskId;
  final String employeeId;
  final String assignBy;
  final String name;
  final String? startDate;
  final String? endDate;
  final String deadline;
  final String? description;
  final String? state;
  final String? assignedToName;
  final String? assignedByName;

  TaskRequest({
    required this.taskId,
    required this.employeeId,
    required this.assignBy,
    required this.name,
    this.startDate,
    this.endDate,
    required this.deadline,
    this.description,
    this.state,
    this.assignedToName,
    this.assignedByName,
  });

  factory TaskRequest.fromJson(Map<String, dynamic> json) {
    String? parseDate(dynamic date) {
      if (date == null || date == false || date == 'False') {
        print('Invalid date value received: $date');
        return null;
      }
      try {
        if (date is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
          final parsedDate = DateTime.parse(date);
          return DateFormat('yyyy-MM-dd').format(parsedDate);
        }
      } catch (e) {
        print('Error parsing date: $date, error: $e');
      }
      return null;
    }

    return TaskRequest(
      taskId: json['task_id']?.toInt() ?? 0,
      employeeId:
          json['employee_id']?.toString() ??
          json['assigned_to']?.toString() ??
          '0',
      assignBy:
          json['assign_by']?.toString() ??
          json['assigned_by']?.toString() ??
          '0',
      name: json['task_name']?.toString() ?? json['name']?.toString() ?? '',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      deadline: parseDate(json['deadline']) ?? '',
      description: json['description']?.toString(),
      state: json['state']?.toString(),
      assignedToName:
          json['employee_name']?.toString() ??
          json['assigned_to_name']?.toString(),
      assignedByName:
          json['assigned_by']?.toString() ??
          json['assigned_by_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      'assigned_to': assignedToName,
      'assigned_by': assignBy,
      'taskName': name,
      'start_date': startDate,
      'deadline': deadline,
      'description': description,
      'state': state ?? 'pending',
    };
  }

  TaskRequest copyWith({
    int? taskId,
    String? employeeId,
    String? assignBy,
    String? name,
    String? startDate,
    String? endDate,
    String? deadline,
    String? description,
    String? state,
    String? assignedToName,
    String? assignedByName,
  }) {
    return TaskRequest(
      taskId: taskId ?? this.taskId,
      employeeId: employeeId ?? this.employeeId,
      assignBy: assignBy ?? this.assignBy,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      state: state ?? this.state,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedByName: assignedByName ?? this.assignedByName,
    );
  }

  String get formattedStartDate => startDate ?? 'N/A';
  String get formattedEndDate => endDate ?? 'N/A';
  String get formattedDeadline => deadline.isNotEmpty ? deadline : 'N/A';

  String formattedState(String? state) {
    if (state == null) return 'Pending';
    switch (state.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'done':
        return 'Done';
      default:
        return state;
    }
  }
}
