// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'dart:async';
// import 'package:shared_preferences/shared_preferences.dart'; // Added for persistent storage
// import '/models/attendance.dart';
// import '/models/attendance_report.dart';
// import '/services/attendance_services.dart';
// import '/services/employee_service.dart';

// class AttendancePage extends StatefulWidget {
//   final bool isAdmin;
//   final String currentUserName;

//   const AttendancePage({
//     super.key,
//     required this.isAdmin,
//     required this.currentUserName,
//   });

//   @override
//   State<AttendancePage> createState() => _AttendancePageState();
// }

// class _AttendancePageState extends State<AttendancePage> {
//   // coordinates
//   final double targetLatitude = 19.716125;
//   final double targetLongitude = 74.481272;
//   final double allowedRadiusInMeters = 100000000;

//   List<Attendance> users = [];
//   List<Attendance> filteredUsers = [];
//   final AttendanceService _attendanceService = AttendanceService();
//   final EmployeeService _employeeService = EmployeeService();
//   bool _isLoading = true;
//   bool _isFabVisible = true;
//   Timer? _fabTimer;
//   final TextEditingController _searchController = TextEditingController();

//   // Key for storing the FAB hide timestamp
//   static const String _fabHideTimestampKey = 'fab_hide_timestamp';

//   Future<void> _saveFabHideTimestamp() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt(
//         _fabHideTimestampKey, DateTime.now().millisecondsSinceEpoch);
//   }

//   Future<void> _checkFabVisibility() async {
//     final prefs = await SharedPreferences.getInstance();
//     final timestamp = prefs.getInt(_fabHideTimestampKey);
//     if (timestamp != null) {
//       final now = DateTime.now();
//       final hideTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
//       final difference = now.difference(hideTime);
//       const hideDuration = Duration(minutes: 5); // Changed to 5 minutes

//       if (difference < hideDuration) {
//         setState(() {
//           _isFabVisible = false;
//         });
//         // Set a timer for the remaining time
//         final remainingTime = hideDuration - difference;
//         _fabTimer?.cancel();
//         _fabTimer = Timer(remainingTime, () {
//           setState(() {
//             _isFabVisible = true;
//           });
//           prefs.remove(_fabHideTimestampKey); // Clear the timestamp
//         });
//       } else {
//         // Timestamp is older than 5 minutes, clear it and show FAB
//         await prefs.remove(_fabHideTimestampKey);
//         setState(() {
//           _isFabVisible = true;
//         });
//       }
//     } else {
//       setState(() {
//         _isFabVisible = true;
//       });
//     }
//   }

//   String formatTime(DateTime? time) {
//     if (time == null) return 'Not Recorded';
//     final istLocation = tz.getLocation('Asia/Kolkata');
//     final istTime =
//         time is tz.TZDateTime ? time : tz.TZDateTime.from(time, istLocation);
//     return '${istTime.day.toString().padLeft(2, '0')}-'
//         '${istTime.month.toString().padLeft(2, '0')}-'
//         '${istTime.year}  '
//         '${istTime.hour.toString().padLeft(2, '0')}:'
//         '${istTime.minute.toString().padLeft(2, '0')}:'
//         '${istTime.second.toString().padLeft(2, '0')}';
//   }

//   void _showCustomSnackBar({
//     required BuildContext context,
//     required String message,
//     required Color backgroundColor,
//     required IconData icon,
//     Duration duration = const Duration(seconds: 3),
//   }) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: SlideTransition(
//           position: Tween<Offset>(
//             begin: const Offset(0, 1),
//             end: Offset.zero,
//           ).animate(
//             CurvedAnimation(
//               parent: ModalRoute.of(context)!.animation!,
//               curve: Curves.easeOutCubic,
//             ),
//           ),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 8,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Row(
//               children: [
//                 Icon(icon, color: Colors.white, size: 24),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     message,
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w500,
//                       color: Colors.white,
//                       fontFamily: 'Roboto',
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         backgroundColor: Colors.transparent,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         elevation: 0,
//         duration: duration,
//       ),
//     );
//   }

//   Future<void> fetchAttendanceData() async {
//     setState(() => _isLoading = true);
//     try {
//       final attendanceList = await _attendanceService.fetchAttendance();
//       setState(() {
//         if (widget.isAdmin) {
//           users = attendanceList;
//           filteredUsers = users;
//         } else {
//           users = attendanceList
//               .where(
//                 (record) =>
//                     record.name.toLowerCase() ==
//                     widget.currentUserName.toLowerCase(),
//               )
//               .toList();
//           if (users.isEmpty) {
//             users = [
//               Attendance(
//                 name: widget.currentUserName,
//                 checkIn: null,
//                 checkOut: null,
//                 lunchIn: null,
//                 lunchOut: null,
//                 daysPresent: 0,
//                 totalHours: '00:00:00',
//                 lunchDurationDisplay: '00:00:00',
//               ),
//             ];
//           }
//           filteredUsers = users;
//         }
//       });
//     } catch (e) {
//       _showCustomSnackBar(
//         context: context,
//         message: "Failed to load attendance data: $e",
//         backgroundColor: Colors.redAccent,
//         icon: Icons.error_outline,
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchAttendanceData();
//     _checkFabVisibility(); // Check FAB visibility on page load
//     _searchController.addListener(_filterUsers);
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_filterUsers);
//     _searchController.dispose();
//     _fabTimer?.cancel();
//     super.dispose();
//   }

//   Future<bool> isWithinAllowedRadius() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return false;

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return false;
//     }

//     if (permission == LocationPermission.deniedForever) return false;

