import 'package:dream_attend/report.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import '/models/attendance.dart';
import '/models/attendance_report.dart';
import '/services/attendance_services.dart';
import 'widget/search_filter_bar.dart';
import 'utils/app_layout.dart';

class AppStrings {
  static const attendanceLoadError =
      "Failed to load attendance data. Please try again.";
  static const locationServicesOff = "Please turn on your location services.";
  static const locationPermissionRequired =
      "Location permission is required to continue.";
  static const locationPermissionDeniedForever =
      "Location permission permanently denied. Enable it from settings.";
  static const locationFetchError =
      "Unable to fetch your location. Please try again.";
  static const noReportData = "No report data available.";
  static const reportLoadError = "Unable to load report. Please try again.";
  static const checkInArea = "Please be within the designated check-in area.";
  static const checkOutArea = "Please be within the designated check-out area.";
  static const lunchOutArea = "Please be within the designated lunch-out area.";
  static const lunchInArea = "Please be within the designated lunch-in area.";
  static const officeRequired = "You must be at the office to check in.";
  static const alreadyCheckedIn = "You have already checked in today.";
  static const createAttendanceFirst =
      "Please create an attendance record before checking in.";
  static const checkInFirst = "Please check in first.";
  static const cannotCheckOutDifferentDay =
      "Cannot check out for a different day.";
  static const cannotLunchOutDifferentDay =
      "Cannot mark lunch out for a different day.";
  static const lunchOutAlreadyRecorded = "Lunch out already recorded for today.";
  static const startLunchBreakFirst = "Start your lunch break first.";
  static const cannotLunchInDifferentDay =
      "Cannot mark lunch in for a different day.";
  static const serverEndpointNotFound =
      "Server endpoint not found. Contact admin.";
  static const serverError = "Server error. Try again later.";
  static const checkInError = "Unable to record check-in. Please try again.";
  static const checkOutError = "Unable to record check-out. Please try again.";
  static const lunchOutError = "Unable to record lunch out. Please try again.";
  static const lunchInError = "Unable to record lunch in. Please try again.";
  static const checkedInAt = "Checked in at";
  static const lunchBreakStarted = "Lunch break started";
  static const lunchBreakEnded = "Lunch break ended";
  static const checkedOutAt = "Checked out at";
}

class AttendancePage extends StatefulWidget {
  final bool isAdmin;
  final String currentUserName;

