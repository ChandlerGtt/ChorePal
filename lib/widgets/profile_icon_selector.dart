// lib/widgets/profile_icon_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/user_state.dart';
import '../utils/chorepal_colors.dart';

/// Profile icon selector widget that shows boy/girl options
class ProfileIconSelector {
  /// Shows the profile icon selection bottom sheet
  static void show(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _ProfileIconSelectorSheet(user: user);
      },
    );
  }
}

class _ProfileIconSelectorSheet extends StatefulWidget {
  final User user;

  const _ProfileIconSelectorSheet({required this.user});

  @override
  State<_ProfileIconSelectorSheet> createState() =>
      _ProfileIconSelectorSheetState();
}

class _ProfileIconSelectorSheetState extends State<_ProfileIconSelectorSheet> {
  String? _selectedIcon;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.user.profileIcon;
  }

  Future<void> _saveProfileIcon() async {
    if (_selectedIcon == widget.user.profileIcon) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userState = Provider.of<UserState>(context, listen: false);
      await userState.updateProfileIcon(widget.user.id, _selectedIcon);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile icon updated!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Profile Icon',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Icon options
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Boy icon option
                _buildIconOption(
                  context: context,
                  icon: Icons.boy,
                  label: 'Boy',
                  value: 'boy',
                  color: ChorePalColors.skyBlue,
                  isDarkMode: isDarkMode,
                ),
                // Girl icon option
                _buildIconOption(
                  context: context,
                  icon: Icons.girl,
                  label: 'Girl',
                  value: 'girl',
                  color: ChorePalColors.strawberryPink,
                  isDarkMode: isDarkMode,
                ),
                // Default (initial) option
                _buildIconOption(
                  context: context,
                  icon: Icons.person,
                  label: 'Initial',
                  value: null,
                  color: ChorePalColors.darkBlue,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfileIcon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChorePalColors.darkBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String? value,
    required Color color,
    required bool isDarkMode,
  }) {
    final isSelected = _selectedIcon == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIcon = value;
        });
      },
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.2)
              : (isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 36,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