//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );

//     double distanceInMeters = Geolocator.distanceBetween(
//       position.latitude,
//       position.longitude,
//       targetLatitude,
//       targetLongitude,
//     );

//     return distanceInMeters <= allowedRadiusInMeters;
//   }

//   void markCheckIn(int index) async {
//     if (users.isEmpty || index >= users.length) return;
//     try {
//       bool isNearby = await isWithinAllowedRadius();
//       if (!isNearby) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Please be within the designated check-in area.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.location_off,
//         );
//         return;
//       }

//       final istLocation = tz.getLocation('Asia/Kolkata');
//       final now = tz.TZDateTime.now(istLocation);
//       final today = DateTime(now.year, now.month, now.day);
//       final lastCheckIn = users[index].checkIn;
//       final lastCheckInDate = lastCheckIn != null
//           ? DateTime(lastCheckIn.year, lastCheckIn.month, lastCheckIn.day)
//           : null;

//       if (lastCheckInDate == today) {
//         _showCustomSnackBar(
//           context: context,
//           message: "You have already checked in today.",
//           backgroundColor: Colors.orangeAccent,
//           icon: Icons.check_circle_outline,
//         );
//         return;
//       }

//       final attendance = users[index].copyWith(checkIn: now);
//       await _attendanceService.checkIn(attendance);

//       setState(() {
//         users[index] = attendance;
//         filteredUsers = users;
//       });

//       _showCustomSnackBar(
//         context: context,
//         message: "Check-in recorded successfully.",
//         backgroundColor: Colors.green,
//         icon: Icons.check_circle,
//       );
//     } catch (e) {
//       String errorMessage = "Failed to record check-in: $e";
//       if (e.toString().contains("Please create an attendance record first")) {
//         errorMessage = "Please create an attendance record before checking in.";
//       }
//       _showCustomSnackBar(
//         context: context,
//         message: errorMessage,
//         backgroundColor: Colors.redAccent,
//         icon: Icons.error_outline,
//       );
//     }
//   }

//   void markCheckOut(int index) async {
//     if (users.isEmpty || index >= users.length) return;

//     try {
//       bool isNearby = await isWithinAllowedRadius();
//       if (!isNearby) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Please be within the designated check-out area.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.location_off,
//         );
//         return;
//       }

//       final istLocation = tz.getLocation('Asia/Kolkata');
//       final now = tz.TZDateTime.now(istLocation);
//       final today = DateTime(now.year, now.month, now.day);
//       final checkIn = users[index].checkIn;

//       final checkInIst = checkIn is tz.TZDateTime
//           ? checkIn
//           : tz.TZDateTime.from(checkIn!, istLocation);
//       final checkInDate = DateTime(
//         checkInIst.year,
//         checkInIst.month,
//         checkInIst.day,
//       );
//       if (checkInDate != today) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Cannot check out for a different day.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.calendar_today,
//         );
//         return;
//       }

//       if (users[index].checkOut == null) {
//         final duration = now.difference(checkInIst);
//         final totalSeconds = duration.inSeconds;
//         final hours = totalSeconds ~/ 3600;
//         final minutes = (totalSeconds % 3600) ~/ 60;
//         final seconds = totalSeconds % 60;
//         final totalHoursDisplay =
//             '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

//         final updatedAttendance = users[index].copyWith(
//           checkOut: now,
//           totalHours: totalHoursDisplay,
//         );

//         await _attendanceService.checkOut(updatedAttendance);

//         setState(() {
//           users[index] = updatedAttendance;
//           filteredUsers = users;
//         });

//         _showCustomSnackBar(
//           context: context,
//           message: "Check-out recorded successfully.",
//           backgroundColor: Colors.green,
//           icon: Icons.check_circle,
//         );
//       }
//     } catch (e) {
//       _showCustomSnackBar(
//         context: context,
//         message: "Failed to record check-out: $e",
//         backgroundColor: Colors.redAccent,
//         icon: Icons.error_outline,
//       );
//     }
//   }

//   void markLunchOut(int index) async {
//     if (users.isEmpty || index >= users.length) return;

//     try {
//       bool isNearby = await isWithinAllowedRadius();
//       if (!isNearby) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Please be within the designated lunch-out area.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.location_off,
//         );
//         return;
//       }

//       final istLocation = tz.getLocation('Asia/Kolkata');
//       final now = tz.TZDateTime.now(istLocation);
//       final today = DateTime(now.year, now.month, now.day);
//       final checkIn = users[index].checkIn;

//       final checkInIst = checkIn is tz.TZDateTime
//           ? checkIn
//           : tz.TZDateTime.from(checkIn!, istLocation);
//       final checkInDate = DateTime(
//         checkInIst.year,
//         checkInIst.month,
//         checkInIst.day,
//       );
//       if (checkInDate != today) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Cannot mark lunch out for a different day.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.calendar_today,
//         );
//         return;
//       }

//       if (users[index].lunchOut != null) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Lunch out already recorded for today.",
//           backgroundColor: Colors.orangeAccent,
//           icon: Icons.warning_amber,
//         );
//         return;
//       }

//       final updatedAttendance = users[index].copyWith(lunchOut: now);
//       await _attendanceService.lunchOut(updatedAttendance);

//       setState(() {
//         users[index] = updatedAttendance;
//         filteredUsers = users;
//       });

//       _showCustomSnackBar(
//         context: context,
//         message: "Lunch out recorded successfully.",
//         backgroundColor: Colors.green,
//         icon: Icons.check_circle,
//       );
//     } catch (e) {
//       _showCustomSnackBar(
//         context: context,
//         message: "Failed to record lunch out: $e",
//         backgroundColor: Colors.redAccent,
//         icon: Icons.error_outline,
//       );
//     }
//   }

