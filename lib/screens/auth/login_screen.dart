import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/screens/home/home_screen.dart';
import 'package:smart_census/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String _verificationId = "";

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    // Test Logic: Bypass Firebase for sample number
    if (_phoneController.text.trim() == '9999999999') {
      setState(() {
        _loading = false;
        _otpSent = true;
        _verificationId = 'test_verification_id';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test Mode: Use OTP 123456')),
      );
      return;
    }

    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }
    
    setState(() => _loading = true);

    await AuthService().verifyPhoneNumber(
      '+91${_phoneController.text}',
      onVerificationCompleted: (credential) async {
        await AuthService().signInWithCredential(credential);
        setState(() => _loading = false);
        if (mounted) {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
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

    setState(() => _loading = true);

    // Test bypass check
    if (_verificationId == 'test_verification_id') {
      print("DEBUG: Test verification ID matched");
      if (_otpController.text == '123456') {
        print("DEBUG: OTP matched. Setting loading=false");
        setState(() => _loading = false);
        if (mounted) {
          print("DEBUG: Navigating to HomeScreen");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid Test OTP')),
        );
      }
      return;
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );

      final userCredential = await AuthService().signInWithCredential(credential);

      setState(() => _loading = false);

      if (userCredential != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF2FF), Color(0xFFC7D2FE)], // Soft Indigo subtle gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Card(
                elevation: 8,
                shadowColor: const Color(0xFF4F46E5).withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Icon Area
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.poll_rounded, size: 50, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Header Text
                      Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to access your dashboard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16, 
                          color: Colors.grey.shade600,
                        ),
                      ),
              const SizedBox(height: 48),

              // Inputs wrapped in a "Card" look for iOS feel? 
              // Or just clean inputs on the background. Let's do clean inputs.

              if (!_otpSent) ...[
                Text("Phone Number", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: '9876543210',
                    prefixIcon: const Icon(Icons.phone_android_rounded, size: 22, color: Color(0xFF4F46E5)),
                    prefixIconConstraints: const BoxConstraints(minWidth: 50),
                    prefixText: '+91 ',
                    prefixStyle: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 18),
                    counterText: "", // Hide counter
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  height: 56, // Tall button
                  child: ElevatedButton(
                    onPressed: _loading ? null : _sendOTP,
                    child: _loading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : const Text('Continue', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ] else ...[
                 Text("Enter Verification Code", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF1E293B))),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: jsonify_style_placeholder(), // Helper
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyOTP,
                    child: _loading 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : const Text('Verify & Login', style: TextStyle(fontSize: 18)),
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
                      style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600),
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
    );
  }

  TextStyle? jsonify_style_placeholder() => GoogleFonts.outfit(color: Colors.grey.shade400, letterSpacing: 8);

}

