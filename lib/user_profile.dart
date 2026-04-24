import 'package:dream_attend/Services/user_profile_service.dart';
import 'package:dream_attend/models/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'controller/app_constants.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/api_service.dart';
import 'utils/app_layout.dart';

class UserProfile extends StatefulWidget {
  final String name;
  final String address;
  final String mobile;
  final int numericId;
  final String jobTitle;

  const UserProfile({
    super.key,
    required this.name,
    required this.address,
    required this.mobile,
    required this.numericId,
    required this.jobTitle,
  });

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String _imagePath = 'assets/images/default.png';
  bool isEditing = false;
  File? _selectedImage;

  late String _name;
  late String _address;
  late String _mobile;
  late String _jobTitle;

  final Color _primaryColor = const Color.fromARGB(255, 7, 56, 80);

  final UserProfileService _userProfileService = UserProfileService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _address = widget.address;
    _mobile = widget.mobile;
    _jobTitle = widget.jobTitle;

    _loadSavedImage();
    _loadEmployeeProfile();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImage = prefs.getString('profile_image_${widget.numericId}');
    if (savedImage != null && savedImage.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _imagePath = savedImage;
        _selectedImage = null;
      });
    }
  }

  Future<void> _loadEmployeeProfile() async {
    try {
      final employeeData = await _userProfileService.fetchEmployeeProfile();
      final prefs = await SharedPreferences.getInstance();
      final savedImage = prefs.getString('profile_image_${widget.numericId}');

      if (!mounted) return;
      setState(() {
        _name = employeeData.name;
        _jobTitle = employeeData.jobTitle ?? _jobTitle;
        _mobile = employeeData.mobile ?? _mobile;
        _address = employeeData.address ?? _address;

        if (savedImage == null &&
            employeeData.image != null &&
            employeeData.image!.isNotEmpty) {
          _imagePath = employeeData.image!;
          _selectedImage = null;
          prefs.setString('profile_image_${widget.numericId}', _imagePath);
        }
      });
    } catch (e) {
      print('Error fetching employee profile: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      if (!mounted) return;
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _changePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update Profile Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildPhotoOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        _pickImage(ImageSource.camera);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPhotoOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        _pickImage(ImageSource.gallery);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _primaryColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          color: _primaryColor.withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: _primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editField(String title, String currentValue, Function(String) onSave) {
    TextEditingController controller =
        TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit $title',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: title,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                keyboardType: title == 'Mobile'
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: title == 'Mobile'
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ]
                    : [],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (controller.text.trim().isEmpty) {
                         showAppSnackBar(title: "Validation",message: "Field cannot be empty",type: AppSnackBarType.warning,);
                      } else {
                        onSave(controller.text.trim());
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Save',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    try {
      String? imageBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      if (widget.numericId <= 0) {
        throw Exception('Invalid employee ID');
      }

      final updateRequest = UpdateEmployeeRequest(
        employeeId: widget.numericId.toString(),
        jobTitle: _jobTitle.isEmpty ? null : _jobTitle,
        mobile: _mobile.isEmpty ? null : _mobile,
        address: _address.isEmpty ? null : _address,
        image: imageBase64,
      );

      print('Update request body: ${updateRequest.toJson()}');

      final response = await _userProfileService.updateEmployeeProfile(
        widget.numericId,
        updateRequest,
      );

      final prefs = await SharedPreferences.getInstance();
      if (imageBase64 != null) {
        await prefs.setString('profile_image_${widget.numericId}', imageBase64);
      } else if (response.image != null && response.image!.isNotEmpty) {
        await prefs.setString(
            'profile_image_${widget.numericId}', response.image!);
      }

      if (!mounted) return;
      setState(() {
        _name = response.name;
        _jobTitle = response.jobTitle ?? _jobTitle;
        _mobile = response.mobile ?? _mobile;
        _address = response.address ?? _address;
        if (imageBase64 != null) {
          _imagePath = imageBase64;
          _selectedImage = null;
        } else if (response.image != null && response.image!.isNotEmpty) {
          _imagePath = response.image!;
          _selectedImage = null;
        }
      });

      showAppSnackBar(message: "Profile updated successfully",type: AppSnackBarType.success,);
      
    } catch (e) {
      print('Error updating profile: $e');
      showAppSnackBar(message: "Unable to update profile. Please try again.",type: AppSnackBarType.error,);
      
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('sessionId');
      final playerId = prefs.getString('player_id');

      if (sessionId == null || sessionId.isEmpty) {
        throw Exception('No active session found');
      }

      final payload = playerId != null && playerId.isNotEmpty
          ? {'player_id': playerId}
          : {};

      final response = await _apiService.authenticatedPost(
        AppConstants.signoutEndpoint,
        payload,
        sessionId: sessionId,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == 'SUCCESS') {
        await _apiService.clearSessionData();

              showAppSnackBar(
          message: "Logout successful",
          type: AppSnackBarType.success,
        );

        Get.offAll(() => const MyHomePage(title: 'Login'));
      } else {
        throw Exception(responseData['message'] ?? 'Logout failed');
      }
    } catch (e) {
      print('Error during logout: $e');
      showAppSnackBar(message: "Unable to logout. Please try again.",type: AppSnackBarType.error,);
    }
  }

  Future<void> _archiveAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account.\n'
          'You will no longer be able to log in with these credentials.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _userProfileService.archiveAccount();

      await _apiService.clearSessionData();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );

     showAppSnackBar(
  message: "Account deleted successfully",
  type: AppSnackBarType.success,
);
    } catch (e) {
      print('delete error: $e');
    
    showAppSnackBar(
  message: "Failed to delete account",
  type: AppSnackBarType.error,
);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F9),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF073850),
        surfaceTintColor: const Color(0xFF073850),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                setState(() {
                  isEditing = !isEditing;
                });
              } else if (value == 'logout') {
                await _logout();
              } else if (value == 'delete') {
                await _archiveAccount();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      isEditing ? Icons.check : Icons.edit_outlined,
                      color: _primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEditing ? 'Done Editing' : 'Edit Profile',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.orangeAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Delete Account', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: isEditing ? _changePhoto : null,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : _imagePath.startsWith('assets/')
                                    ? AssetImage(_imagePath)
                                    : _imagePath.startsWith('http')
                                        ? NetworkImage(_imagePath)
                                        : MemoryImage(base64Decode(_imagePath))
                                            as ImageProvider,
                          ),
                        ),
                        if (isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF073850),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        _buildInfoItem(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _name,
                          onEdit: null,
                        ),
                        const Divider(height: 1),
                        _buildInfoItem(
                          icon: Icons.work_outline,
                          label: 'Job Title',
                          value: _jobTitle,
                          onEdit: isEditing
                              ? () =>
                                  _editField('Job Title', _jobTitle, (value) {
                                    setState(() => _jobTitle = value);
                                  })
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildInfoItem(
                          icon: Icons.phone_outlined,
                          label: 'Mobile Number',
                          value: _mobile,
                          onEdit: isEditing
                              ? () => _editField('Mobile', _mobile, (value) {
                                    setState(() => _mobile = value);
                                  })
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildInfoItem(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: _address,
                          onEdit: isEditing
                              ? () => _editField('Address', _address, (value) {
                                    setState(() => _address = value);
                                  })
                              : null,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          setState(() {
                            isEditing = false;
                          });
                          await _saveProfileChanges();
                        },
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: _primaryColor,
                size: 20,
              ),
              onPressed: onEdit,
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}
