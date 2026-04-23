
import 'dart:convert';
import 'dart:developer' as developer;
import '/models/payslip.dart';
import '/services/api_service.dart';
import '/controller/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PayslipService {
  final ApiService _apiService = ApiService();
  String? _sessionId;

  Map<String, dynamic> _unwrapResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      final result = data['result'];
      if (result is Map<String, dynamic>) {
        return result;
      }
      return data;
    }
    return {};
  }

  Map<String, dynamic>? _extractPayslipMap(Map<String, dynamic> payload) {
    final payslipId = (payload['payslip_id'] as num?)?.toInt() ??
        (payload['id'] as num?)?.toInt();

    final details = payload['payslip_details'];
    if (details is Map<String, dynamic>) {
      final mergedDetails = Map<String, dynamic>.from(details);
      if (mergedDetails['id'] == null && payslipId != null) {
        mergedDetails['id'] = payslipId;
      }
      return mergedDetails;
    }

    final candidates = [
      payload['data'],
      payload['payslip'],
      payload,
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic> && candidate['id'] != null) {
        return Map<String, dynamic>.from(candidate);
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _mapComputedLines(dynamic rawLines) {
    if (rawLines is! List) {
      return [];
    }

    return rawLines
        .whereType<Map>()
        .map(
          (x) => {
            'code': x['code'],
            'name': x['name'],
            'quantity': x['quantity'],
            'amount': x['amount'],
            'total': x['total'],
            'category_id': x['category_id'],
            'salary_rule_id': x['salary_rule_id'],
          },
        )
        .toList();
  }

  Future<void> _ensureAuthenticated() async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('sessionId');
      if (_sessionId == null || _sessionId!.isEmpty) {
        throw Exception('No valid session found. Please log in.');
      }
      developer.log('Using stored sessionId: $_sessionId',
          name: 'PayslipService');
    }
  }

  Future<List<Payslip>> fetchPayslips() async {
    try {
      await _ensureAuthenticated();
      const endpoint = AppConstants.getPayslipsEndpoint;
      developer.log('Fetching payslips from endpoint: $endpoint',
          name: 'PayslipService');

      final response = await _apiService.authenticatedGet(
        endpoint,
        sessionId: _sessionId!,
      );

      developer.log(
          'Fetch payslips response: statusCode=${response.statusCode}',
          name: 'PayslipService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          developer.log(
              'Payslips fetched successfully, count: ${data['data'].length}',
              name: 'PayslipService');
          return data['data'].map<Payslip>((e) => Payslip.fromJson(e)).toList();
        } else {
          developer.log(
              'Invalid response format: ${data['message'] ?? 'Expected List'}',
              name: 'PayslipService');
          throw Exception(
              'Invalid response format: ${data['message'] ?? 'Expected List'}');
        }
      } else {
        developer.log(
            'Failed to fetch payslips: ${response.statusCode} - ${response.body}',
            name: 'PayslipService');
        throw Exception(
            'Failed to fetch payslips: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching payslips: $e',
          name: 'PayslipService', error: e);
      throw Exception('Error fetching payslips: $e');
    }
  }

  Future<Payslip> fetchPayslipDetails(int payslipId) async {
    try {
      await _ensureAuthenticated();
      final endpoint = '${AppConstants.getPayslipDetailsEndpoint}/$payslipId';
      developer.log(
          'Fetching payslip details for ID: $payslipId from endpoint: $endpoint',
          name: 'PayslipService');

      final response = await _apiService.authenticatedGet(
        endpoint,
        sessionId: _sessionId!,
      );

      developer.log(
          'Fetch payslip details response: statusCode=${response.statusCode}',
          name: 'PayslipService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          developer.log(
              'Payslip details fetched successfully for ID: $payslipId',
              name: 'PayslipService');
          return Payslip.fromJson(data['data']);
        } else {
          developer.log(
              'Invalid response format: ${data['message'] ?? 'Expected data object'}',
              name: 'PayslipService');
          throw Exception(
              'Invalid response format: ${data['message'] ?? 'Expected data object'}');
        }
      } else {
        developer.log(
            'Failed to fetch payslip details: ${response.statusCode} - ${response.body}',
            name: 'PayslipService');
        throw Exception(
            'Failed to fetch payslip details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching payslip details: $e',
          name: 'PayslipService', error: e);
      throw Exception('Error fetching payslip details: $e');
    }
  }

  Future<Map<String, dynamic>> fetchPayslipWorkedDaysInputs(
      int payslipId) async {
    try {
      await _ensureAuthenticated();
      const endpoint = AppConstants.getPayslipWorkedDaysEndpoint;
      developer.log(
          'Fetching payslip worked days and inputs for ID: $payslipId from endpoint: $endpoint',
          name: 'PayslipService');

      final payload = {'payslip_id': payslipId};

      final response = await _apiService.authenticatedPost(
        endpoint,
        payload,
        sessionId: _sessionId!,
      );

      developer.log(
          'Fetch payslip worked days/inputs response: statusCode=${response.statusCode}',
          name: 'PayslipService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          developer.log(
              'Payslip worked days and inputs fetched successfully for ID: $payslipId',
              name: 'PayslipService');
          return {
            'worked_days': data['worked_days'] ?? [],
            'inputs': data['inputs'] ?? [],
            'employee': data['employee'] ?? '',
            'period': data['period'] ?? '',
          };
        } else {
          developer.log(
              'Failed to fetch payslip details: ${data['error'] ?? 'Unknown error'}',
              name: 'PayslipService');
          throw Exception(data['error'] ?? 'Failed to fetch payslip details');
        }
      } else {
        developer.log(
            'Failed to fetch payslip details: ${response.statusCode} - ${response.body}',
            name: 'PayslipService');
        throw Exception(
            'Failed to fetch payslip details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching payslip details: $e',
          name: 'PayslipService', error: e);
      throw Exception('Error fetching payslip details: $e');
    }
  }

  Future<Payslip> createPayslip({
    required int employeeId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required int contractId,
    int? structId,
    String state = 'draft',
    String note = '',
    double? advanceDeductionAmount,
  }) async {
    try {
      await _ensureAuthenticated();
      const endpoint = AppConstants.createPayslipEndpoint;
      final payload = {
        'employee_id': employeeId,
        'date_from': dateFrom.toIso8601String().split('T')[0],
        'date_to': dateTo.toIso8601String().split('T')[0],
        'contract_id': contractId,
        'state': state,
        'note': note,
        'name': '',
        if (structId != null) 'struct_id': structId,
        if (advanceDeductionAmount != null)
          'advance_pay_details': {
            'advance_deduction_amount': advanceDeductionAmount,
          },
      };

      developer.log('Creating payslip with payload: ${jsonEncode(payload)}',
          name: 'PayslipService');

      final response = await _apiService.authenticatedPost(
        endpoint,
        payload,
        sessionId: _sessionId!,
      );

      developer.log(
          'Create payslip response: statusCode=${response.statusCode}',
          name: 'PayslipService');
      developer.log('Create payslip response body: ${response.body}',
          name: 'PayslipService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payload = _unwrapResult(data);
        final isSuccess = data['status'] == 'success' ||
            data['success'] == true ||
            payload['status'] == 'success' ||
            payload['success'] == true;

        if (isSuccess) {
          final payslipMap = _extractPayslipMap(payload) ?? _extractPayslipMap(data);

          if (payslipMap != null) {
            final payslip = Payslip.fromJson(payslipMap);
            developer.log(
                'Payslip created successfully: ID=${payslip.id}, Employee=${payslip.employeeName}, AdvanceDeduction=${payslip.advanceDeductionAmount}',
                name: 'PayslipService');
            return payslip;
          }

          final payslipId = (payload['id'] as num?)?.toInt() ??
              (data['id'] as num?)?.toInt();
          if (payslipId != null) {
            developer.log(
                'Create response succeeded without full payslip details, fetching payslip ID=$payslipId',
                name: 'PayslipService');
            return await fetchPayslipDetails(payslipId);
          }

          final payslips = await fetchPayslips();
          final matchingPayslips = payslips.where((payslip) {
            final currentEmployeeId = payslip.employeeId?['id'] as int?;
            final currentContractId = payslip.contractId?['id'] as int?;
            final fromMatches = payslip.dateFrom != null &&
                payslip.dateFrom!.year == dateFrom.year &&
                payslip.dateFrom!.month == dateFrom.month &&
                payslip.dateFrom!.day == dateFrom.day;
            final toMatches = payslip.dateTo != null &&
                payslip.dateTo!.year == dateTo.year &&
                payslip.dateTo!.month == dateTo.month &&
                payslip.dateTo!.day == dateTo.day;
            return currentEmployeeId == employeeId &&
                currentContractId == contractId &&
                fromMatches &&
                toMatches;
          }).toList();

          if (matchingPayslips.isNotEmpty) {
            matchingPayslips.sort((a, b) => b.id.compareTo(a.id));
            final payslip = matchingPayslips.first;
            developer.log(
                'Create response succeeded without details, resolved created payslip from list: ID=${payslip.id}',
                name: 'PayslipService');
            return payslip;
          }

          developer.log(
              'Create payslip succeeded but response did not include enough data to identify the created payslip',
              name: 'PayslipService');
          throw Exception(
              payload['message'] ?? data['message'] ?? 'Payslip created but response was incomplete');
        } else {
          developer.log(
              'Failed to create payslip: ${payload['message'] ?? data['message'] ?? 'Unknown error'}',
              name: 'PayslipService');
          throw Exception(
              payload['message'] ?? data['message'] ?? 'Failed to create payslip');
        }
      } else {
        final data = jsonDecode(response.body);
        developer.log(
            'Failed to create payslip: ${response.statusCode} - ${data['message'] ?? response.body}',
            name: 'PayslipService');
        throw Exception(
            'Failed to create payslip: ${response.statusCode} - ${data['message'] ?? response.body}');
      }
    } catch (e) {
      developer.log('Error creating payslip: $e',
          name: 'PayslipService', error: e);
      throw Exception('Error creating payslip: $e');
    }
  }

  Future<List<Map<String, dynamic>>> computePayslipSheet(int payslipId) async {
    try {
      await _ensureAuthenticated();
      const endpoint = AppConstants.computePayslipEndpoint;
      final payload = {'payslip_id': payslipId};

      developer.log(
          'Computing payslip sheet for ID: $payslipId with payload: ${jsonEncode(payload)}',
          name: 'PayslipService');

      final response = await _apiService.authenticatedPost(
        endpoint,
        payload,
        sessionId: _sessionId!,
      );

      developer.log(
          'Compute payslip sheet response: statusCode=${response.statusCode}',
          name: 'PayslipService');
      developer.log('Compute payslip sheet response body: ${response.body}',
          name: 'PayslipService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payload = data['result'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['result'])
            : Map<String, dynamic>.from(data);

        if (payload['status'] == 'success') {
          var computedLines = _mapComputedLines(payload['line_ids']);

          if (computedLines.isEmpty &&
              payload['data'] is Map<String, dynamic>) {
            computedLines =
                _mapComputedLines((payload['data'] as Map<String, dynamic>)['line_ids']);
          }

          if (computedLines.isEmpty &&
              payload['payslip_details'] is Map<String, dynamic>) {
            computedLines = _mapComputedLines(
              (payload['payslip_details'] as Map<String, dynamic>)['line_ids'],
            );
          }

          if (computedLines.isEmpty) {
            developer.log(
                'Compute response did not include lines, fetching updated payslip details for ID: $payslipId',
                name: 'PayslipService');
            final refreshedPayslip = await fetchPayslipDetails(payslipId);
            computedLines = refreshedPayslip.lineIds;
          }

          developer.log(
              'Payslip sheet computed successfully for ID: $payslipId, lines: ${computedLines.length}',
              name: 'PayslipService');
          return computedLines;
        } else {
          developer.log(
              'Failed to compute payslip sheet: ${payload['message'] ?? 'No lines provided'}',
              name: 'PayslipService');
          throw Exception(
              payload['message'] ?? 'Failed to compute payslip sheet');
        }
      } else {
        final data = jsonDecode(response.body);
        final payload = data['result'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['result'])
            : Map<String, dynamic>.from(data);
        developer.log(
            'Failed to compute payslip sheet: ${response.statusCode} - ${payload['message'] ?? response.body}',
            name: 'PayslipService');
        if (payload['status'] == 'error') {
          throw Exception(
              payload['message'] ?? 'Failed to compute payslip sheet');
        } else {
          throw Exception(
              'Unexpected response: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      developer.log('Error computing payslip sheet: $e',
          name: 'PayslipService', error: e);
      if (e.toString().contains('Payslip must be in Draft or Waiting state')) {
        throw Exception('Payslip must be in Draft or Waiting state to compute');
      }
      throw Exception('Error computing payslip sheet: $e');
    }
  }

  Future<void> confirmPayslip(int payslipId) async {
    try {
      await _ensureAuthenticated();
      const endpoint = AppConstants.confirmPayslipEndpoint;
      final payload = {'payslip_id': payslipId};

      developer.log(
          'Confirming payslip for ID: $payslipId with payload: ${jsonEncode(payload)}',
          name: 'PayslipService');

      final response = await _apiService.authenticatedPost(
        endpoint,
        payload,
        sessionId: _sessionId!,
      );

      developer.log(
          'Confirm payslip response: statusCode=${response.statusCode}',
          name: 'PayslipService');
      developer.log('Confirm payslip response body: ${response.body}',
          name: 'PayslipService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responsePayload = data['result'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['result'])
            : Map<String, dynamic>.from(data);

        if (responsePayload['status'] == 'success') {
          developer.log('Payslip confirmed successfully for ID: $payslipId',
              name: 'PayslipService');
          return;
        } else {
          developer.log(
              'Failed to confirm payslip: ${responsePayload['message'] ?? 'No details provided'}',
              name: 'PayslipService');
          throw Exception(
              responsePayload['message'] ?? 'Failed to confirm payslip');
        }
      } else {
        final data = jsonDecode(response.body);
        final responsePayload = data['result'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['result'])
            : Map<String, dynamic>.from(data);
        String errorMessage;
        switch (response.statusCode) {
          case 400:
            errorMessage =
                responsePayload['message'] ?? 'Invalid request payload';
            break;
          case 403:
            errorMessage = responsePayload['message'] ?? 'Permission denied';
            break;
          case 404:
            errorMessage = responsePayload['message'] ?? 'Payslip not found';
            break;
          default:
            errorMessage =
                responsePayload['message'] ?? 'Failed to confirm payslip';
        }
        developer.log(
            'Failed to confirm payslip: ${response.statusCode} - $errorMessage',
            name: 'PayslipService');

        final refreshedPayslip = await fetchPayslipDetails(payslipId);
        if (refreshedPayslip.state != 'draft' &&
            refreshedPayslip.state != 'verify') {
          developer.log(
              'Payslip $payslipId is already confirmed on server despite error response.',
              name: 'PayslipService');
          return;
        }

        throw Exception(
            'Failed to confirm payslip: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      try {
        final refreshedPayslip = await fetchPayslipDetails(payslipId);
        if (refreshedPayslip.state != 'draft' &&
            refreshedPayslip.state != 'verify') {
          developer.log(
              'Payslip $payslipId confirmed on server after exception during confirm.',
              name: 'PayslipService');
          return;
        }
      } catch (_) {}

      developer.log('Error confirming payslip: $e',
          name: 'PayslipService', error: e);
      throw Exception('Error confirming payslip: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchContracts(int employeeId) async {
    try {
      await _ensureAuthenticated();
      final endpoint =
          '${AppConstants.getContractsEndpoint}?employee_id=$employeeId';
      developer.log(
          'Fetching contracts for employee ID: $employeeId from endpoint: $endpoint',
          name: 'PayslipService');

      final response = await _apiService.authenticatedGet(
        endpoint,
        sessionId: _sessionId!,
      );

      developer.log(
          'Fetch contracts response: statusCode=${response.statusCode}',
          name: 'PayslipService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          developer.log(
              'Contracts fetched successfully, count: ${data['data'].length}',
              name: 'PayslipService');
          return List<Map<String, dynamic>>.from(
              data['data'].map((x) => Map<String, dynamic>.from(x)));
        } else {
          developer.log(
              'Invalid response format: ${data['message'] ?? 'Expected List'}',
              name: 'PayslipService');
          throw Exception(
              data['message'] ?? 'Invalid response format: Expected List');
        }
      } else {
        developer.log(
            'Failed to fetch contracts: ${response.statusCode} - ${response.body}',
            name: 'PayslipService');
        throw Exception(
            'Failed to fetch contracts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching contracts: $e',
          name: 'PayslipService', error: e);
      throw Exception('Error fetching contracts: $e');
    }
  }
}
