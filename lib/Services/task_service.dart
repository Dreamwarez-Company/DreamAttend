import 'dart:convert';
import '/models/employee.dart';
import '/models/task_request.dart';
import '/controller/app_constants.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  final ApiService _apiService = ApiService();
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
        return (responseBody['tasks'] as List).map((e) {
          print(
            'Task: $e\n'
            'Start Date (raw): ${e['start_date']}, Deadline (raw): ${e['deadline']}, End Date (raw): ${e['end_date']}',
          );
          return TaskRequest.fromJson(e as Map<String, dynamic>);
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