//   void markLunchIn(int index) async {
//     if (users.isEmpty || index >= users.length) return;

//     try {
//       bool isNearby = await isWithinAllowedRadius();
//       if (!isNearby) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Please be within the designated lunch-in area.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.location_off,
//         );
//         return;
//       }

//       final istLocation = tz.getLocation('Asia/Kolkata');
//       final now = tz.TZDateTime.now(istLocation);
//       final today = DateTime(now.year, now.month, now.day);
//       final lunchOut = users[index].lunchOut;

//       final lunchOutIst = lunchOut is tz.TZDateTime
//           ? lunchOut
//           : tz.TZDateTime.from(lunchOut!, istLocation);
//       final lunchOutDate = DateTime(
//         lunchOutIst.year,
//         lunchOutIst.month,
//         lunchOutIst.day,
//       );
//       if (lunchOutDate != today) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Cannot mark lunch in for a different day.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.calendar_today,
//         );
//         return;
//       }

//       if (users[index].lunchIn == null) {
//         final duration = now.difference(lunchOutIst);
//         final totalSeconds = duration.inSeconds;
//         final hours = totalSeconds ~/ 3600;
//         final minutes = (totalSeconds % 3600) ~/ 60;
//         final seconds = totalSeconds % 60;
//         final lunchDurationDisplay =
//             '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

//         final updatedAttendance = users[index].copyWith(
//           lunchIn: now,
//           lunchDurationDisplay: lunchDurationDisplay,
//         );

//         await _attendanceService.lunchIn(updatedAttendance);

//         setState(() {
//           users[index] = updatedAttendance;
//           filteredUsers = users;
//         });

//         _showCustomSnackBar(
//           context: context,
//           message: "Lunch in recorded successfully.",
//           backgroundColor: Colors.green,
//           icon: Icons.check_circle,
//         );
//       }
//     } catch (e) {
//       _showCustomSnackBar(
//         context: context,
//         message: "Failed to record lunch in: $e",
//         backgroundColor: Colors.redAccent,
//         icon: Icons.error_outline,
//       );
//     }
//   }

//   void createAttendanceRecord() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Please turn on your location services.",
//           backgroundColor: Colors.orangeAccent,
//           icon: Icons.gps_off,
//         );
//         return;
//       }

//       bool isNearby = await isWithinAllowedRadius();
//       if (!isNearby) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Please be within the designated area to create a record.",
//           backgroundColor: Colors.redAccent,
//           icon: Icons.location_off,
//         );
//         return;
//       }

//       final istLocation = tz.getLocation('Asia/Kolkata');
//       final now = tz.TZDateTime.now(istLocation);
//       final today = DateTime(now.year, now.month, now.day);

//       // Check for existing records for today
//       final todayRecords = users.where((user) {
//         if (user.name.toLowerCase() != widget.currentUserName.toLowerCase()) {
//           return false;
//         }
//         if (user.checkIn == null) {
//           return false;
//         }
//         final checkInDate = DateTime(
//           user.checkIn!.year,
//           user.checkIn!.month,
//           user.checkIn!.day,
//         );
//         return checkInDate == today;
//       }).toList();

//       // Count records for today
//       final recordCount = todayRecords.length;

//       if (recordCount >= 1) {
//         _showCustomSnackBar(
//           context: context,
//           message: "Attendance record already created for today.",
//           backgroundColor: Colors.orangeAccent,
//           icon: Icons.warning_amber,
//         );
//         return;
//       }

//       // Create new attendance record
//       await _attendanceService.markAttendance(widget.currentUserName);
//       await fetchAttendanceData();

//       // Hide FAB, save timestamp, and start 5-minute timer
//       setState(() {
//         _isFabVisible = false;
//       });
//       await _saveFabHideTimestamp(); // Save the timestamp
//       _fabTimer?.cancel(); // Cancel any existing timer
//       _fabTimer = Timer(const Duration(minutes: 5), () async {
//         setState(() {
//           _isFabVisible = true;
//         });
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.remove(_fabHideTimestampKey); // Clear the timestamp
//       });

//       _showCustomSnackBar(
//         context: context,
//         message: "Attendance record created successfully.",
//         backgroundColor: Colors.green,
//         icon: Icons.check_circle,
//       );
//     } catch (e) {
//       _showCustomSnackBar(
//         context: context,
//         message: "Failed to create attendance record: $e",
//         backgroundColor: Colors.redAccent,
//         icon: Icons.error_outline,
//       );
//     }
//   }