  const AttendancePage({
    super.key,
    required this.isAdmin,
    required this.currentUserName,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // coordinates
  final double targetLatitude = 19.716125;
  final double targetLongitude = 74.481272;
  final double allowedRadiusInMeters = 1000000;

  List<Attendance> users = [];
  List<Attendance> filteredUsers = [];
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _loadErrorMessage;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  List<AttendanceReport>? _reports; // cache for report data

  String _formatShortTimeWithPeriod(DateTime? time) {
    if (time == null) return '-';
    final istLocation = tz.getLocation('Asia/Kolkata');
    final istTime =
        time is tz.TZDateTime ? time : tz.TZDateTime.from(time, istLocation);
    final hour = istTime.hour % 12 == 0 ? 12 : istTime.hour % 12;
    final period = istTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:'
        '${istTime.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatAttendanceDate(Attendance user) {
    final recordedAt =
        user.checkIn ?? user.lunchOut ?? user.lunchIn ?? user.checkOut;
    if (recordedAt == null) return 'No attendance recorded';

    final istLocation = tz.getLocation('Asia/Kolkata');
    final istTime = recordedAt is tz.TZDateTime
        ? recordedAt
        : tz.TZDateTime.from(recordedAt, istLocation);

    return '${istTime.day.toString().padLeft(2, '0')}-'
        '${istTime.month.toString().padLeft(2, '0')}-'
        '${istTime.year}';
  }

  String formatDuration(String time) {
    try {
      final parts = time.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);

      if (hours == 0 && minutes == 0) return '0m';
      if (hours == 0) return '${minutes}m';
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    } catch (e) {
      return time;
    }
  }

  Future<void> fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final attendanceList = await _attendanceService.fetchAttendance();
      setState(() {
        _loadErrorMessage = null;
        if (widget.isAdmin) {
          users = attendanceList;
          filteredUsers = users;
        } else {
          users = attendanceList
              .where(
                (record) =>
                    record.name.toLowerCase() ==
                    widget.currentUserName.toLowerCase(),
              )
              .toList();
          if (users.isEmpty) {
            users = [
              Attendance(
                name: widget.currentUserName,
                checkIn: null,
                checkOut: null,
                lunchIn: null,
                lunchOut: null,
                daysPresent: 0,
                totalHours: '00:00:00',
                lunchDurationDisplay: '00:00:00',
              ),
            ];
          }
          filteredUsers = users;
        }
      });
    } catch (e) {
      debugPrint('Failed to load attendance data: $e');
      setState(() {
        _loadErrorMessage = AppStrings.attendanceLoadError;
      });
      showAppSnackBar(
        message: AppStrings.attendanceLoadError,
        type: AppSnackBarType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> isWithinAllowedRadius() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showAppSnackBar(
        message: AppStrings.locationServicesOff,
        type: AppSnackBarType.warning,
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showAppSnackBar(
          message: AppStrings.locationPermissionRequired,
          type: AppSnackBarType.warning,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showAppSnackBar(
        message: AppStrings.locationPermissionDeniedForever,
        type: AppSnackBarType.error,
      );
      return false;
    }

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Failed to fetch location: $e');
      showAppSnackBar(
        message: AppStrings.locationFetchError,
        type: AppSnackBarType.error,
      );
      return false;
    }

    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLatitude,
      targetLongitude,
    );

    return distanceInMeters <= allowedRadiusInMeters;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isActionLoading) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  void markCheckIn(int index) async {
    if (users.isEmpty || index >= users.length) return;
    await _runAction(() async {
      try {
        bool isNearby = await isWithinAllowedRadius();
        if (!isNearby) {
          showAppSnackBar(
            message: AppStrings.checkInArea,
            type: AppSnackBarType.error,
          );
          return;
        }

        final istLocation = tz.getLocation('Asia/Kolkata');
        final now = tz.TZDateTime.now(istLocation);
        final today = DateTime(now.year, now.month, now.day);
        final lastCheckIn = users[index].checkIn;
        final lastCheckInDate = lastCheckIn != null
            ? DateTime(lastCheckIn.year, lastCheckIn.month, lastCheckIn.day)
            : null;

        if (lastCheckInDate == today) {
          showAppSnackBar(
            message: AppStrings.alreadyCheckedIn,
            type: AppSnackBarType.warning,
          );
          return;
        }

        final attendance = users[index].copyWith(checkIn: now);
        await _attendanceService.checkIn(attendance);

        setState(() {
          users[index] = attendance;
          filteredUsers = users;
        });

        showAppSnackBar(
          message:
              "${AppStrings.checkedInAt} ${_formatShortTimeWithPeriod(now)}",
          type: AppSnackBarType.success,
        );
      } catch (e) {
        debugPrint('Failed to record check-in: $e');
        String errorMessage = AppStrings.checkInError;
        if (e.toString().contains("Please create an attendance record first")) {
          errorMessage = AppStrings.createAttendanceFirst;
        }
        showAppSnackBar(
          message: errorMessage,
          type: AppSnackBarType.error,
        );
      }
    });
  }

  void markCheckOut(int index) async {
    if (users.isEmpty || index >= users.length) return;

    await _runAction(() async {
      try {
        bool isNearby = await isWithinAllowedRadius();
        if (!isNearby) {
          showAppSnackBar(
            message: AppStrings.checkOutArea,
            type: AppSnackBarType.error,
          );
          return;
        }

        final istLocation = tz.getLocation('Asia/Kolkata');
        final now = tz.TZDateTime.now(istLocation);
        final today = DateTime(now.year, now.month, now.day);
        final checkIn = users[index].checkIn;

        if (checkIn == null) {
          showAppSnackBar(
            message: AppStrings.checkInFirst,
            type: AppSnackBarType.warning,
          );
          return;
        }

        final checkInIst = checkIn is tz.TZDateTime
            ? checkIn
            : tz.TZDateTime.from(checkIn, istLocation);
        final checkInDate = DateTime(
          checkInIst.year,
          checkInIst.month,
          checkInIst.day,
        );
        if (checkInDate != today) {
          showAppSnackBar(
            message: AppStrings.cannotCheckOutDifferentDay,
            type: AppSnackBarType.error,
          );
          return;
        }

        if (users[index].checkOut == null) {
          final duration = now.difference(checkInIst);
          final totalSeconds = duration.inSeconds;
          final hours = totalSeconds ~/ 3600;
          final minutes = (totalSeconds % 3600) ~/ 60;
          final seconds = totalSeconds % 60;
          final totalHoursDisplay =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

          final updatedAttendance = users[index].copyWith(
            checkOut: now,
            totalHours: totalHoursDisplay,
          );

          await _attendanceService.checkOut(updatedAttendance);

          setState(() {
            users[index] = updatedAttendance;
            filteredUsers = users;
          });

          showAppSnackBar(
            message:
                "${AppStrings.checkedOutAt} ${_formatShortTimeWithPeriod(now)}",
            type: AppSnackBarType.success,
          );
        }
      } catch (e) {
        debugPrint('Failed to record check-out: $e');
        showAppSnackBar(
          message: AppStrings.checkOutError,
          type: AppSnackBarType.error,
        );
      }
    });
  }

