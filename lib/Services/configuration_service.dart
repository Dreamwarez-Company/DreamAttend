// import 'dart:convert';
// import '/controller/app_constants.dart';
// import '/models/salary_rule.dart';
// import '/models/salary_structure.dart';
// import '/services/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ConfigurationService {
//   final ApiService _apiService = ApiService();
//   String? _sessionId;

//   Future<void> _ensureAuthenticated() async {
//     if (_sessionId == null || _sessionId!.isEmpty) {
//       final prefs = await SharedPreferences.getInstance();
//       _sessionId = prefs.getString('sessionId');
//       if (_sessionId == null || _sessionId!.isEmpty) {
//         throw Exception('No valid session found. Please log in.');
//       }
//       print('Using stored sessionId: $_sessionId');
//     }
//   }

//   Future<List<SalaryRule>> fetchSalaryRules({
//     int limit = 100,
//     int offset = 0,
//     String domain = '[]',
//   }) async {
//     try {
//       await _ensureAuthenticated();
//       const endpoint = AppConstants.salaryRuleEndpoint;
//       final queryParams = {
//         'limit': limit.toString(),
//         'offset': offset.toString(),
//         'domain': domain,
//       };

//       final response = await _apiService.authenticatedGet(
//         endpoint,
//         queryParams: queryParams,
//         sessionId: _sessionId!,
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['status'] == 'success' && data['data'] is List) {
//           return (data['data'] as List)
//               .map((e) => SalaryRule.fromJson(e))
//               .toList();
//         } else {
//           throw Exception(
//               'Invalid response format: Expected success status with data List');
//         }
//       } else {
//         throw Exception(
//           'Failed to fetch salary rules: ${response.statusCode} - ${response.body}',
//         );
//       }
//     } catch (e) {
//       throw Exception('Error fetching salary rules: $e');
//     }
//   }

//   Future<List<SalaryStructure>> fetchSalaryStructures({
//     int limit = 100,
//     int offset = 0,
//     String domain = '[]',
//   }) async {
//     try {
//       await _ensureAuthenticated();
//       const endpoint = AppConstants.salaryStructureEndpoint;
//       final queryParams = {
//         'limit': limit.toString(),
//         'offset': offset.toString(),
//         'domain': domain,
//       };

//       final response = await _apiService.authenticatedGet(
//         endpoint,
//         queryParams: queryParams,
//         sessionId: _sessionId!,
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['status'] == 'success' && data['data'] is List) {
//           return (data['data'] as List)
//               .map((e) => SalaryStructure.fromJson(e))
//               .toList();
//         } else {
//           throw Exception(
//               'Invalid response format: Expected success status with data List');
//         }
//       } else {
//         throw Exception(
//           'Failed to fetch salary structures: ${response.statusCode} - ${response.body}',
//         );
//       }
//     } catch (e) {
//       throw Exception('Error fetching salary structures: $e');
//     }
//   }
// }