//   void _filterUsers() {
//     setState(() {
//       final query = _searchController.text.trim();
//       if (query.isEmpty) {
//         filteredUsers = users;
//       } else {
//         filteredUsers = users
//             .where(
//               (user) => user.name.toLowerCase().contains(query.toLowerCase()),
//             )
//             .toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Attendance Hub",
//           style: TextStyle(
//               fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
//         ),
//         backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//         elevation: 4,
//         centerTitle: true,
//         shadowColor: Colors.black.withOpacity(0.2),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFFF1F6F9),
//               Color(0xFFE5EAF0),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: _isLoading
//             ? const Center(
//                 child: CircularProgressIndicator(
//                     color: Color.fromARGB(255, 7, 56, 80)),
//               )
//             : Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16.0,
//                   vertical: 20.0,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.isAdmin
//                           ? "Team Attendance Overview"
//                           : "Your Attendance Tracker",
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     if (widget.isAdmin)
//                       Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(12),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 8,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: TextField(
//                           controller: _searchController,
//                           decoration: InputDecoration(
//                             hintText: 'Search team members...',
//                             prefixIcon: const Icon(
//                               Icons.search,
//                               color: Colors.grey,
//                             ),
//                             suffixIcon: _searchController.text.isNotEmpty
//                                 ? IconButton(
//                                     icon: const Icon(
//                                       Icons.clear,
//                                       color: Colors.grey,
//                                     ),
//                                     onPressed: () {
//                                       _searchController.clear();
//                                       _filterUsers();
//                                     },
//                                   )
//                                 : null,
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide.none,
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               vertical: 14,
//                             ),
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 20),
//                     Expanded(
//                       child: filteredUsers.isEmpty
//                           ? const Center(
//                               child: Text(
//                                 "No attendance records available. Start by creating one.",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   color: Colors.black54,
//                                 ),
//                               ),
//                             )
//                           : ListView.builder(
//                               itemCount: filteredUsers.length,
//                               itemBuilder: (context, index) {
//                                 final user = filteredUsers[index];
//                                 return Card(
//                                   elevation: 2,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                   margin: const EdgeInsets.symmetric(
//                                     vertical: 8,
//                                   ),
//                                   color: Colors.white,
//                                   shadowColor: Colors.black.withOpacity(0.1),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(16.0),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           children: [
//                                             CircleAvatar(
//                                               radius: 24,
//                                               backgroundColor:
//                                                   const Color.fromARGB(
//                                                 255,
//                                                 7,
//                                                 56,
//                                                 80,
//                                               ),
//                                               child: Text(
//                                                 user.name[0].toUpperCase(),
//                                                 style: const TextStyle(
//                                                   color: Colors.white,
//                                                   fontWeight: FontWeight.bold,
//                                                   fontSize: 18,
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(width: 16),
//                                             Expanded(
//                                               child: Text(
//                                                 user.name,
//                                                 style: const TextStyle(
//                                                   fontSize: 18,
//                                                   fontWeight: FontWeight.w600,
//                                                   color: Colors.black87,
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 16),
//                                         _buildInfoRow(
//                                           icon: Icons.login,
//                                           color: Colors.green,
//                                           label: "Check-In",
//                                           value: formatTime(user.checkIn),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         _buildInfoRow(
//                                           icon: Icons.restaurant_menu,
//                                           color: Colors.orange,
//                                           label: "Lunch Out",
//                                           value: formatTime(user.lunchOut),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         _buildInfoRow(
//                                           icon: Icons.restaurant,
//                                           color: Colors.blue,
//                                           label: "Lunch In",
//                                           value: formatTime(user.lunchIn),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         _buildInfoRow(
//                                           icon: Icons.logout,
//                                           color: Colors.red,
//                                           label: "Check-Out",
//                                           value: formatTime(user.checkOut),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         _buildInfoRow(
//                                           icon: Icons.timer,
//                                           color: Colors.black54,
//                                           label: "Lunch Duration",
//                                           value: user.lunchDurationDisplay,
//                                         ),
//                                         const SizedBox(height: 8),
//                                         _buildInfoRow(
//                                           icon: Icons.access_time,
//                                           color: Colors.black54,
//                                           label: "Total Hours",
//                                           value: user.totalHours,
//                                         ),
//                                         const SizedBox(height: 24),
//                                         if (!widget.isAdmin)
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceEvenly,
//                                             children: [
//                                               Expanded(
//                                                 child: ElevatedButton(
//                                                   onPressed: user.daysPresent ==
//                                                               0 ||
//                                                           user.checkIn != null
//                                                       ? null
//                                                       : () =>
//                                                           markCheckIn(index),
//                                                   style:
//                                                       ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.green[700],
//                                                     foregroundColor:
//                                                         Colors.white,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               8),
//                                                     ),
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                         vertical: 12),
//                                                     elevation: 2,
//                                                   ),
//                                                   child: const Text(
//                                                     'Check In',
//                                                     style: TextStyle(
//                                                         fontWeight:
//                                                             FontWeight.w500),
//                                                   ),
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               Expanded(
//                                                 child: ElevatedButton(
//                                                   onPressed: user.checkIn ==
//                                                               null ||
//                                                           user.lunchOut != null
//                                                       ? null
//                                                       : () =>
//                                                           markLunchOut(index),
//                                                   style:
//                                                       ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.orange[700],
//                                                     foregroundColor:
//                                                         Colors.white,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               8),
//                                                     ),
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                         vertical: 12),
//                                                     elevation: 2,
//                                                   ),
//                                                   child: const Text(
//                                                     'Lunch Out',
//                                                     style: TextStyle(
//                                                         fontWeight:
//                                                             FontWeight.w500),
//                                                   ),
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               Expanded(
//                                                 child: ElevatedButton(
//                                                   onPressed: user.lunchOut ==
//                                                               null ||
//                                                           user.lunchIn != null
//                                                       ? null
//                                                       : () =>
//                                                           markLunchIn(index),
//                                                   style:
//                                                       ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.blue[700],
//                                                     foregroundColor:
//                                                         Colors.white,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               8),
//                                                     ),
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                         vertical: 12),
//                                                     elevation: 2,
//                                                   ),
//                                                   child: const Text(
//                                                     'Lunch In',
//                                                     style: TextStyle(
//                                                         fontWeight:
//                                                             FontWeight.w500),
//                                                   ),
//                                                 ),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               Expanded(
//                                                 child: ElevatedButton(
//                                                   onPressed: user.lunchIn ==
//                                                               null ||
//                                                           user.checkOut != null
//                                                       ? null
//                                                       : () =>
//                                                           markCheckOut(index),
//                                                   style:
//                                                       ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.red[700],
//                                                     foregroundColor:
//                                                         Colors.white,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               8),
//                                                     ),
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                         vertical: 12),
//                                                     elevation: 2,
//                                                   ),
//                                                   child: const Text(
//                                                     'Check Out',
//                                                     style: TextStyle(
//                                                         fontWeight:
//                                                             FontWeight.w500),
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         const SizedBox(height: 16),
//                                         ElevatedButton(
//                                           onPressed: () async {
//                                             try {
//                                               if (widget.isAdmin) {
//                                                 final reports =
//                                                     await _attendanceService
//                                                         .fetchAllEmployeesAttendanceReport(
//                                                   month: DateTime.now()
//                                                       .month
//                                                       .toString()
//                                                       .padLeft(
//                                                         2,
//                                                         '0',
//                                                       ),
//                                                   year: DateTime.now().year,
//                                                 );

