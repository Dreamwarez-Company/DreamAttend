import 'package:flutter/material.dart';
import '/services/configuration_service.dart';
import '/models/salary_structure.dart';
import 'utils/app_layout.dart';

class SalaryStructurePage extends StatefulWidget {
  final ConfigurationService configurationService;

  const SalaryStructurePage({super.key, required this.configurationService});

  @override
  State<SalaryStructurePage> createState() => _SalaryStructurePageState();
}

class _SalaryStructurePageState extends State<SalaryStructurePage> {
  List<SalaryStructure> _salaryStructures = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSalaryStructures();
  }

  Future<void> _fetchSalaryStructures() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final salaryStructures =
          await widget.configurationService.fetchSalaryStructures();
      setState(() {
        _salaryStructures = salaryStructures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      errorSnackBar('Error', 'Error fetching salary structures: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Structures'),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_salaryStructures.isNotEmpty) ...[
              const Text(
                'Salary Structures',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 7, 56, 80),
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _salaryStructures.length,
                itemBuilder: (context, index) {
                  final structure = _salaryStructures[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(structure.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${structure.id}'),
                          if (structure.code != null)
                            Text('Code: ${structure.code}'),
                          if (structure.companyId != null)
                            Text(
                                'Company: ${structure.companyId!['name'] ?? 'N/A'}'),
                          if (structure.ruleIds.isNotEmpty)
                            Text('Rules: ${structure.ruleIds.length}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            if (!_isLoading && _salaryStructures.isEmpty)
              const Center(
                child: Text(
                  'No salary structures found.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