  void markLunchOut(int index) async {
    if (users.isEmpty || index >= users.length) return;

    await _runAction(() async {
      try {
        bool isNearby = await isWithinAllowedRadius();
        if (!isNearby) {
          showAppSnackBar(
            message: AppStrings.lunchOutArea,
            type: AppSnackBarType.error,
          );
          return;
        }

        final istLocation = tz.getLocation('Asia/Kolkata');
        final now = tz.TZDateTime.now(istLocation);
        final today = DateTime(now.year, now.month, now.day);
        final checkIn = users[index].checkIn;

        if (checkIn == null) {
          showAppSnackBar(
            message: AppStrings.checkInFirst,
            type: AppSnackBarType.warning,
          );
          return;
        }

        final checkInIst = checkIn is tz.TZDateTime
            ? checkIn
            : tz.TZDateTime.from(checkIn, istLocation);
        final checkInDate = DateTime(
          checkInIst.year,
          checkInIst.month,
          checkInIst.day,
        );
        if (checkInDate != today) {
          showAppSnackBar(
            message: AppStrings.cannotLunchOutDifferentDay,
            type: AppSnackBarType.error,
          );
          return;
        }

        if (users[index].lunchOut != null) {
          showAppSnackBar(
            message: AppStrings.lunchOutAlreadyRecorded,
            type: AppSnackBarType.warning,
          );
          return;
        }

        final updatedAttendance = users[index].copyWith(lunchOut: now);
        await _attendanceService.lunchOut(updatedAttendance);

        setState(() {
          users[index] = updatedAttendance;
          filteredUsers = users;
        });

        showAppSnackBar(
          message: AppStrings.lunchBreakStarted,
          type: AppSnackBarType.success,
        );
      } catch (e) {
        debugPrint('Failed to record lunch out: $e');
        showAppSnackBar(
          message: AppStrings.lunchOutError,
          type: AppSnackBarType.error,
        );
      }
    });
  }

  void markLunchIn(int index) async {
    if (users.isEmpty || index >= users.length) return;

    await _runAction(() async {
      try {
        bool isNearby = await isWithinAllowedRadius();
        if (!isNearby) {
          showAppSnackBar(
            message: AppStrings.lunchInArea,
            type: AppSnackBarType.error,
          );
          return;
        }

        final istLocation = tz.getLocation('Asia/Kolkata');
        final now = tz.TZDateTime.now(istLocation);
        final today = DateTime(now.year, now.month, now.day);
        final lunchOut = users[index].lunchOut;

        if (lunchOut == null) {
          showAppSnackBar(
            message: AppStrings.startLunchBreakFirst,
            type: AppSnackBarType.warning,
          );
          return;
        }

        final lunchOutIst = lunchOut is tz.TZDateTime
            ? lunchOut
            : tz.TZDateTime.from(lunchOut, istLocation);
        final lunchOutDate = DateTime(
          lunchOutIst.year,
          lunchOutIst.month,
          lunchOutIst.day,
        );
        if (lunchOutDate != today) {
          showAppSnackBar(
            message: AppStrings.cannotLunchInDifferentDay,
            type: AppSnackBarType.error,
          );
          return;
        }

        if (users[index].lunchIn == null) {
          final duration = now.difference(lunchOutIst);
          final totalSeconds = duration.inSeconds;
          final hours = totalSeconds ~/ 3600;
          final minutes = (totalSeconds % 3600) ~/ 60;
          final seconds = totalSeconds % 60;
          final lunchDurationDisplay =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

          final updatedAttendance = users[index].copyWith(
            lunchIn: now,
            lunchDurationDisplay: lunchDurationDisplay,
          );

          await _attendanceService.lunchIn(updatedAttendance);

          setState(() {
            users[index] = updatedAttendance;
            filteredUsers = users;
          });

          showAppSnackBar(
            message: AppStrings.lunchBreakEnded,
            type: AppSnackBarType.success,
          );
        }
      } catch (e) {
        debugPrint('Failed to record lunch in: $e');
        showAppSnackBar(
          message: AppStrings.lunchInError,
          type: AppSnackBarType.error,
        );
      }
    });
  }

