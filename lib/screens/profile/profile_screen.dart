import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart_census/screens/auth/login_screen.dart';
import 'package:smart_census/services/auth_service.dart';
import 'package:smart_census/services/database_service.dart';
import 'package:smart_census/services/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _surveyorName = "Not set";
  int _totalSurveys = 0;
  int _syncedSurveys = 0;
  int _pendingSurveys = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadStats();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _surveyorName = prefs.getString('surveyor_name') ?? "Not set";
    });
  }

  Future<void> _loadStats() async {
    try {
      final allSurveys = DatabaseService().getAllSurveys();
      setState(() {
        _totalSurveys = allSurveys.length;
        _syncedSurveys = allSurveys.where((s) => s.isSynced).length;
        _pendingSurveys = _totalSurveys - _syncedSurveys;
      });
    } catch (e) {
      print("Error loading stats: $e");
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
        text: _surveyorName == "Not set" ? "" : _surveyorName);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        title: Text('Edit Name',
            style: GoogleFonts.inter(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your name"),
          autofocus: true,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: isDark ? Colors.grey : Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('surveyor_name', newName);
      setState(() {
        _surveyorName = newName;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_role');
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      print("DEBUG: Firebase not initialized (Test Mode active)");
    }
    final phoneNumber = user?.phoneNumber ?? "+91 9999999999";

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = theme.cardTheme.color;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Profile Avatar & Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.blue.shade50,
                        child: Icon(Icons.person_outline,
                            size: 45, color: theme.colorScheme.primary),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Profile picture upload coming soon")));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 3),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        phoneNumber,
                        style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {}, // Future link to account settings
                        child: Icon(Icons.edit_outlined,
                            size: 18, color: subtitleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3A5F)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          "Census Surveyor",
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stats Row
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  _buildStatItem("Surveys", _totalSurveys.toString(), textColor,
                      subtitleColor),
                  _buildDivider(isDark),
                  _buildStatItem("Synced", _syncedSurveys.toString(), textColor,
                      subtitleColor),
                  _buildDivider(isDark),
                  _buildStatItem("Pending", _pendingSurveys.toString(),
                      textColor, subtitleColor),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("APPEARANCE", subtitleColor),
            const SizedBox(height: 8),
            _buildThemeSelector(
                context,
                cardColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                textColor),

            const SizedBox(height: 24),
            _buildSectionHeader("ACCOUNT", subtitleColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildListTile(Icons.person_outline, "Surveyor Name",
                      _surveyorName, isDark, textColor, subtitleColor,
                      onTap: _editName),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(Icons.phone_outlined, "Phone Number",
                      phoneNumber, isDark, textColor, subtitleColor),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(Icons.assignment_ind_outlined, "Role",
                      "Surveyor", isDark, textColor, subtitleColor),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(Icons.location_on_outlined, "Assigned Area",
                      "Delhi (Ward 05)", isDark, textColor, subtitleColor),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader("GENERAL", subtitleColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildListTile(Icons.help_outline, "Help & Support", "",
                      isDark, textColor, subtitleColor,
                      showChevron: true),
                  const Divider(height: 1, indent: 56),
                  _buildListTile(Icons.logout, "Log Out", "", isDark,
                      Colors.red, Colors.red,
                      onTap: () => _signOut(context)),
                ],
              ),
            ),
            const SizedBox(height: 48), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color textColor, Color subtitleColor) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: subtitleColor)),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle,
      bool isDark, Color titleColor, Color subtitleColor,
      {VoidCallback? onTap, bool showChevron = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: subtitleColor, size: 22),
      title: Text(title,
          style: GoogleFonts.inter(fontSize: 12, color: subtitleColor)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: titleColor))
          : null,
      trailing:
          showChevron ? Icon(Icons.chevron_right, color: subtitleColor) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, Color cardColor, Color textColor) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildThemeOption("Light", Icons.light_mode_outlined, ThemeMode.light,
              themeProvider, isDark, textColor),
          _buildThemeOption("Dark", Icons.dark_mode_outlined, ThemeMode.dark,
              themeProvider, isDark, textColor),
          _buildThemeOption("System", Icons.phone_android_outlined,
              ThemeMode.system, themeProvider, isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, IconData icon, ThemeMode mode,
      ThemeProvider provider, bool isDark, Color textColor) {
    final isSelected = provider.themeMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? primaryColor.withOpacity(0.2) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: isSelected ? primaryColor : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
