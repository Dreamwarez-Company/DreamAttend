import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';
import 'Services/api_service.dart';
import 'attendance_page.dart';
import 'apply_leave.dart';
import 'task.dart';
import 'payroll.dart';
import 'holidays.dart';
import 'user_profile.dart';
import 'employee_page.dart';
import 'utils/app_layout.dart';

/// Professional Color Palette
class AppColors {
  static const Color primaryBlue =
      Color(0xFF0B4A5E); // Darker, more professional blue
  static const Color accentTeal = Color(0xFF00897B); // Modern teal accent
  static const Color lightBackground = Color(0xFFF8FAFC); // Softer background
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF2D3748); // Darker text
  static const Color textLight = Color(0xFF718096); // Lighter text
  static const Color successGreen = Color(0xFF38A169);
  static const Color warningOrange = Color(0xFFED8936);
}

class HomePage extends StatefulWidget {
  final String name;
  final String employeeId;
  final int numericId;
  final List<String> groups;
  final String address;
  final String mobile;
  final String jobTitle;
  final String? image;

  const HomePage({
    super.key,
    required this.name,
    required this.employeeId,
    required this.numericId,
    required this.groups,
    required this.address,
    required this.mobile,
    required this.jobTitle,
    this.image,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _gridAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _gridAnimation;

  final Upgrader _upgrader = Upgrader(
    debugDisplayAlways: false,
    debugLogging: true,
    showLater: false,
    canDismissDialog: false,
  );

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    _gridAnimation = CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _gridAnimationController.forward();
    });

    // Check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString('sessionId');
    if (sessionId == null || sessionId.isEmpty) {
      return false;
    }

    return ApiService().validateStoredSession();
  }

  void _navigateToPage(BuildContext context, Widget page) async {
    try {
      if (await _isSessionValid()) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => page,
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
      } else {
        _showSnackBar('Session expired. Please log in again.', Colors.red);
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showSnackBar('Error navigating: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    showStatusSnackBar(
      message,
      color: backgroundColor,
      duration: const Duration(seconds: 4),
    );
  }

  void _openUserProfile() {
    _navigateToPage(
      context,
      UserProfile(
        numericId: widget.numericId,
        jobTitle: widget.jobTitle,
        name: widget.name,
        address: widget.address,
        mobile: widget.mobile,
      ),
    );
  }

  Future<void> _checkForUpdate(BuildContext context) async {
    final upgrader = _upgrader;
    await upgrader.initialize();

    String? storeVersion = upgrader.currentAppStoreVersion();
    String? installedVersion = upgrader.currentInstalledVersion();

    if (upgrader.shouldDisplayUpgrade()) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentMaterialBanner();

      messenger.showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.accentTeal.withOpacity(0.9),
          content: Text(
            'Update available! New: v$storeVersion (Current: v$installedVersion)',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
          leading: const Icon(Icons.system_update_alt, color: Colors.white),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                upgrader.onUserUpdated(context, true);
              },
              child: const Text(
                'UPDATE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      Future.delayed(const Duration(seconds: 10), () {
        messenger.hideCurrentMaterialBanner();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage: groups = ${widget.groups}');
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          _buildProfessionalAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildWelcomeHeader(),
                const SizedBox(height: 20),
                _buildQuickStats(),
                const SizedBox(height: 16),
                _buildDashboardGrid(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dashboard_outlined,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.groups.contains('dm_employee.group_hr_admin')
                  ? 'Admin Dashboard'
                  : 'Employee Dashboard',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue,
                AppColors.primaryBlue.withOpacity(0.9),
                AppColors.accentTeal.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 60,
                right: 80,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Material(
            color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _openUserProfile,
                child: Container(
                  padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(_headerAnimation),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openUserProfile,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color(0xFFFCFCFC),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentTeal.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withOpacity(0.08),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentTeal,
                          AppColors.accentTeal.withOpacity(0.8),
                          AppColors.primaryBlue.withOpacity(0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentTeal.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.successGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getTimeBasedGreeting(),
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _getTimeBasedIcon(),
                              color: AppColors.accentTeal,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.accentTeal,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            // Expanded(
            //   child: _buildStatCard(
            //     icon: Icons.access_time,
            //     title: 'Today',
            //     subtitle: 'Check In',
            //     color: AppColors.successGreen,
            //   ),
            // ),
            SizedBox(width: 12),
            // Expanded(
            //   child: _buildStatCard(
            //     icon: Icons.task_alt,
            //     title: '5',
            //     subtitle: 'Tasks',
            //     color: AppColors.accentTeal,
            //   ),
            // ),
            SizedBox(width: 12),
            // Expanded(
            //   child: _buildStatCard(
            //     icon: Icons.calendar_month,
            //     title: '2',
            //     subtitle: 'Leaves',
            //     color: AppColors.warningOrange,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return FadeTransition(
      opacity: _gridAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_gridAnimation),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.accentTeal,
                            AppColors.primaryBlue,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Quick Access',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.15,
                children: _buildDashboardItems(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  IconData _getTimeBasedIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny_outlined;
    } else if (hour < 17) {
      return Icons.wb_sunny;
    } else {
      return Icons.nightlight_round;
    }
  }

  List<Widget> _buildDashboardItems(BuildContext context) {
    final List<Widget> items = [];

    final bool isEmployee =
        widget.groups.contains('dm_employee.group_hr_employee');
    final bool isAdmin = widget.groups.contains('dm_employee.group_hr_admin');
    final bool isTaskAssigner =
        widget.groups.contains('dm_employee.group_task_assigner');

    // Attendance
    if (isAdmin || isEmployee) {
      items.add(
        _buildDashboardItem(
          context,
          Icons.fingerprint_outlined,
          'Attendance',
          '',
          AppColors.accentTeal,
          AttendancePage(
            isAdmin: isAdmin,
            currentUserName: widget.name,
          ),
        ),
      );
    }

    // Leave Management
    if (isAdmin || isEmployee) {
      items.add(
        _buildDashboardItem(
          context,
          isAdmin ? Icons.description_outlined : Icons.edit_calendar_outlined,
          isAdmin ? 'Applied Leaves' : 'Apply Leave',
          isAdmin ? '' : '',
          AppColors.warningOrange,
          ApplyLeave(
            userRole: isAdmin ? 'admin' : 'employee',
            currentUserName: widget.name,
          ),
        ),
      );
    }

    // Tasks
    if (isAdmin || isEmployee || isTaskAssigner) {
      items.add(
        _buildDashboardItem(
          context,
          Icons.task_alt_outlined,
          'Tasks',
          '',
          AppColors.successGreen,
          Task(
            groups: widget.groups,
            currentUserName: widget.name,
          ),
        ),
      );
    }

    // Employees
    if (isAdmin) {
      items.add(
        _buildDashboardItem(
          context,
          Icons.people_alt_outlined,
          'Employees',
          '',
          AppColors.primaryBlue,
          const EmployeePage(),
        ),
      );
    }

    // Payroll
    if (isAdmin) {
      items.add(
        _buildDashboardItem(
          context,
          Icons.payments_outlined,
          'Payroll',
          '',
          const Color(0xFF8B5CF6),
          const PayrollPage(),
        ),
      );
    }

    // Calendar
    if (isAdmin || isEmployee) {
      items.add(
        _buildDashboardItem(
          context,
          Icons.calendar_today_outlined,
          'Calendar',
          '',
          const Color(0xFFEC4899),
          const Holidays(),
        ),
      );
    }

    return items;
  }

  Widget _buildDashboardItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Widget page,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFDFDFD),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          onTap: () => _navigateToPage(context, page),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.8),
                        color.withOpacity(0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
