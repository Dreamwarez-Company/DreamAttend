import 'package:flutter/material.dart';
import 'advance_pay.dart';
import 'contracts_page.dart';
import 'payslip_page.dart';

class PayrollPage extends StatefulWidget {
  const PayrollPage({super.key});

  @override
  State<PayrollPage> createState() => _PayrollPageState();
}

class _PayrollPageState extends State<PayrollPage> {
  bool _showConfigOptions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFe6f0fa),
                  Color(0xFFf7fafc),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Decorative Circles
          Positioned(
            top: -80,
            right: -80,
            child: _backgroundCircle(
                200, const Color(0xFF6b7280).withOpacity(0.1)),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _backgroundCircle(
                250, const Color(0xFF3b82f6).withOpacity(0.15)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  _buildHeaderCard(),
                  const SizedBox(height: 32),
                  _buildMenuButton(
                    context,
                    icon: Icons.receipt_long_rounded,
                    label: 'Payslips',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366f1), Color(0xFF4f46e5)],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PayslipPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Contracts',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10b981), Color(0xFF059669)],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ContractsPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildMenuButton(
                    context,
                    icon: Icons.payment,
                    label: 'Advance Pay',
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 139, 169, 65),
                        Color.fromARGB(255, 136, 185, 68)
                      ],
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdvancePayPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // _buildConfigDropdown(context),
                  AnimatedOpacity(
                    opacity: _showConfigOptions ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _showConfigOptions ? null : 0,
                      child: _showConfigOptions
                          ? const Column(
                              children: [
                                SizedBox(height: 10),
                                // _buildDropdownOption(
                                //   context,
                                //   label: 'Salary Rules',
                                //   onPressed: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder: (context) => SalaryRulePage(
                                //           configurationService:
                                //               ConfigurationService(),
                                //         ),
                                //       ),
                                //     );
                                //     setState(() {
                                //       _showConfigOptions = false;
                                //     });
                                //   },
                                // ),
                                SizedBox(height: 10),
                                // _buildDropdownOption(
                                //   context,
                                //   label: 'Salary Structure',
                                //   onPressed: () {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(
                                //         builder: (context) =>
                                //             SalaryStructurePage(
                                //           configurationService:
                                //               ConfigurationService(),
                                //         ),
                                //       ),
                                //     );
                                //     setState(() {
                                //       _showConfigOptions = false;
                                //     });
                                //   },
                                // ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 100),
                  Text(
                    // '© 2025 Payroll System (Dreamwarez)',
                    '© ${DateTime.now().year} Payroll System (Dreamwarez)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        // boxShadow: [],
                  boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 80,
            color: Color(0xFF1e3a8a),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payroll Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e3a8a),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Streamline payslips, contracts, and settings with ease.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onPressed,
  }) {
    // return GestureDetector(
    //   onTap: onPressed,
    //   child: AnimatedContainer(
    return Material(
  color: Colors.transparent,
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onPressed,
    child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildConfigDropdown(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showConfigOptions = !_showConfigOptions;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          // gradient: const LinearGradient(
          //   colors: [Color(0xFFf97316), Color(0xFFea580c)],
          // ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: const Row(
          children: [
            // const Icon(Icons.settings_suggest, size: 32, color: Colors.white),
            // const SizedBox(width: 20),
            // const Text(
            //   'Configuration',
            //   style: TextStyle(
            //     fontSize: 16,
            //     fontWeight: FontWeight.w500,
            //     color: Colors.white,
            //   ),
            // ),
            // const Spacer(),
            // Icon(
            //   _showConfigOptions
            //       ? Icons.arrow_drop_up_rounded
            //       : Icons.arrow_drop_down_rounded,
            //   size: 32,
            //   color: Colors.white,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownOption(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFFfb923c),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 52),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