//                                                 final userReport =
//                                                     reports.firstWhere(
//                                                   (report) =>
//                                                       report.employeeName
//                                                           .toLowerCase() ==
//                                                       user.name.toLowerCase(),
//                                                   orElse: () =>
//                                                       AttendanceReport(
//                                                     employeeId: 0,
//                                                     employeeName: user.name,
//                                                     month: DateTime.now()
//                                                         .month
//                                                         .toString()
//                                                         .padLeft(
//                                                           2,
//                                                           '0',
//                                                         ),
//                                                     year: DateTime.now().year,
//                                                     daysPresent: 0,
//                                                     totalHours: '00:00:00',
//                                                     fullLeaveDays: 0,
//                                                     halfLeaveDays: 0,
//                                                     wfhDays: 0,
//                                                     department: '',
//                                                     totalLunchDuration: '',
//                                                   ),
//                                                 );

//                                                 Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder: (
//                                                       context,
//                                                     ) =>
//                                                         UserReportPage(
//                                                       attendanceReport:
//                                                           userReport,
//                                                       currentUserName:
//                                                           user.name,
//                                                     ),
//                                                   ),
//                                                 );
//                                               } else {
//                                                 final reports =
//                                                     await _attendanceService
//                                                         .fetchAllEmployeesAttendanceReport(
//                                                   month: DateTime.now()
//                                                       .month
//                                                       .toString()
//                                                       .padLeft(
//                                                         2,
//                                                         '0',
//                                                       ),
//                                                   year: DateTime.now().year,
//                                                 );

//                                                 final userReport =
//                                                     reports.firstWhere(
//                                                   (report) =>
//                                                       report.employeeName
//                                                           .toLowerCase() ==
//                                                       widget.currentUserName
//                                                           .toLowerCase(),
//                                                   orElse: () => throw Exception(
//                                                     'Report not found for ${widget.currentUserName}',
//                                                   ),
//                                                 );

//                                                 Navigator.push(
//                                                   context,
//                                                   MaterialPageRoute(
//                                                     builder: (
//                                                       context,
//                                                     ) =>
//                                                         UserReportPage(
//                                                       attendanceReport:
//                                                           userReport,
//                                                       currentUserName: widget
//                                                           .currentUserName,
//                                                     ),
//                                                   ),
//                                                 );
//                                               }
//                                             } catch (e) {
//                                               _showCustomSnackBar(
//                                                 context: context,
//                                                 message:
//                                                     "Failed to load report: $e",
//                                                 backgroundColor:
//                                                     Colors.redAccent,
//                                                 icon: Icons.error_outline,
//                                               );
//                                             }
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor:
//                                                 const Color.fromARGB(
//                                                     255, 7, 56, 80),
//                                             foregroundColor: Colors.white,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                             ),
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 24,
//                                               vertical: 12,
//                                             ),
//                                             elevation: 2,
//                                             minimumSize:
//                                                 const Size(double.infinity, 0),
//                                           ),
//                                           child: const Text(
//                                             'View Report',
//                                             style: TextStyle(
//                                               fontWeight: FontWeight.w500,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//       floatingActionButton: !widget.isAdmin && _isFabVisible
//           ? FloatingActionButton(
//               onPressed: createAttendanceRecord,
//               backgroundColor: const Color.fromARGB(255, 7, 56, 80),
//               tooltip: 'Create Attendance Record',
//               child: const Icon(Icons.add, color: Colors.orange),
//             )
//           : null,
//     );
//   }

