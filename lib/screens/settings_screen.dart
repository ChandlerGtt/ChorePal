import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/theme_service.dart';
import '../models/user_state.dart';
import '../models/user.dart';
import '../utils/chorepal_colors.dart';
import '../widgets/glassmorphism_card.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  bool? _isChild; // null = unknown, true = child, false = parent
  bool _isLoadingPreferences = false;

  @override
  void initState() {
    super.initState();
    _determineUserType();
    _loadPreferences();
  }

  // Determine if user is child or parent immediately from SharedPreferences
  Future<void> _determineUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedChildId = prefs.getString('child_user_id');
      final storedFamilyId = prefs.getString('child_family_id');
      
      setState(() {
        _isChild = (storedChildId != null && storedFamilyId != null);
      });
    } catch (e) {
      print('Error determining user type: $e');
      // Default to parent if we can't determine
      setState(() {
        _isChild = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Load preference values asynchronously (doesn't block UI)
  Future<void> _loadPreferences() async {
    if (_isLoadingPreferences || !mounted) {
      return;
    }

    try {
      _isLoadingPreferences = true;
      final userState = Provider.of<UserState>(context, listen: false);
      
      // Try to load user data, but don't block if it fails
      if (userState.currentUser == null) {
        await userState.loadCurrentUser();
      }

      if (userState.currentUser != null && mounted) {
        final user = userState.currentUser!;
        setState(() {
          _pushNotificationsEnabled = user.pushNotificationsEnabled;
          _emailNotificationsEnabled = user.emailNotificationsEnabled;
          _smsNotificationsEnabled = user.smsNotificationsEnabled;

          // Load phone number (masked for display) - only for parents
          if (user is Parent && user.phoneNumber != null) {
            _phoneNumberController.text = _maskPhoneNumber(user.phoneNumber!);
          }

          // Load email - only for parents
          if (user is Parent) {
            _emailController.text = user.email;
          }
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
      // Don't show error to user - preferences will use defaults
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPreferences = false;
        });
      }
    }
  }

  Future<void> _saveThemePreference(bool isDarkMode) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    await themeService.toggleTheme(isDarkMode);
    // Theme will update automatically via ChangeNotifier
  }

  Future<void> _savePushNotificationPreference(bool enabled) async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = _authService.currentUser?.uid;

      if (userId == null) return;

      await _firestoreService.updateNotificationPreferences(
        userId,
        pushNotificationsEnabled: enabled,
      );

      setState(() {
        _pushNotificationsEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Push notifications enabled'
                : 'Push notifications disabled',
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reload user to get updated preferences
      await userState.loadCurrentUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update preference: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveEmailNotificationPreference(bool enabled) async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = _authService.currentUser?.uid;

      if (userId == null) return;

      await _firestoreService.updateNotificationPreferences(
        userId,
        emailNotificationsEnabled: enabled,
      );

      setState(() {
        _emailNotificationsEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Email notifications enabled'
                : 'Email notifications disabled',
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reload user to get updated preferences
      await userState.loadCurrentUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update preference: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveSmsNotificationPreference(bool enabled) async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = _authService.currentUser?.uid;

      if (userId == null) return;

      // Validate phone number if enabling SMS
      if (enabled) {
        final actualPhoneNumber = _getActualPhoneNumber();
        if (actualPhoneNumber == null || actualPhoneNumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Phone number is required to enable SMS notifications'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _smsNotificationsEnabled = false;
          });
          return;
        }

        // Basic E.164 format validation
        if (!actualPhoneNumber.startsWith('+')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Phone number must be in E.164 format (e.g., +18777804236)'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _smsNotificationsEnabled = false;
          });
          return;
        }

        await _firestoreService.updateNotificationPreferences(
          userId,
          smsNotificationsEnabled: enabled,
          phoneNumber: actualPhoneNumber,
        );
      } else {
        await _firestoreService.updateNotificationPreferences(
          userId,
          smsNotificationsEnabled: enabled,
        );
      }

      setState(() {
        _smsNotificationsEnabled = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'SMS notifications enabled'
                : 'SMS notifications disabled',
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      // Reload user to get updated preferences
      await userState.loadCurrentUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to update preference: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Reset toggle on error
      setState(() {
        _smsNotificationsEnabled = !enabled;
      });
    }
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length <= 5) return phoneNumber;
    // Show first 5 characters and mask the rest with dots
    return '${phoneNumber.substring(0, 5)}${'.' * (phoneNumber.length - 5)}';
  }

  String? _getActualPhoneNumber() {
    final userState = Provider.of<UserState>(context, listen: false);
    final user = userState.currentUser;
    if (user is Parent && user.phoneNumber != null) {
      return user.phoneNumber;
    }
    return null;
  }

  Future<void> _savePhoneNumber() async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = _authService.currentUser?.uid;

      if (userId == null) return;

      // Get actual phone number from user data (not masked display)
      final actualPhoneNumber = _getActualPhoneNumber();
      final phoneNumber =
          actualPhoneNumber ?? _phoneNumberController.text.trim();

      // If SMS is enabled and phone number is empty, show error
      if (_smsNotificationsEnabled &&
          (phoneNumber.isEmpty || actualPhoneNumber == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Phone number is required when SMS notifications are enabled'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Basic E.164 format validation if phone number is provided
      if (phoneNumber.isNotEmpty && !phoneNumber.startsWith('+')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Phone number must be in E.164 format (e.g., +18777804236)'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _firestoreService.updateNotificationPreferences(
        userId,
        phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number saved'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Reload user to get updated preferences
      await userState.loadCurrentUser();

      // Update masked display
      if (userState.currentUser != null) {
        final user = userState.currentUser!;
        if (user is Parent && user.phoneNumber != null) {
          _phoneNumberController.text = _maskPhoneNumber(user.phoneNumber!);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to save phone number: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showPhoneNumberEditDialog() async {
    final actualPhoneNumber = _getActualPhoneNumber() ?? '';
    final phoneController = TextEditingController(text: actualPhoneNumber);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+18777804236 (E.164 format)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, phoneController.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      // Validate format
      if (result.isNotEmpty && !result.startsWith('+')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Phone number must be in E.164 format (e.g., +18777804236)'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Save the phone number
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        try {
          await _firestoreService.updateNotificationPreferences(
            userId,
            phoneNumber: result.isEmpty ? null : result,
          );

          await userState.loadCurrentUser();

          // Update masked display
          if (userState.currentUser != null) {
            final user = userState.currentUser!;
            if (user is Parent && user.phoneNumber != null) {
              _phoneNumberController.text = _maskPhoneNumber(user.phoneNumber!);
            } else {
              _phoneNumberController.text = '';
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number saved'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to save phone number: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveEmail() async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final user = userState.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not found. Please log in again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Use the user ID from the user object instead of AuthService
      final userId = user.id;
      final email = _emailController.text.trim();

      print(
          'Saving email for user: $userId, isParent: ${user.isParent}, email: $email');

      // Validate email format if provided (client-side validation)
      if (email.isNotEmpty) {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(email)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid email address'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      // Always pass email (even if empty string) to allow saving or clearing it
      print('Calling updateNotificationPreferences with email: $email');
      await _firestoreService.updateNotificationPreferences(
        userId,
        email: email, // Pass the email string (empty or filled)
      );

      print('Email update completed for user: $userId');

      // Reload user to get updated preferences
      await userState.loadCurrentUser();

      // Verify the email was saved
      final updatedUser = userState.currentUser;
      if (updatedUser is Parent) {
        print('Updated parent email: ${updatedUser.email}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error saving email: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to save email: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ChorePalColors.primaryGradient,
          ),
        ),
        title: const Text('Settings'),
      ),
      body: Builder(
        builder: (context) {
          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
          return Container(
            decoration: BoxDecoration(
              gradient: isDarkMode
                  ? ChorePalColors.darkBackgroundGradient
                  : ChorePalColors.backgroundGradient,
            ),
            child: Builder(
              builder: (context) {
                // Use _isChild from state (determined from SharedPreferences)
                // If still unknown, default to showing parent UI (safer default)
                final isChild = _isChild ?? false;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 16),
                    // Appearance Section
                    GlassmorphismCard(
                      borderRadius: 20,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: ChorePalColors.accentGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.palette,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Appearance',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : ChorePalColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Theme Switch
                          _buildSettingTile(
                            title: 'Dark Mode',
                            subtitle: 'Switch between light and dark theme',
                            icon: Icons.dark_mode,
                            trailing: Switch(
                              value: themeService.isDarkMode,
                              onChanged: _saveThemePreference,
                              activeThumbColor: ChorePalColors.darkBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notifications Section
                    GlassmorphismCard(
                      borderRadius: 20,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      ChorePalColors.sunshineOrange,
                                      ChorePalColors.strawberryPink,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : ChorePalColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildSettingTile(
                            title: 'Push Notifications',
                            subtitle:
                                'Receive push notifications on your device',
                            icon: Icons.notifications_active,
                            trailing: Switch(
                              value: _pushNotificationsEnabled,
                              onChanged: _savePushNotificationPreference,
                              activeThumbColor: ChorePalColors.darkBlue,
                            ),
                          ),
                          // Only show email/SMS options and phone/email inputs for parents
                          if (!isChild) ...[
                            _buildSettingTile(
                              title: 'Email Notifications',
                              subtitle: 'Receive notifications via email',
                              icon: Icons.email,
                              trailing: Switch(
                                value: _emailNotificationsEnabled,
                                onChanged: _saveEmailNotificationPreference,
                                activeThumbColor: ChorePalColors.darkBlue,
                              ),
                            ),
                            _buildSettingTile(
                              title: 'SMS Notifications',
                              subtitle:
                                  'Receive notifications via text message',
                              icon: Icons.sms,
                              trailing: Switch(
                                value: _smsNotificationsEnabled,
                                onChanged: _saveSmsNotificationPreference,
                                activeThumbColor: ChorePalColors.darkBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Phone Number Input
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        color: ChorePalColors.skyBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Phone Number',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : ChorePalColors.textPrimary,
                                        ),
                                      ),
                                      if (_smsNotificationsEnabled)
                                        const Text(
                                          ' *',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _phoneNumberController,
                                    keyboardType: TextInputType.phone,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Tap edit icon to change phone number',
                                      hintStyle: TextStyle(
                                        color: isDarkMode
                                            ? Colors.grey.shade400
                                            : ChorePalColors.textSecondary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: _showPhoneNumberEditDialog,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : ChorePalColors.textPrimary,
                                    ),
                                  ),
                                  if (_smsNotificationsEnabled &&
                                      _phoneNumberController.text.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Phone number is required when SMS notifications are enabled',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _savePhoneNumber,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            ChorePalColors.darkBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Save Phone Number'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Email Input
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email,
                                        color: ChorePalColors.skyBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Email Address',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : ChorePalColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        ' (Optional)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: isDarkMode
                                              ? Colors.grey.shade400
                                              : ChorePalColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      hintText: 'your.email@example.com',
                                      hintStyle: TextStyle(
                                        color: isDarkMode
                                            ? Colors.grey.shade400
                                            : ChorePalColors.textSecondary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                    ),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : ChorePalColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        print('Save Email button pressed');
                                        _saveEmail();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            ChorePalColors.darkBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Save Email'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Account Section
                    GlassmorphismCard(
                      borderRadius: 20,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      ChorePalColors.skyBlue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: ChorePalColors.skyBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Account',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : ChorePalColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildActionTile(
                            title: 'Logout',
                            subtitle: 'Sign out of your account',
                            icon: Icons.logout,
                            iconColor: Colors.red,
                            onTap: _handleLogout,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ChorePalColors.skyBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: ChorePalColors.skyBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? Colors.grey.shade300
                        : ChorePalColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? Colors.white
                          : ChorePalColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? Colors.grey.shade300
                          : ChorePalColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: ChorePalColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
