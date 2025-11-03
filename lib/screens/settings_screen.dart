import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.loadCurrentUser();
      
      if (userState.currentUser != null) {
        final user = userState.currentUser!;
        setState(() {
          _pushNotificationsEnabled = user.pushNotificationsEnabled;
          _emailNotificationsEnabled = user.emailNotificationsEnabled;
          _smsNotificationsEnabled = user.smsNotificationsEnabled;
          
          if (user is Parent && user.phoneNumber != null) {
            _phoneNumberController.text = user.phoneNumber!;
          } else if (user is Child && user.phoneNumber != null) {
            _phoneNumberController.text = user.phoneNumber!;
          }
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
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
            enabled ? 'Push notifications enabled' : 'Push notifications disabled',
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
            enabled ? 'Email notifications enabled' : 'Email notifications disabled',
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
        final phoneNumber = _phoneNumberController.text.trim();
        if (phoneNumber.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Phone number is required to enable SMS notifications'),
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
        if (!phoneNumber.startsWith('+')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Phone number must be in E.164 format (e.g., +12148433202)'),
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
          phoneNumber: phoneNumber,
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
            enabled ? 'SMS notifications enabled' : 'SMS notifications disabled',
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
          content: Text('Failed to update preference: ${e.toString().replaceAll('Exception: ', '')}'),
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

  Future<void> _savePhoneNumber() async {
    try {
      final userState = Provider.of<UserState>(context, listen: false);
      final userId = _authService.currentUser?.uid;
      
      if (userId == null) return;
      
      final phoneNumber = _phoneNumberController.text.trim();
      
      // If SMS is enabled and phone number is empty, show error
      if (_smsNotificationsEnabled && phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone number is required when SMS notifications are enabled'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // Basic E.164 format validation if phone number is provided
      if (phoneNumber.isNotEmpty && !phoneNumber.startsWith('+')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Phone number must be in E.164 format (e.g., +12148433202)'),
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
        SnackBar(
          content: const Text('Phone number saved'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Reload user to get updated preferences
      await userState.loadCurrentUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save phone number: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            child: ListView(
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
                          color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
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
                      activeColor: ChorePalColors.darkBlue,
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
                          gradient: LinearGradient(
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
                          color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingTile(
                    title: 'Push Notifications',
                    subtitle: 'Receive push notifications on your device',
                    icon: Icons.notifications_active,
                    trailing: Switch(
                      value: _pushNotificationsEnabled,
                      onChanged: _savePushNotificationPreference,
                      activeColor: ChorePalColors.darkBlue,
                    ),
                  ),
                  _buildSettingTile(
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    icon: Icons.email,
                    trailing: Switch(
                      value: _emailNotificationsEnabled,
                      onChanged: _saveEmailNotificationPreference,
                      activeColor: ChorePalColors.darkBlue,
                    ),
                  ),
                  _buildSettingTile(
                    title: 'SMS Notifications',
                    subtitle: 'Receive notifications via text message',
                    icon: Icons.sms,
                    trailing: Switch(
                      value: _smsNotificationsEnabled,
                      onChanged: _saveSmsNotificationPreference,
                      activeColor: ChorePalColors.darkBlue,
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
                            Icon(
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
                                color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                              ),
                            ),
                            if (_smsNotificationsEnabled)
                              Text(
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
                          decoration: InputDecoration(
                            hintText: '+12148433202 (E.164 format)',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.grey.shade400 : ChorePalColors.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: isDarkMode 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                          ),
                          onChanged: (value) {
                            // Auto-save phone number after user stops typing (optional)
                            // For now, we'll save on button press or when SMS toggle changes
                          },
                        ),
                        if (_smsNotificationsEnabled && _phoneNumberController.text.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
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
                              backgroundColor: ChorePalColors.darkBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Save Phone Number'),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          color: ChorePalColors.skyBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
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
                          color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
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
                    color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey.shade300 : ChorePalColors.textSecondary,
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
                      color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey.shade300 : ChorePalColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: ChorePalColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

