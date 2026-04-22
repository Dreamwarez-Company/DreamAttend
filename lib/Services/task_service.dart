import 'dart:convert';
import '/models/task_request.dart';
import '/models/employee.dart';
import '/controller/app_constants.dart';
import 'api_service.dart';
import 'employee_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  final ApiService _apiService = ApiService();
  final EmployeeService _employeeService = EmployeeService();
  String? _sessionId;

  /// Load the stored sessionId from SharedPreferences
  Future<void> _ensureAuthenticated() async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final storedSessionId = prefs.getString('sessionId');

      if (storedSessionId == null || storedSessionId.isEmpty) {
        throw Exception('No active session. Please log in again.');
      }

      _sessionId = storedSessionId;
    }
  }

  Future<List<Employee>> fetchAssignableEmployees() async {
    await _ensureAuthenticated();
    final response = await _apiService.authenticatedGet(
      AppConstants.assignableEmployeesEndpoint,
      queryParams: {'db': AppConstants.databaseName},
      sessionId: _sessionId!,
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Assignable Employees API Response: $responseBody');
      if (responseBody is Map && responseBody.containsKey('employees')) {
        return (responseBody['employees'] as List)
            .map((e) => Employee.fromJson(e))
            .toList();
      }
      throw Exception(
          'Invalid response format: expected object with "employees" key');
    }
    throw Exception(
        'Failed to fetch assignable employees: ${response.statusCode} ${response.body}');
  }

  Future<int> createTask(TaskRequest task) async {
    await _ensureAuthenticated();
    final response = await _apiService.authenticatedPost(
      AppConstants.taskEndpoint,
      {
        'taskName': task.name,
        'assigned_to': int.parse(task.employeeId),
        'deadline': task.deadline,
        'startDate': task.startDate,
        'description': task.description,
        'db': AppConstants.databaseName,
      },
      sessionId: _sessionId!,
    );

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody['task_id']?.toInt() ?? 0;
    }
    throw Exception(
        'Task creation failed: ${response.statusCode} ${response.body}');
  }

  Future<List<TaskRequest>> fetchTasks({String? employeeName}) async {
    await _ensureAuthenticated();
    final queryParams = {'db': AppConstants.databaseName};
    if (employeeName != null && employeeName.isNotEmpty) {
      queryParams['name'] = employeeName;
    }

    final response = await _apiService.authenticatedGet(
      AppConstants.getTaskEndpoint,
      queryParams: queryParams,
      sessionId: _sessionId!,
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('API Response: $responseBody');
      if (responseBody is Map && responseBody.containsKey('tasks')) {
        final employees = await _employeeService.getEmployees();
        Map<int, String> employeeIdToName = {
          for (var emp in employees) emp.id: emp.name,
        };
        Map<String, String> employeeNameToId = {
          for (var emp in employees) emp.name: emp.id.toString(),
        };
        print('Employee ID to Name Map: $employeeIdToName');
        print('Employee Name to ID Map: $employeeNameToId');

        return (responseBody['tasks'] as List).map((e) {
          String assignedByName = e['assigned_by']?.toString() ?? 'Unknown';
          String assignedToName = e['employee_name']?.toString() ?? 'Unknown';

          String employeeIdStr = employeeNameToId[assignedToName] ?? '0';
          String assignByStr = employeeNameToId[assignedByName] ?? '0';

          print(
            'Task: $e\n'
            'Employee ID: $employeeIdStr, Assign By: $assignByStr\n'
            'Assigned To Name: $assignedToName, Assigned By Name: $assignedByName\n'
            'Start Date (raw): ${e['start_date']}, Deadline (raw): ${e['deadline']}, End Date (raw): ${e['end_date']}',
          );

          return TaskRequest(
            taskId: e['task_id']?.toInt() ?? 0,
            employeeId: employeeIdStr,
            assignBy: assignByStr,
            name: e['task_name']?.toString() ?? e['name']?.toString() ?? '',
            startDate: e['start_date']?.toString(),
            endDate: e['end_date']?.toString(),
            deadline: e['deadline']?.toString() ?? '',
            description: e['description']?.toString(),
            state: e['state']?.toString(),
            assignedToName: assignedToName,
            assignedByName: assignedByName,
          );
        }).toList();
      }
      throw Exception(
          'Invalid response format: expected object with "tasks" key');
    }
    throw Exception(
        'Failed to fetch tasks: ${response.statusCode} ${response.body}');
  }

  Future<void> updateTaskState(int taskId, String state) async {
    await _ensureAuthenticated();
    final endpoint = state == 'in_progress'
        ? AppConstants.updateTaskInProgressEndpoint
        : AppConstants.updateTaskDoneEndpoint;
    final response = await _apiService.authenticatedPost(
      endpoint,
      {
        'task_id': taskId,
        'db': AppConstants.databaseName,
      },
      sessionId: _sessionId!,
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['success'] == true) {
        return;
      }
      throw Exception('Failed to update task state: ${responseBody['error']}');
    }
    throw Exception(
        'Failed to update task state: ${response.statusCode} ${response.body}');
  }
}