  void createAttendanceRecord() async {
    await _runAction(() async {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          showAppSnackBar(
            message: AppStrings.locationServicesOff,
            type: AppSnackBarType.warning,
          );
          return;
        }

        bool isNearby = await isWithinAllowedRadius();
        if (!isNearby) {
          showAppSnackBar(
            message: AppStrings.officeRequired,
            type: AppSnackBarType.error,
          );
          return;
        }

        final istLocation = tz.getLocation('Asia/Kolkata');
        final now = tz.TZDateTime.now(istLocation);
        final today = DateTime(now.year, now.month, now.day);

        final alreadyCheckedIn = users.any((user) {
          if (user.name.toLowerCase() != widget.currentUserName.toLowerCase()) {
            return false;
          }
          if (user.checkIn == null) return false;
          final checkInDate = DateTime(
            user.checkIn!.year,
            user.checkIn!.month,
            user.checkIn!.day,
          );
          return checkInDate == today;
        });

        if (alreadyCheckedIn) {
          showAppSnackBar(
            message: AppStrings.alreadyCheckedIn,
            type: AppSnackBarType.warning,
          );
          return;
        }

        await _attendanceService.markAttendance(widget.currentUserName);

        final attendance = Attendance(
          name: widget.currentUserName,
          checkIn: now,
          checkOut: null,
          lunchIn: null,
          lunchOut: null,
          daysPresent: 1,
          totalHours: '00:00:00',
          lunchDurationDisplay: '00:00:00',
        );

        await _attendanceService.checkIn(attendance);

        await fetchAttendanceData();
        showAppSnackBar(
          message:
              "${AppStrings.checkedInAt} ${_formatShortTimeWithPeriod(now)}",
          type: AppSnackBarType.success,
          duration: const Duration(seconds: 4),
        );
      } catch (e) {
        debugPrint('Check-in failed: $e');
        String errorMsg = AppStrings.checkInError;
        if (e.toString().contains("404")) {
          errorMsg = AppStrings.serverEndpointNotFound;
        } else if (e.toString().contains("500")) {
          errorMsg = AppStrings.serverError;
        }

        showAppSnackBar(
          message: errorMsg,
          type: AppSnackBarType.error,
        );
      }
    });
  }

  void _filterUsers() {
    setState(() {
      final query = _searchController.text.trim().toLowerCase();
      filteredUsers = users.where((user) {
        final nameMatch =
            query.isEmpty || user.name.toLowerCase().contains(query);
        bool dateMatch = _selectedDate == null;
        if (_selectedDate != null && user.checkIn != null) {
          final checkInDate = DateTime(
            user.checkIn!.year,
            user.checkIn!.month,
            user.checkIn!.day,
          );
          final selected = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          );
          dateMatch = checkInDate == selected;
        }
        return nameMatch && dateMatch;
      }).toList();
    });
  }

  Attendance? get _currentUserAttendance {
    if (widget.isAdmin || filteredUsers.isEmpty) return null;
    return filteredUsers.first;
  }

  Widget _buildActionButton(Attendance user, int index) {
    if (user.checkIn == null) {
      return _primaryButton("Check In", Colors.green, () => markCheckIn(index));
    } else if (user.lunchOut == null) {
      return _primaryButton(
        "Lunch Out",
        Colors.orange,
        () => markLunchOut(index),
      );
    } else if (user.lunchIn == null) {
      return _primaryButton("Lunch In", Colors.blue, () => markLunchIn(index));
    } else if (user.checkOut == null) {
      return _primaryButton("Check Out", Colors.red, () => markCheckOut(index));
    } else {
      return _primaryButton("Completed", Colors.grey, null);
    }
  }

  Widget _primaryButton(
    String label,
    Color color,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isActionLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null ? Colors.grey.shade400 : color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isActionLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Widget _buildReportButton(Attendance user) {
    return ElevatedButton(
      onPressed: () async {
        try {
          _reports ??= await _attendanceService.fetchAllEmployeesAttendanceReport(
            month: DateTime.now().month.toString().padLeft(2, '0'),
            year: DateTime.now().year,
          );

          if (_reports == null || _reports!.isEmpty) {
            showAppSnackBar(
              message: AppStrings.noReportData,
              type: AppSnackBarType.warning,
            );
            return;
          }

          final targetName = widget.isAdmin ? user.name : widget.currentUserName;

          final userReport = _reports!.firstWhere(
            (report) =>
                report.employeeName.toLowerCase() == targetName.toLowerCase(),
            orElse: () => widget.isAdmin
                ? AttendanceReport(
                    employeeId: 0,
                    employeeName: user.name,
                    month: DateTime.now().month.toString().padLeft(2, '0'),
                    year: DateTime.now().year,
                    daysPresent: 0,
                    totalHours: '00:00:00',
                    fullLeaveDays: 0,
                    halfLeaveDays: 0,
                    wfhDays: 0,
                    department: '',
                    totalLunchDuration: '',
                  )
                : throw Exception('Report not found for $targetName'),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserReportPage(
                attendanceReport: userReport,
                currentUserName: targetName,
              ),
            ),
          );
        } catch (e) {
          debugPrint(
            'Unable to load report: $e',
          );
          _reports = null;
          showAppSnackBar(
            message: AppStrings.reportLoadError,
            type: AppSnackBarType.error,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        elevation: 2,
        minimumSize: const Size(double.infinity, 0),
      ),
      child: const Text(
        'View Report',
        style: TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTimeline(Attendance user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildTimelineItem(
            label: "Check In",
            time: user.checkIn,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            label: "Lunch Out",
            time: user.lunchOut,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            label: "Lunch In",
            time: user.lunchIn,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            label: "Check Out",
            time: user.checkOut,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String label,
    required DateTime? time,
    required Color color,
  }) {
    final isPending = time == null;
    return Row(
      children: [
        Icon(
          isPending ? Icons.radio_button_unchecked : Icons.check_circle,
          size: 18,
          color: isPending ? Colors.grey : color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        _buildValueText(_formatShortTimeWithPeriod(time)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 36,
              color: Colors.black54,
            ),
            const SizedBox(height: 12),
            Text(
              _loadErrorMessage ?? AppStrings.attendanceLoadError,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchAttendanceData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 7, 56, 80),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueText(String value) {
    // final isPending = value == 'Pending';
    final isPending = value == '-';
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        fontWeight: isPending ? FontWeight.w500 : FontWeight.w600,
        color: isPending ? Colors.grey : Colors.black87,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 7, 56, 80),
        ),
      );
    }

    if (_loadErrorMessage != null) {
      return _buildErrorState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isAdmin
                ? "Team Attendance Overview"
                : "Your Attendance Tracker",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.isAdmin)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SearchFilterBar(
                controller: _searchController,
                hintText: 'Search team or employee...',
                onChanged: _filterUsers,
                padding: EdgeInsets.zero,
                iconColor: Colors.grey,
                borderSide: BorderSide.none,
                enabledBorderSide: BorderSide.none,
                focusedBorderSide: BorderSide.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                fillColor: Colors.transparent,
                extraSuffixActions: [
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                        _filterUsers();
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: _selectedDate != null ? Colors.blue : Colors.grey,
                    ),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color.fromARGB(255, 7, 56, 80),
                                onPrimary: Colors.white,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        _filterUsers();
                      }
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      "No attendance records found. Please create a record to get started.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        const Color.fromARGB(255, 7, 56, 80),
                                    child: Text(
                                      (user.name.trim().isNotEmpty
                                              ? user.name.trim()[0]
                                              : '?')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatAttendanceDate(user),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTimeline(user),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                icon: Icons.lunch_dining,
                                color: Colors.orange,
                                label: "Break",
                                value: formatDuration(user.lunchDurationDisplay),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                icon: Icons.access_time,
                                color: Colors.green,
                                label: "Worked",
                                value: formatDuration(user.totalHours),
                              ),
                              const SizedBox(height: 5),
                              if (!widget.isAdmin)
                                _buildActionButton(user, index),
                              const SizedBox(height: 16),
                              _buildReportButton(user),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Attendance Hub",
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        elevation: 4,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF1F6F9),
              Color(0xFFE5EAF0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildBody(),
      ),
      floatingActionButton:
          !widget.isAdmin &&
                  _currentUserAttendance != null &&
                  _currentUserAttendance!.checkIn == null
          ? FloatingActionButton(
              onPressed: _isActionLoading ? null : createAttendanceRecord,
              backgroundColor: const Color.fromARGB(255, 7, 56, 80),
              tooltip: 'Create Attendance Record',
              child: _isActionLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.orange),
            )
          : null,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          "$label:",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        _buildValueText(value),
      ],
    );
  }
}
