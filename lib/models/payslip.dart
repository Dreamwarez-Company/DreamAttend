// Updated payslip.dart
class Payslip {
  final int id;
  final String name;
  final String number;
  final String employeeName;
  final String state;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final Map<String, dynamic>? employeeId;
  final Map<String, dynamic>? structId;
  final Map<String, dynamic>? contractId;
  final Map<String, dynamic>? companyId;
  final bool paid;
  final String note;
  final bool creditNote;
  final Map<String, dynamic>? payslipRunId;
  final List<Map<String, dynamic>> workedDaysLineIds;
  final List<Map<String, dynamic>> inputLineIds;
  final List<Map<String, dynamic>> lineIds;
  final double advanceDeductionAmount;
  final double totalAdvancePay;
  final double remainingAdvanceBalance;

  Payslip({
    required this.id,
    required this.name,
    required this.number,
    required this.employeeName,
    required this.state,
    this.dateFrom,
    this.dateTo,
    this.employeeId,
    this.structId,
    this.contractId,
    this.companyId,
    required this.paid,
    required this.note,
    required this.creditNote,
    this.payslipRunId,
    required this.workedDaysLineIds,
    required this.inputLineIds,
    required this.lineIds,
    this.advanceDeductionAmount = 0.0,
    this.totalAdvancePay = 0.0,
    this.remainingAdvanceBalance = 0.0,
  });

  Payslip copyWith({
    int? id,
    String? name,
    String? number,
    String? employeeName,
    String? state,
    DateTime? dateFrom,
    DateTime? dateTo,
    Map<String, dynamic>? employeeId,
    Map<String, dynamic>? structId,
    Map<String, dynamic>? contractId,
    Map<String, dynamic>? companyId,
    bool? paid,
    String? note,
    bool? creditNote,
    Map<String, dynamic>? payslipRunId,
    List<Map<String, dynamic>>? workedDaysLineIds,
    List<Map<String, dynamic>>? inputLineIds,
    List<Map<String, dynamic>>? lineIds,
    double? advanceDeductionAmount,
    double? totalAdvancePay,
    double? remainingAdvanceBalance,
  }) {
    return Payslip(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      employeeName: employeeName ?? this.employeeName,
      state: state ?? this.state,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      employeeId: employeeId ?? this.employeeId,
      structId: structId ?? this.structId,
      contractId: contractId ?? this.contractId,
      companyId: companyId ?? this.companyId,
      paid: paid ?? this.paid,
      note: note ?? this.note,
      creditNote: creditNote ?? this.creditNote,
      payslipRunId: payslipRunId ?? this.payslipRunId,
      workedDaysLineIds: workedDaysLineIds ?? this.workedDaysLineIds,
      inputLineIds: inputLineIds ?? this.inputLineIds,
      lineIds: lineIds ?? this.lineIds,
      advanceDeductionAmount:
          advanceDeductionAmount ?? this.advanceDeductionAmount,
      totalAdvancePay: totalAdvancePay ?? this.totalAdvancePay,
      remainingAdvanceBalance:
          remainingAdvanceBalance ?? this.remainingAdvanceBalance,
    );
  }

  factory Payslip.fromJson(Map<String, dynamic> json) {
    final advancePayDetails =
        json['advance_pay_details'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['advance_pay_details'])
            : {};

    Map<String, dynamic>? normalizeRelation(dynamic value) {
      if (value is Map<String, dynamic>) {
        return Map<String, dynamic>.from(value);
      }
      if (value is int) {
        return {'id': value};
      }
      return null;
    }

    final normalizedEmployeeId = normalizeRelation(json['employee_id']);
    final normalizedStructId = normalizeRelation(json['struct_id']);
    final normalizedContractId = normalizeRelation(json['contract_id']);
    final normalizedCompanyId = normalizeRelation(json['company_id']);

    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Payslip(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      number: json['number'] ?? '',
      employeeName: json['employee_name'] ??
          (normalizedEmployeeId != null
              ? normalizedEmployeeId['name'] ?? ''
              : ''),
      state: json['state'] ?? '',
      dateFrom: json['date_from'] != null && json['date_from'] is String
          ? DateTime.tryParse(json['date_from'])
          : null,
      dateTo: json['date_to'] != null && json['date_to'] is String
          ? DateTime.tryParse(json['date_to'])
          : null,
      employeeId: normalizedEmployeeId,
      structId: normalizedStructId,
      contractId: normalizedContractId,
      companyId: normalizedCompanyId,
      paid: json['paid'] ?? false,
      note: json['note'] ?? '',
      creditNote: json['credit_note'] ?? false,
      payslipRunId: json['payslip_run_id'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payslip_run_id'])
          : null,
      workedDaysLineIds: json['worked_days_line_ids'] is List
          ? List<Map<String, dynamic>>.from(json['worked_days_line_ids']
              .map((x) => Map<String, dynamic>.from(x)))
          : [],
      inputLineIds: json['input_line_ids'] is List
          ? List<Map<String, dynamic>>.from(
              json['input_line_ids'].map((x) => Map<String, dynamic>.from(x)))
          : [],
      lineIds: json['line_ids'] is List
          ? List<Map<String, dynamic>>.from(
              json['line_ids'].map((x) => Map<String, dynamic>.from(x)))
          : [],
      advanceDeductionAmount: parseDouble(
        advancePayDetails['advance_deduction_amount'] ??
            json['advance_deduction_amount'],
      ),
      totalAdvancePay: parseDouble(
        advancePayDetails['total_advance_pay'] ?? json['total_advance_pay'],
      ),
      remainingAdvanceBalance: parseDouble(
        advancePayDetails['remaining_advance_balance'] ??
            json['remaining_advance_balance'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'employee_name': employeeName,
      'state': state,
      'date_from': dateFrom?.toIso8601String(),
      'date_to': dateTo?.toIso8601String(),
      'employee_id': employeeId,
      'struct_id': structId,
      'contract_id': contractId,
      'company_id': companyId,
      'paid': paid,
      'note': note,
      'credit_note': creditNote,
      'payslip_run_id': payslipRunId,
      'worked_days_line_ids': workedDaysLineIds,
      'input_line_ids': inputLineIds,
      'line_ids': lineIds,
      'advance_pay_details': {
        'advance_deduction_amount': advanceDeductionAmount,
        'total_advance_pay': totalAdvancePay,
        'remaining_advance_balance': remainingAdvanceBalance,
      },
    };
  }
}
