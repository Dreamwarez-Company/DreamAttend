import 'dart:convert';
import '/models/contract_model.dart';
import '/controller/app_constants.dart';
import '/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContractService {
  final ApiService _apiService = ApiService();
  String? _sessionId;

  Future<void> _ensureAuthenticated() async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      _sessionId = prefs.getString('sessionId');
      if (_sessionId == null || _sessionId!.isEmpty) {
        throw Exception('No valid session found. Please log in.');
      }
      print('Using stored sessionId: $_sessionId');
    }
  }

  Future<List<Contract>> getContracts() async {
    await _ensureAuthenticated();
    final response = await _apiService.authenticatedGet(
      AppConstants.getContractsEndpoint,
      sessionId: _sessionId!,
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          final contracts = (jsonData['data'] as List)
              .map((item) => Contract.fromJson(item))
              .toList();
          return contracts;
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch contracts');
        }
      } catch (e) {
        throw Exception('Invalid JSON response: ${e.toString()}');
      }
    } else {
      throw Exception(
          'Failed to fetch contracts: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Contract> getContractDetails(int contractId) async {
    await _ensureAuthenticated();
    final response = await _apiService.authenticatedGet(
      '${AppConstants.getContractDetailsEndpoint}/$contractId',
      sessionId: _sessionId!,
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          return Contract.fromJson(jsonData['data']);
        } else {
          throw Exception(
              jsonData['message'] ?? 'Failed to fetch contract details');
        }
      } catch (e) {
        throw Exception('Invalid JSON response: ${e.toString()}');
      }
    } else {
      throw Exception(
          'Failed to fetch contract details: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createContract(
      Map<String, dynamic> contractData) async {
    await _ensureAuthenticated();

    try {
      final response = await _apiService.authenticatedPost(
        AppConstants.createContractEndpoint,
        contractData,
        sessionId: _sessionId!,
      );

      final jsonData = json.decode(response.body);
      final normalizedData = _unwrapResult(jsonData);
      final isSuccess = jsonData['status'] == 'success' ||
          jsonData['success'] == true ||
          normalizedData['status'] == 'success' ||
          normalizedData['success'] == true;

      if (response.statusCode == 200 && isSuccess) {
        return normalizedData;
      }

      throw Exception(
        normalizedData['message'] ??
            normalizedData['error'] ??
            jsonData['message'] ??
            jsonData['error'] ??
            'Failed to create contract',
      );
    } catch (e) {
      throw Exception('Error creating contract: $e');
    }
  }

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

  Future<void> setContractRunning(int contractId) async {
    await _ensureAuthenticated();
    final response = await _apiService.authenticatedPost(
      '/api/hr_contract/set_running',
      {'contract_id': contractId},
      sessionId: _sessionId!,
    );

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        final normalizedData = _unwrapResult(jsonData);
        final isSuccess = jsonData['status'] == 'success' ||
            jsonData['success'] == true ||
            normalizedData['status'] == 'success' ||
            normalizedData['success'] == true;

        if (isSuccess) {
          return;
        }

        throw Exception(
          normalizedData['message'] ??
              normalizedData['error'] ??
              jsonData['message'] ??
              jsonData['error'] ??
              'Failed to set contract to running',
        );
      } on FormatException catch (e) {
        throw Exception('Invalid JSON response: ${e.toString()}');
      }
    } else {
      throw Exception(
          'Failed to set contract to running: ${response.statusCode} - ${response.body}');
    }
  }
}