//   Widget _buildInfoRow({
//     required IconData icon,
//     required Color color,
//     required String label,
//     required String value,
//   }) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           size: 20,
//           color: color,
//         ),
//         const SizedBox(width: 8),
//         Text(
//           "$label: $value",
//           style: const TextStyle(
//             fontSize: 14,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:dream_attend/report.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // Added for persistent storage
import '/models/attendance.dart';
import '/models/attendance_report.dart';
import '/services/attendance_services.dart';
import '/services/employee_service.dart';

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
  final EmployeeService _employeeService = EmployeeService();
  bool _isLoading = true;
  bool _isFabVisible = true;
  Timer? _fabTimer;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  // Key for storing the FAB hide timestamp
  static const String _fabHideTimestampKey = 'fab_hide_timestamp';

  Future<void> _saveFabHideTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _fabHideTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _checkFabVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_fabHideTimestampKey);
    if (timestamp != null) {
      final now = DateTime.now();
      final hideTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final difference = now.difference(hideTime);
      const hideDuration = Duration(minutes: 5);

      if (difference < hideDuration) {
        setState(() {
          _isFabVisible = false;
        });

        final remainingTime = hideDuration - difference;
        _fabTimer?.cancel();
        _fabTimer = Timer(remainingTime, () {
          setState(() {
            _isFabVisible = true;
          });
          prefs.remove(_fabHideTimestampKey); // Clear the timestamp
        });
      } else {
        // Timestamp is older than 5 minutes, clear it and show FAB
        await prefs.remove(_fabHideTimestampKey);
        setState(() {
          _isFabVisible = true;
        });
      }
    } else {
      setState(() {
        _isFabVisible = true;
      });
    }
  }

  String formatTime(DateTime? time) {
    if (time == null) return 'Not Recorded';
    final istLocation = tz.getLocation('Asia/Kolkata');
    final istTime =
        time is tz.TZDateTime ? time : tz.TZDateTime.from(time, istLocation);
    return '${istTime.day.toString().padLeft(2, '0')}-'
        '${istTime.month.toString().padLeft(2, '0')}-'
        '${istTime.year}  '
        '${istTime.hour.toString().padLeft(2, '0')}:'
        '${istTime.minute.toString().padLeft(2, '0')}:'
        '${istTime.second.toString().padLeft(2, '0')}';
  }

  void _showCustomSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
        duration: duration,
      ),
    );
  }

  Future<void> fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final attendanceList = await _attendanceService.fetchAttendance();
      setState(() {
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
      _showCustomSnackBar(
        context: context,
        message: "Failed to load attendance data: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
    _checkFabVisibility(); // Check FAB visibility on page load
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    _fabTimer?.cancel();
    super.dispose();
  }

  Future<bool> isWithinAllowedRadius() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      targetLatitude,
      targetLongitude,
    );

    return distanceInMeters <= allowedRadiusInMeters;
  }

  void markCheckIn(int index) async {
    if (users.isEmpty || index >= users.length) return;
    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated check-in area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
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
        _showCustomSnackBar(
          context: context,
          message: "You have already checked in today.",
          backgroundColor: Colors.orangeAccent,
          icon: Icons.check_circle_outline,
        );
        return;
      }

      final attendance = users[index].copyWith(checkIn: now);
      await _attendanceService.checkIn(attendance);

      setState(() {
        users[index] = attendance;
        filteredUsers = users;
      });

      _showCustomSnackBar(
        context: context,
        message: "Check-in recorded successfully.",
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    } catch (e) {
      String errorMessage = "Failed to record check-in: $e";
      if (e.toString().contains("Please create an attendance record first")) {
        errorMessage = "Please create an attendance record before checking in.";
      }
      _showCustomSnackBar(
        context: context,
        message: errorMessage,
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void markCheckOut(int index) async {
    if (users.isEmpty || index >= users.length) return;

    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated check-out area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);
      final checkIn = users[index].checkIn;

      final checkInIst = checkIn is tz.TZDateTime
          ? checkIn
          : tz.TZDateTime.from(checkIn!, istLocation);
      final checkInDate = DateTime(
        checkInIst.year,
        checkInIst.month,
        checkInIst.day,
      );
      if (checkInDate != today) {
        _showCustomSnackBar(
          context: context,
          message: "Cannot check out for a different day.",
          backgroundColor: Colors.redAccent,
          icon: Icons.calendar_today,
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

        _showCustomSnackBar(
          context: context,
          message: "Check-out recorded successfully.",
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to record check-out: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void markLunchOut(int index) async {
    if (users.isEmpty || index >= users.length) return;

    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated lunch-out area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);
      final checkIn = users[index].checkIn;

      final checkInIst = checkIn is tz.TZDateTime
          ? checkIn
          : tz.TZDateTime.from(checkIn!, istLocation);
      final checkInDate = DateTime(
        checkInIst.year,
        checkInIst.month,
        checkInIst.day,
      );
      if (checkInDate != today) {
        _showCustomSnackBar(
          context: context,
          message: "Cannot mark lunch out for a different day.",
          backgroundColor: Colors.redAccent,
          icon: Icons.calendar_today,
        );
        return;
      }

      if (users[index].lunchOut != null) {
        _showCustomSnackBar(
          context: context,
          message: "Lunch out already recorded for today.",
          backgroundColor: Colors.orangeAccent,
          icon: Icons.warning_amber,
        );
        return;
      }

      final updatedAttendance = users[index].copyWith(lunchOut: now);
      await _attendanceService.lunchOut(updatedAttendance);

      setState(() {
        users[index] = updatedAttendance;
        filteredUsers = users;
      });

      _showCustomSnackBar(
        context: context,
        message: "Lunch out recorded successfully.",
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to record lunch out: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  void markLunchIn(int index) async {
    if (users.isEmpty || index >= users.length) return;

    try {
      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "Please be within the designated lunch-in area.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);
      final lunchOut = users[index].lunchOut;

      final lunchOutIst = lunchOut is tz.TZDateTime
          ? lunchOut
          : tz.TZDateTime.from(lunchOut!, istLocation);
      final lunchOutDate = DateTime(
        lunchOutIst.year,
        lunchOutIst.month,
        lunchOutIst.day,
      );
      if (lunchOutDate != today) {
        _showCustomSnackBar(
          context: context,
          message: "Cannot mark lunch in for a different day.",
          backgroundColor: Colors.redAccent,
          icon: Icons.calendar_today,
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

        _showCustomSnackBar(
          context: context,
          message: "Lunch in recorded successfully.",
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        context: context,
        message: "Failed to record lunch in: $e",
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
  }

  // void createAttendanceRecord() async {
  //   try {
  //     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //     if (!serviceEnabled) {
  //       _showCustomSnackBar(
  //         context: context,
  //         message: "Please turn on your location services.",
  //         backgroundColor: Colors.orangeAccent,
  //         icon: Icons.gps_off,
  //       );
  //       return;
  //     }

  //     bool isNearby = await isWithinAllowedRadius();
  //     if (!isNearby) {
  //       _showCustomSnackBar(
  //         context: context,
  //         message: "Please be within the designated area to create a record.",
  //         backgroundColor: Colors.redAccent,
  //         icon: Icons.location_off,
  //       );
  //       return;
  //     }

  //     final istLocation = tz.getLocation('Asia/Kolkata');
  //     final now = tz.TZDateTime.now(istLocation);
  //     final today = DateTime(now.year, now.month, now.day);

  //     // Check for existing records for today
  //     final todayRecords = users.where((user) {
  //       if (user.name.toLowerCase() != widget.currentUserName.toLowerCase()) {
  //         return false;
  //       }
  //       if (user.checkIn == null) {
  //         return false;
  //       }
  //       final checkInDate = DateTime(
  //         user.checkIn!.year,
  //         user.checkIn!.month,
  //         user.checkIn!.day,
  //       );
  //       return checkInDate == today;
  //     }).toList();

  //     // Count records for today
  //     final recordCount = todayRecords.length;

  //     if (recordCount >= 1) {
  //       _showCustomSnackBar(
  //         context: context,
  //         message: "Attendance record already created for today.",
  //         backgroundColor: Colors.orangeAccent,
  //         icon: Icons.warning_amber,
  //       );
  //       return;
  //     }

  //     // Create new attendance record
  //     await _attendanceService.markAttendance(widget.currentUserName);
  //     await fetchAttendanceData();

  //     // Hide FAB, save timestamp, and start 5-minute timer
  //     setState(() {
  //       _isFabVisible = false;
  //     });
  //     await _saveFabHideTimestamp(); // Save the timestamp
  //     _fabTimer?.cancel(); // Cancel any existing timer
  //     _fabTimer = Timer(const Duration(minutes: 5), () async {
  //       setState(() {
  //         _isFabVisible = true;
  //       });
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.remove(_fabHideTimestampKey); // Clear the timestamp
  //     });

  //     _showCustomSnackBar(
  //       context: context,
  //       message: "Attendance record created successfully.",
  //       backgroundColor: Colors.green,
  //       icon: Icons.check_circle,
  //     );
  //   } catch (e) {
  //     _showCustomSnackBar(
  //       context: context,
  //       message: "Failed to create attendance record: $e",
  //       backgroundColor: Colors.redAccent,
  //       icon: Icons.error_outline,
  //     );
  //   }
  // }
  void createAttendanceRecord() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showCustomSnackBar(
          context: context,
          message: "Please turn on your location services.",
          backgroundColor: Colors.orangeAccent,
          icon: Icons.gps_off,
        );
        return;
      }

      bool isNearby = await isWithinAllowedRadius();
      if (!isNearby) {
        _showCustomSnackBar(
          context: context,
          message: "You must be at the office to check in.",
          backgroundColor: Colors.redAccent,
          icon: Icons.location_off,
        );
        return;
      }

      final istLocation = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.now(istLocation);
      final today = DateTime(now.year, now.month, now.day);

      // Check if already checked in today
      final alreadyCheckedIn = users.any((user) {
        if (user.name.toLowerCase() != widget.currentUserName.toLowerCase()) {
          return false;
        }
        if (user.checkIn == null) return false;
        final checkInDate = DateTime(
            user.checkIn!.year, user.checkIn!.month, user.checkIn!.day);
        return checkInDate == today;
      });

      if (alreadyCheckedIn) {
        _showCustomSnackBar(
          context: context,
          message: "You have already checked in today!",
          backgroundColor: Colors.orangeAccent,
          icon: Icons.check_circle_outline,
        );
        return;
      }

      // Step 1: Create attendance record
      await _attendanceService.markAttendance(widget.currentUserName);

      // Step 2: Immediately Check-In
      final attendance = Attendance(
        name: widget.currentUserName,
        checkIn: now,
        checkOut: null,
        lunchIn: null,
        lunchOut: null,
        daysPresent: 1, // since we're checking in
        totalHours: '00:00:00',
        lunchDurationDisplay: '00:00:00',
      );

      await _attendanceService.checkIn(attendance);

      // Refresh UI
      await fetchAttendanceData();

      // Hide FAB for 5 minutes
      setState(() {
        _isFabVisible = false;
      });
      await _saveFabHideTimestamp();
      _fabTimer?.cancel();
      _fabTimer = Timer(const Duration(minutes: 15), () async {
        setState(() {
          _isFabVisible = true;
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_fabHideTimestampKey);
      });

      _showCustomSnackBar(
        context: context,
        message: "Checked in successfully at ${formatTime(now)}",
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      String errorMsg = "Check-in failed: $e";
      if (e.toString().contains("404")) {
        errorMsg = "Server endpoint not found. Contact admin.";
      } else if (e.toString().contains("500")) {
        errorMsg = "Server error. Try again later.";
      }

      _showCustomSnackBar(
        context: context,
        message: errorMsg,
        backgroundColor: Colors.redAccent,
        icon: Icons.error_outline,
      );
    }
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 7, 56, 80)),
              )
            : Padding(
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
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search team members...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterUsers();
                                    },
                                  ),
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
                                    color: _selectedDate != null
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _selectedDate ?? DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                      builder: (BuildContext context,
                                          Widget? child) {
                                        return Theme(
                                          data: ThemeData.light().copyWith(
                                            colorScheme:
                                                const ColorScheme.light(
                                              primary: Color.fromARGB(
                                                  255, 7, 56, 80),
                                              onPrimary: Colors.white,
                                            ),
                                            textButtonTheme:
                                                TextButtonThemeData(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors
                                                    .red, // Cancel button color
                                              ),
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null &&
                                        picked != _selectedDate) {
                                      setState(() {
                                        _selectedDate = picked;
                                      });
                                      _filterUsers();
                                    }
                                  },
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? const Center(
                              child: Text(
                                "No attendance records available. Start by creating one.",
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
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  color: Colors.white,
                                  shadowColor: Colors.black.withOpacity(0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                255,
                                                7,
                                                56,
                                                80,
                                              ),
                                              child: Text(
                                                user.name[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildInfoRow(
                                          icon: Icons.login,
                                          color: Colors.green,
                                          label: "Check-In",
                                          value: formatTime(user.checkIn),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.restaurant_menu,
                                          color: Colors.orange,
                                          label: "Lunch Out",
                                          value: formatTime(user.lunchOut),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.restaurant,
                                          color: Colors.blue,
                                          label: "Lunch In",
                                          value: formatTime(user.lunchIn),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.logout,
                                          color: Colors.red,
                                          label: "Check-Out",
                                          value: formatTime(user.checkOut),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.timer,
                                          color: Colors.black54,
                                          label: "Lunch Duration",
                                          value: user.lunchDurationDisplay,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildInfoRow(
                                          icon: Icons.access_time,
                                          color: Colors.black54,
                                          label: "Total Hours",
                                          value: user.totalHours,
                                        ),
                                        const SizedBox(height: 5),
                                        if (!widget.isAdmin)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.daysPresent ==
                                                              0 ||
                                                          user.checkIn != null
                                                      ? null
                                                      : () =>
                                                          markCheckIn(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Check In',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.checkIn ==
                                                              null ||
                                                          user.lunchOut != null
                                                      ? null
                                                      : () =>
                                                          markLunchOut(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Lunch Out',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.lunchOut ==
                                                              null ||
                                                          user.lunchIn != null
                                                      ? null
                                                      : () =>
                                                          markLunchIn(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Lunch In',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: user.lunchIn ==
                                                              null ||
                                                          user.checkOut != null
                                                      ? null
                                                      : () =>
                                                          markCheckOut(index),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red[700],
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    elevation: 2,
                                                  ),
                                                  child: const Text(
                                                    'Check Out',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              if (widget.isAdmin) {
                                                final reports =
                                                    await _attendanceService
                                                        .fetchAllEmployeesAttendanceReport(
                                                  month: DateTime.now()
                                                      .month
                                                      .toString()
                                                      .padLeft(
                                                        2,
                                                        '0',
                                                      ),
                                                  year: DateTime.now().year,
                                                );

                                                final userReport =
                                                    reports.firstWhere(
                                                  (report) =>
                                                      report.employeeName
                                                          .toLowerCase() ==
                                                      user.name.toLowerCase(),
                                                  orElse: () =>
                                                      AttendanceReport(
                                                    employeeId: 0,
                                                    employeeName: user.name,
                                                    month: DateTime.now()
                                                        .month
                                                        .toString()
                                                        .padLeft(
                                                          2,
                                                          '0',
                                                        ),
                                                    year: DateTime.now().year,
                                                    daysPresent: 0,
                                                    totalHours: '00:00:00',
                                                    fullLeaveDays: 0,
                                                    halfLeaveDays: 0,
                                                    wfhDays: 0,
                                                    department: '',
                                                    totalLunchDuration: '',
                                                  ),
                                                );

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (
                                                      context,
                                                    ) =>
                                                        UserReportPage(
                                                      attendanceReport:
                                                          userReport,
                                                      currentUserName:
                                                          user.name,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                final reports =
                                                    await _attendanceService
                                                        .fetchAllEmployeesAttendanceReport(
                                                  month: DateTime.now()
                                                      .month
                                                      .toString()
                                                      .padLeft(
                                                        2,
                                                        '0',
                                                      ),
                                                  year: DateTime.now().year,
                                                );

                                                final userReport =
                                                    reports.firstWhere(
                                                  (report) =>
                                                      report.employeeName
                                                          .toLowerCase() ==
                                                      widget.currentUserName
                                                          .toLowerCase(),
                                                  orElse: () => throw Exception(
                                                    'Report not found for ${widget.currentUserName}',
                                                  ),
                                                );

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (
                                                      context,
                                                    ) =>
                                                        UserReportPage(
                                                      attendanceReport:
                                                          userReport,
                                                      currentUserName: widget
                                                          .currentUserName,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              _showCustomSnackBar(
                                                context: context,
                                                message:
                                                    "Failed to load report: $e",
                                                backgroundColor:
                                                    Colors.redAccent,
                                                icon: Icons.error_outline,
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 7, 56, 80),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            elevation: 2,
                                            minimumSize:
                                                const Size(double.infinity, 0),
                                          ),
                                          child: const Text(
                                            'View Report',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: !widget.isAdmin && _isFabVisible
          ? FloatingActionButton(
              onPressed: createAttendanceRecord,
              backgroundColor: const Color.fromARGB(255, 7, 56, 80),
              tooltip: 'Create Attendance Record',
              child: const Icon(Icons.add, color: Colors.orange),
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
          "$label: $value",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
