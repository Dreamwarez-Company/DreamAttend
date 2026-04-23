import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/attendance.dart';
import '/models/attendance_report.dart';
import 'api_service.dart';
import '/controller/app_constants.dart';

class AttendanceService {
  final ApiService _apiService = ApiService();
  String? _sessionId;

  /// Load the stored sessionId from SharedPreferences instead of re-login
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

  Future<void> markAttendance(String employeeName) async {
    await _ensureAuthenticated();
    final response = await _apiService.authenticatedPost(
      '/api/post/create-attendance',
      {'name': employeeName.trim()},
      sessionId: _sessionId!,
    );

    if (response.statusCode == 404) {
      throw Exception('Target URL not found: /api/post/create-attendance');
    } else if (response.statusCode == 500) {
      throw Exception(
          'Internal server error occurred while creating attendance');
    } else if (response.statusCode != 200) {
      throw Exception(
        'Create attendance failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> checkIn(Attendance attendance) async {
    await _ensureAuthenticated();
    // Validate sequence: Attendance must be created (daysPresent > 0)
    if (attendance.daysPresent == 0) {
      throw Exception('Please create an attendance record first.');
    }
    final response = await _apiService.authenticatedPost(
      AppConstants.checkInEndpoint,
      {
        'name': attendance.name.trim(),
        'checkIn': attendance.checkIn?.toIso8601String(),
      },
      sessionId: _sessionId!,
    );

    if (response.statusCode == 404) {
      throw Exception('Target URL not found: ${AppConstants.checkInEndpoint}');
    } else if (response.statusCode == 500) {
      throw Exception('Internal server error occurred during check-in');
    } else if (response.statusCode != 200) {
      throw Exception(
        'Check-in failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> checkOut(Attendance attendance) async {
    await _ensureAuthenticated();
    // Validate sequence: Must have checked in and lunch in completed
    if (attendance.checkIn == null) {
      throw Exception('Please check in before checking out.');
    }
    if (attendance.lunchOut != null && attendance.lunchIn == null) {
      throw Exception('Please complete lunch in before checking out.');
    }
    final response = await _apiService.authenticatedPost(
      AppConstants.checkOutEndpoint,
      {
        'name': attendance.name.trim(),
        'checkOut': attendance.checkOut?.toIso8601String(),
        'totalHours': attendance.totalHours,
      },
      sessionId: _sessionId!,
    );

    if (response.statusCode == 404) {
      throw Exception('Target URL not found: ${AppConstants.checkOutEndpoint}');
    } else if (response.statusCode == 500) {
      throw Exception('Internal server error occurred during check-out');
    } else if (response.statusCode != 200) {
      throw Exception(
        'Check-out failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> lunchIn(Attendance attendance) async {
    await _ensureAuthenticated();
    // Validate sequence: Must have checked in and lunch out
    if (attendance.checkIn == null) {
      throw Exception('Please check in before marking lunch in.');
    }
    if (attendance.lunchOut == null) {
      throw Exception('Please mark lunch out before marking lunch in.');
    }
    final response = await _apiService.authenticatedPost(
      AppConstants.lunchInEndpoint,
      {
        'name': attendance.name.trim(),
        'lunchIn': attendance.lunchIn?.toIso8601String(),
      },
      sessionId: _sessionId!,
    );

    if (response.statusCode == 404) {
      throw Exception('Target URL not found: ${AppConstants.lunchInEndpoint}');
    } else if (response.statusCode == 500) {
      throw Exception('Internal server error occurred during lunch-in');
    } else if (response.statusCode != 200) {
      throw Exception(
        'Lunch-in failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> lunchOut(Attendance attendance) async {
    await _ensureAuthenticated();
    // Validate sequence: Must have checked in
    if (attendance.checkIn == null) {
      throw Exception('Please check in before marking lunch out.');
    }
    final response = await _apiService.authenticatedPost(
      AppConstants.lunchOutEndpoint,
      {
        'name': attendance.name.trim(),
        'lunchOut': attendance.lunchOut?.toIso8601String(),
      },
      sessionId: _sessionId!,
    );

    if (response.statusCode == 404) {
      throw Exception('Target URL not found: ${AppConstants.lunchOutEndpoint}');
    } else if (response.statusCode == 500) {
      throw Exception('Internal server error occurred during lunch-out');
    } else if (response.statusCode != 200) {
      throw Exception(
        'Lunch-out failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Attendance>> fetchAttendance() async {
    await _ensureAuthenticated();
    const endpoint = AppConstants.getAttendanceEndpoint;

    final response = await _apiService.authenticatedPost(
      endpoint,
      {},
      sessionId: _sessionId!,
    );

    if (response.statusCode == 404) {
      throw Exception('Target URL not found: $endpoint');
    } else if (response.statusCode == 500) {
      throw Exception(
          'Internal server error occurred while fetching attendance');
    } else if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Attendance.fromJson(e)).toList();
      } else {
        throw Exception('Invalid response format: Expected List');
      }
    } else {
      throw Exception(
        'Failed to fetch attendance: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<AttendanceReport>> fetchAllEmployeesAttendanceReport({
    String? month,
    int? year,
    int? employeeId,
  }) async {
    await _ensureAuthenticated();
    const endpoint = AppConstants.attendanceReportEndpoint;

    // Prepare the POST body instead of query parameters
    final body = <String, dynamic>{};
    if (month != null) body['month'] = month;
    if (year != null) body['year'] = year;
    if (employeeId != null) body['employee_id'] = employeeId;

    try {
      final response = await _apiService.authenticatedPost(
        endpoint,
        body,
        sessionId: _sessionId!,
      );

      if (response.statusCode == 404) {
        throw Exception('Target URL not found: $endpoint');
      } else if (response.statusCode == 500) {
        throw Exception(
            'Internal server error occurred while fetching attendance report');
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => AttendanceReport.fromJson(e)).toList();
        } else {
          throw Exception('Invalid response format: Expected List');
        }
      } else {
        throw Exception(
          'Failed to fetch attendance report: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
