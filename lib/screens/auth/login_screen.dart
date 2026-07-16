import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/screens/home/home_screen.dart';
import 'package:smart_census/screens/admin/admin_dashboard_screen.dart';
import 'package:smart_census/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String _verificationId = "";

  // Role selection
  bool _isAdmin = false; // false = Surveyor, true = Admin

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // --- TEST MODE CREDENTIALS ---
  static const String _testSurveyorPhone = '9999999999';
  static const String _testAdminPhone = '8888888888';
  static const String _testOtp = '123456';

  String get _currentTestPhone => _isAdmin ? _testAdminPhone : _testSurveyorPhone;

  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    // ✅ TEST MODE BYPASS
    if (phone == _currentTestPhone) {
      setState(() {
        _loading = false;
        _otpSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test Mode: OTP is 123456')),
        );
      }
      return;
    }

    setState(() => _loading = true);

    await AuthService().verifyPhoneNumber(
      '+91$phone',
      onVerificationCompleted: (credential) async {
        await AuthService().signInWithCredential(credential);
        setState(() => _loading = false);
        if (mounted) _navigateToHome();
      },
      onVerificationFailed: (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: ${e.message}')),
        );
      },
      onCodeSent: (verificationId, resendToken) {
        setState(() {
          _loading = false;
          _otpSent = true;
          _verificationId = verificationId;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Sent!')),
        );
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    // ✅ TEST MODE BYPASS
    if (_phoneController.text.trim() == _currentTestPhone &&
        _otpController.text == _testOtp) {
      await _saveRole();
      if (mounted) _navigateToHome();
      return;
    }

    setState(() => _loading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );

      final userCredential =
          await AuthService().signInWithCredential(credential);

      setState(() => _loading = false);

      if (userCredential != null && mounted) {
        await _saveRole();
        _navigateToHome();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Failed')),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', _isAdmin ? 'admin' : 'surveyor');
    await prefs.setString('user_phone', _phoneController.text.trim());
  }

  void _navigateToHome() {
    final destination =
        _isAdmin ? const AdminDashboardScreen() : const HomeScreen();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isAdmin
                ? [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)]
                : [const Color(0xFFEEF2FF), const Color(0xFFC7D2FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 8,
                  shadowColor: _isAdmin
                      ? const Color(0xFF302B63).withOpacity(0.3)
                      : const Color(0xFF4F46E5).withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  color: _isAdmin ? const Color(0xFF1C1C2E) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo / Icon Area
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isAdmin
                                    ? [const Color(0xFFFF6B35), const Color(0xFFFF4444)]
                                    : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isAdmin
                                          ? const Color(0xFFFF6B35)
                                          : const Color(0xFF4F46E5))
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.poll_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Role Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: _isAdmin
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              _buildRoleTab("Surveyor", Icons.person_search_rounded, !_isAdmin),
                              _buildRoleTab("Admin", Icons.shield_rounded, _isAdmin),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Header Text
                        Text(
                          _isAdmin ? 'Admin Login' : 'Welcome Back',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _isAdmin ? Colors.white : const Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAdmin
                              ? 'Sign in to manage your surveyors'
                              : 'Sign in to access your dashboard',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: _isAdmin
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),

                        // Test mode hint
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isAdmin
                                ? const Color(0xFFFF6B35).withOpacity(0.1)
                                : const Color(0xFF4F46E5).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isAdmin
                                  ? const Color(0xFFFF6B35).withOpacity(0.2)
                                  : const Color(0xFF4F46E5).withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16,
                                  color: _isAdmin
                                      ? const Color(0xFFFF6B35)
                                      : const Color(0xFF4F46E5)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _isAdmin
                                      ? 'Test: 8888888888 / OTP: 123456'
                                      : 'Test: 9999999999 / OTP: 123456',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: _isAdmin
                                        ? const Color(0xFFFF6B35)
                                        : const Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (!_otpSent) ...[
                          Text("Phone Number",
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _isAdmin
                                      ? Colors.grey.shade300
                                      : const Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: _isAdmin ? Colors.white : const Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              hintText: _isAdmin ? '8888888888' : '9876543210',
                              hintStyle: GoogleFonts.outfit(
                                  color: _isAdmin
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400),
                              prefixIcon: Icon(
                                  Icons.phone_android_rounded,
                                  size: 22,
                                  color: _isAdmin
                                      ? const Color(0xFFFF6B35)
                                      : const Color(0xFF4F46E5)),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 50),
                              prefixText: '+91 ',
                              prefixStyle: GoogleFonts.outfit(
                                  color: _isAdmin
                                      ? Colors.grey.shade300
                                      : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18),
                              counterText: "",
                              filled: true,
                              fillColor: _isAdmin
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _isAdmin
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _isAdmin
                                        ? const Color(0xFFFF6B35)
                                        : const Color(0xFF4F46E5),
                                    width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _sendOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isAdmin
                                    ? const Color(0xFFFF6B35)
                                    : const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : Text('Continue',
                                      style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ] else ...[
                          Text("Enter Verification Code",
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: _isAdmin
                                      ? Colors.grey.shade300
                                      : const Color(0xFF1E293B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              letterSpacing: 12,
                              fontWeight: FontWeight.bold,
                              color: _isAdmin ? Colors.white : const Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••',
                              hintStyle: GoogleFonts.outfit(
                                  color: _isAdmin
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                  letterSpacing: 8),
                              counterText: "",
                              filled: true,
                              fillColor: _isAdmin
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _isAdmin
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _isAdmin
                                        ? const Color(0xFFFF6B35)
                                        : const Color(0xFF4F46E5),
                                    width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _verifyOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isAdmin
                                    ? const Color(0xFFFF6B35)
                                    : const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : Text('Verify & Login',
                                      style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _otpSent = false;
                                  _otpController.clear();
                                });
                              },
                              child: Text(
                                'Change Phone Number',
                                style: GoogleFonts.outfit(
                                    color: _isAdmin
                                        ? const Color(0xFFFF6B35)
                                        : const Color(0xFF4F46E5),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String label, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isAdmin = label == "Admin";
            _otpSent = false;
            _phoneController.clear();
            _otpController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (_isAdmin
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF4F46E5))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (_isAdmin
                              ? const Color(0xFFFF6B35)
                              : const Color(0xFF4F46E5))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : (_isAdmin
                          ? Colors.grey.shade500
                          : Colors.grey.shade600)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (_isAdmin
                          ? Colors.grey.shade500
                          : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
