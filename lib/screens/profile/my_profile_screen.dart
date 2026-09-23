import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vote_sense/screens/profile/terms_and_privacy_policy_screen.dart';
import '../auth/landing_screen.dart';
import 'help_and_legal_support_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _notificationsEnabled = true;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _verifiedAccount = false;
  bool? registeredLawyer = false;
  bool _isUploading = false;
  bool? isVerified = false;

  // Updated to primary green and light mode backgrounds
  static const Color primaryColor = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  String? fName;
  String? lName;
  String? pNumber;

  @override
  void initState() {
    super.initState();
    _setDefaults();
    _checkVerification();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    await _loadNotificationPreference();
  }

  String _getInitials(String firstName, String lastName) {
    final String f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final String l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    final String combined = '$f$l';
    return combined.isEmpty ? 'U' : combined;
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (mounted) {}
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) _showSnackBar('Could not launch application.');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Could not open link.');
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final File imageFile = File(pickedFile.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      await _firestore
          .collection('new-users')
          .doc(currentUser.uid)
          .set({'profilePicture': base64Image}, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('Profile picture updated!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to update picture: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: primaryColor),
                title: const Text('Choose from Gallery', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: primaryColor),
                title: const Text('Take a Photo', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditProfileDialog({
    required String currentFirstName,
    required String currentLastName,
    required String currentPhone,
  }) async {
    final TextEditingController firstNameController = TextEditingController(text: currentFirstName);
    final TextEditingController lastNameController = TextEditingController(text: currentLastName);
    final TextEditingController phoneController = TextEditingController(text: currentPhone);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Personal Info', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: firstNameController,
                    style: const TextStyle(color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('First Name', Icons.person_outline),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: lastNameController,
                    style: const TextStyle(color: Color(0xFF1E293B)),
                    decoration: _inputDecoration('Last Name', Icons.person_outline),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    style: const TextStyle(color: Color(0xFF1E293B)),
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                onPressed: isSaving ? null : () async {
                  if (!formKey.currentState!.validate()) return;

                  setDialogState(() => isSaving = true);

                  try {
                    await _firestore.collection('new-users').doc(_auth.currentUser!.uid).update({
                      'firstName': firstNameController.text.trim(),
                      'lastName': lastNameController.text.trim(),
                      'phoneNumber': phoneController.text.trim(),
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      _showSnackBar('Profile updated!', isError: false);
                    }
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    _showSnackBar('Failed to update: $e');
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _showUpdatePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isSaving = false;
    bool isObscured = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Change Password', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: isObscured,
                  style: const TextStyle(color: Color(0xFF1E293B)),
                  decoration: _inputDecoration('Current Password', Icons.lock_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: isObscured,
                  style: const TextStyle(color: Color(0xFF1E293B)),
                  decoration: _inputDecoration('New Password', Icons.lock_rounded),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: isObscured,
                  style: const TextStyle(color: Color(0xFF1E293B)),
                  decoration: _inputDecoration('Confirm Password', Icons.lock_rounded),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setDialogState(() => isObscured = !isObscured),
                    child: Text(isObscured ? 'Show Passwords' : 'Hide Passwords', style: const TextStyle(color: primaryColor)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                onPressed: isSaving ? null : () async {
                  if (newPasswordController.text != confirmPasswordController.text) {
                    _showSnackBar('Passwords do not match');
                    return;
                  }
                  if (newPasswordController.text.length < 6) {
                    _showSnackBar('Password must be at least 6 characters');
                    return;
                  }

                  setDialogState(() => isSaving = true);

                  try {
                    final user = _auth.currentUser!;
                    final cred = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPasswordController.text.trim()
                    );
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(newPasswordController.text.trim());

                    if (mounted) {
                      Navigator.pop(context);
                      _showSnackBar('Password updated successfully!', isError: false);
                    }
                  } on FirebaseAuthException catch (e) {
                    setDialogState(() => isSaving = false);
                    _showSnackBar(e.message ?? 'Failed to update password');
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
    prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
    filled: true,
    fillColor: lightBackground,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
  );

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LandingScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to sign out: ${e.toString()}');
      }
    }
  }

  Future<bool> emailExists(String email) async {
    if (email.isEmpty) return false;
    final snapshot = await FirebaseFirestore.instance
        .collection('lawyers')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<bool> isUserVerified(String email) async {
    if (email.trim().isEmpty) return false;

    try {
      final snapshot = await _firestore
          .collection('lawyers')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      final data = snapshot.docs.first.data();

      return data['isVerified'] == true;
    } catch (e) {
      debugPrint('Error checking lawyer verification: $e');
      return false;
    }
  }

  Future<void> _checkVerification() async {
    final email = _auth.currentUser?.email ?? '';

    if (email.trim().isEmpty) {
      if (mounted) {
        setState(() {
          isVerified = false;
        });
      }
      return;
    }

    final verified = await isUserVerified(email);

    if (mounted) {
      setState(() {
        isVerified = verified;
      });
    }
  }

  Future<void> _setDefaults() async {
    final email = _auth.currentUser?.email ?? "";
    final exists = await emailExists(email);
    if (mounted) {
      setState(() {
        registeredLawyer = exists;
      });
    }
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _handleNotificationToggle(bool val) async {
    if (val) {
      bool granted = await _requestDevicePermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission denied in system settings.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _notificationsEnabled = val;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', val);
  }

  Future<bool> _requestDevicePermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final bool? granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      final bool? granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: const Color(0xFF64748B),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Color(0xFF94A3B8),
        size: 14,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required VoidCallback onTap,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(
        icon,
        color: const Color(0xFF64748B),
        size: 22,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 12,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: primaryColor,
        onChanged: onChanged,
      ),
      onTap: onTap,
    );
  }

  void _showSuccessDialog(bool isVerified) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isVerified == true ? "Already Verified" : "Verification Required",
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isVerified == true ? "Your identity as a lawyer has been verified. Thank you." : "To verify your identity as a lawyer, kindly send your identity card and your SCN to openlawsnig@gmail.com",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => isVerified == true ? Navigator.of(context).pop() : _launchUrl('mailto:openlawsnig@gmail.com?subject=OpenLawsNig Verification Request'),
                child: Text(
                  isVerified == true ? "Done" : "Send Now",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E293B),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Profile',
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: currentUser != null
                      ? _firestore
                      .collection('new-users')
                      .doc(currentUser.uid)
                      .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    String firstName = '';
                    String lastName = '';
                    String email = currentUser?.email ?? 'No email provided';
                    String profilePictureBase64 = '';

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      firstName = data['firstName'] ?? '';
                      lastName = data['lastName'] ?? '';
                      email = data['email'] ?? email;
                      profilePictureBase64 = data['profilePicture'] ?? '';
                      fName = data['firstName'] ?? '';
                      lName = data['lastName'] ?? '';
                      pNumber = data['phoneNumber'] ?? '';
                    } else if (currentUser?.displayName != null) {
                      final parts = currentUser!.displayName!.split(' ');
                      firstName = parts.isNotEmpty ? parts[0] : '';
                      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                      fName = firstName;
                      lName = lastName;
                    }

                    final String fullName = '$firstName $lastName'.trim();
                    final String initials = _getInitials(firstName, lastName);

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _isUploading ? null : _showImagePickerModal,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                                  backgroundImage: profilePictureBase64.isNotEmpty
                                      ? MemoryImage(base64Decode(profilePictureBase64))
                                      : null,
                                  child: _isUploading
                                      ? const CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 2,
                                  )
                                      : (profilePictureBase64.isEmpty
                                      ? Text(
                                    initials,
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                      : null),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName.isNotEmpty ? fullName : 'VoteSense User',
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Account & Security'),
                    const SizedBox(height: 12),
                    _buildSettingsGroup([
                      _buildListTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        subtitle: 'Update name and phone number',
                        onTap: () {
                          _showEditProfileDialog(
                            currentFirstName: fName ?? "",
                            currentLastName: lName ?? "",
                            currentPhone: pNumber ?? "",
                          );
                        },
                      ),
                      Divider(height: 1, color: Colors.black.withValues(alpha: 0.06), indent: 56),
                      _buildListTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: _showUpdatePasswordDialog,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Preferences & Support'),
                    const SizedBox(height: 12),
                    _buildSettingsGroup([
                      _buildSwitchTile(
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Enable or disable alerts',
                        value: _notificationsEnabled,
                        onTap: () => _handleNotificationToggle(!_notificationsEnabled),
                        onChanged: _handleNotificationToggle,
                      ),
                      Divider(height: 1, color: Colors.black.withValues(alpha: 0.06), indent: 56),
                      _buildListTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get assistance or contact us',
                        onTap: () => _navigateTo(const HelpAndLegalSupportScreen()),
                      ),
                      Divider(height: 1, color: Colors.black.withValues(alpha: 0.06), indent: 56),
                      _buildListTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Terms & Privacy Policy',
                        subtitle: 'Read our legal guidelines',
                        onTap: () => _navigateTo(const TermsAndPrivacyPolicyScreen()),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSettingsGroup([
                      _buildListTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        subtitle: 'Log out from your account',
                        onTap: _handleSignOut,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}