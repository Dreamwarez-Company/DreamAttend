class Contract {
  final int id;
  final String name;
  final int? employeeId;
  final String employeeName;
  final String state;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final double wage;
  final String? schedulePay;
  final String? resourceCalendarName;
  final double? hra;
  final double? da;
  final double? travelAllowance;
  final double? mealAllowance;
  final double? medicalAllowance;
  final double? overtimeRate;
  final double? otherAllowance;
  final String? typeName;
  final String? structName;

  Contract({
    required this.id,
    required this.name,
    this.employeeId,
    required this.employeeName,
    required this.state,
    this.dateStart,
    this.dateEnd,
    required this.wage,
    this.schedulePay,
    this.resourceCalendarName,
    this.hra = 0.0,
    this.da = 0.0,
    this.travelAllowance = 0.0,
    this.mealAllowance = 0.0,
    this.medicalAllowance = 0.0,
    this.overtimeRate = 0.0,
    this.otherAllowance = 0.0,
    this.typeName,
    this.structName,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    // Debug print to check the raw employee data
    print('Raw employee_id from JSON: ${json['employee_id']}');
    print('Raw employee_name from JSON: ${json['employee_name']}');

    int? employeeIdValue;
    if (json['employee_id'] is List && json['employee_id'].length > 1) {
      employeeIdValue = json['employee_id'][0] as int?;
    } else if (json['employee_id'] is Map) {
      employeeIdValue = json['employee_id']['id'] as int?;
    } else if (json['employee_id'] is int) {
      employeeIdValue = json['employee_id'] as int;
    }

    String employeeNameValue = '';
    // Check employee_name first (from /api/hr_contracts/tree)
    if (json['employee_name'] != null && json['employee_name'] != false) {
      employeeNameValue = json['employee_name'].toString();
    }
    // Fallback to employee_id if employee_name is not available (from /api/hr_contracts/form)
    else if (json['employee_id'] != null) {
      if (json['employee_id'] is List && json['employee_id'].length > 1) {
        employeeNameValue = json['employee_id'][1] ?? '';
      } else if (json['employee_id'] is Map) {
        employeeNameValue = json['employee_id']['name'] ?? '';
      }
    }
    print('Parsed employeeName: $employeeNameValue');

    return Contract(
      id: json['id'],
      name: json['name'],
      employeeId: employeeIdValue,
      employeeName: employeeNameValue,
      state: json['state'] ?? 'draft',
      dateStart: json['date_start'] != null && json['date_start'] != false
          ? DateTime.tryParse(json['date_start'])
          : null,
      dateEnd: json['date_end'] != null && json['date_end'] != false
          ? DateTime.tryParse(json['date_end'])
          : null,
      wage: (json['wage'] as num?)?.toDouble() ?? 0.0,
      schedulePay: json['schedule_pay'],
      resourceCalendarName: json['resource_calendar_id'] != null &&
              json['resource_calendar_id'] is Map
          ? json['resource_calendar_id']['name']
          : null,
      hra: (json['hra'] as num?)?.toDouble(),
      da: (json['da'] as num?)?.toDouble(),
      travelAllowance: (json['travel_allowance'] as num?)?.toDouble(),
      mealAllowance: (json['meal_allowance'] as num?)?.toDouble(),
      medicalAllowance: (json['medical_allowance'] as num?)?.toDouble(),
      overtimeRate: (json['overtime_rate'] as num?)?.toDouble(),
      otherAllowance: (json['other_allowance'] as num?)?.toDouble(),
      typeName: json['type_id'] != null && json['type_id'] is Map
          ? json['type_id']['name']
          : null,
      structName: json['struct_id'] != null && json['struct_id'] is Map
          ? json['struct_id']['name']
          : null,
    );
  }
}
