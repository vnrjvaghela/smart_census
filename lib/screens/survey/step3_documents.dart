import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/models/family_member_model.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/services/database_service.dart';
import 'package:smart_census/screens/home/home_screen.dart';

import 'package:smart_census/services/ai_verification_service.dart';
import 'package:smart_census/utils/crypto_utils.dart';

class Step3Documents extends StatefulWidget {
  final String householdId;
  final String address;
  final String gpsLocation;
  final List<FamilyMember> members;
  final SurveyModel? existingSurvey;

  const Step3Documents({
    super.key,
    required this.householdId,
    required this.address,
    required this.gpsLocation,
    required this.members,
    this.existingSurvey,
  });

  @override
  State<Step3Documents> createState() => _Step3DocumentsState();
}

class _Step3DocumentsState extends State<Step3Documents> {
  final List<String> _capturedImages = [];
  // null = not yet verified, true = verified, false = rejected
  final Map<String, bool?> _verificationResults = {};
  bool _saving = false;
  String _loadingMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.existingSurvey != null) {
      _capturedImages.addAll(widget.existingSurvey!.documentPaths);
    }
  }

  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (image != null) {
        _addImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
        limit: 5,
      );
      for (final image in images) {
        _addImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open gallery: $e')),
        );
      }
    }
  }

  void _addImage(String path) {
    setState(() {
      _capturedImages.add(path);
      _verificationResults[path] = null;
    });
    if (!kIsWeb) {
      _runAiVerificationForImage(path);
    }
  }

  void _showAddPhotoOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Add Document Photo',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      color: const Color(0xFF0A84FF),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        _takePhoto();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF30D158),
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickFromGallery();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAiVerificationForImage(String imagePath) async {
    try {
      final aiService = AiVerificationService();
      final result = await aiService.verifyDocument(imagePath);
      aiService.dispose();
      if (mounted) {
        setState(() => _verificationResults[imagePath] = result);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _verificationResults[imagePath] = false);
      }
    }
  }

  Future<void> _submitSurvey() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one document photo')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _loadingMessage = 'Running AI Verification...';
    });

    try {
      // Use already-computed per-image verification results.
      // A survey is AI-verified if at least one document passed OCR.
      bool isAiVerified = _verificationResults.values.any((v) => v == true);

      setState(() {
         _loadingMessage = 'Generating Blockchain Hash...';
      });

      // 2. Create the Survey Model
      SurveyModel survey = SurveyModel(
        id: widget.existingSurvey?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        householdId: widget.householdId,
        address: widget.address,
        latitude: double.parse(widget.gpsLocation.split(',')[0].trim()),
        longitude: double.parse(widget.gpsLocation.split(',')[1].trim()),
        members: widget.members,
        documentPaths: _capturedImages,
        timestamp: DateTime.now(),
        status: isAiVerified ? 'Auto-Verified' : 'Pending',
        isSynced: false,
        aiVerified: isAiVerified,
        blockchainHash: '', // Temp
      );

      // 3. Generate Crypto Hash
      final hash = CryptoUtils.generateSurveyHash(survey);
      
      // 4. Update model with hash
      survey = SurveyModel(
        id: survey.id,
        householdId: survey.householdId,
        address: survey.address,
        latitude: survey.latitude,
        longitude: survey.longitude,
        members: survey.members,
        documentPaths: survey.documentPaths,
        timestamp: survey.timestamp,
        status: survey.status,
        isSynced: false,
        aiVerified: isAiVerified,
        blockchainHash: hash, 
      );

      await DatabaseService().saveSurvey(survey);
      await DatabaseService().deleteDraft();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Survey submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save survey: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
           _saving = false;
           _loadingMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Submit'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.colorScheme.primary, // Blue accent line under app bar
            height: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step 3 of 3 — Review & Submit",
                    style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Household Section
                  Text(
                    "Household",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isDark ? null : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.tag, 'ID', widget.householdId, const Color(0xFF0A84FF), isDark),
                        _buildDivider(isDark),
                        _buildInfoRow(Icons.home_outlined, 'Address', widget.address, const Color(0xFFFF9F0A), isDark),
                        _buildDivider(isDark),
                        _buildInfoRow(Icons.location_on_outlined, 'GPS', widget.gpsLocation, Colors.green, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Members",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${widget.members.length}",
                          style: GoogleFonts.poppins(color: const Color(0xFF0A84FF), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...widget.members.map((member) => _buildMemberCard(member, cardColor ?? Colors.white, textColor, isDark)),
                  
                  const SizedBox(height: 32),

                  // Documents Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Documents",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${_capturedImages.length}",
                          style: GoogleFonts.poppins(color: const Color(0xFF0A84FF), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Grid of documents
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _capturedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          onTap: _showAddPhotoOptions,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFEEF2FF),
                              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), style: BorderStyle.solid, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 28, color: theme.colorScheme.primary),
                                const SizedBox(height: 6),
                                Text("Add Photo", style: GoogleFonts.poppins(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text("Camera / Gallery", style: GoogleFonts.poppins(color: theme.colorScheme.primary.withOpacity(0.6), fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final imagePath = _capturedImages[index - 1];
                      final verifyResult = _verificationResults[imagePath];
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(child: Icon(Icons.insert_drive_file, color: isDark ? Colors.grey.shade600 : Colors.grey, size: 40)),
                              ),
                            ),
                          ),
                          // AI Verification Badge (bottom-left)
                          if (!kIsWeb)
                            Positioned(
                              bottom: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: verifyResult == null
                                      ? Colors.black54
                                      : verifyResult == true
                                          ? Colors.green.withOpacity(0.85)
                                          : Colors.red.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (verifyResult == null)
                                      const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                    else
                                      Icon(
                                        verifyResult == true ? Icons.verified_rounded : Icons.cancel_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      verifyResult == null ? 'OCR...' : verifyResult == true ? 'Verified' : 'Not verified',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Remove button (top-right)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _verificationResults.remove(imagePath);
                                  _capturedImages.removeAt(index - 1);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Verification Section
                  Text(
                    "Verification",
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: isDark ? null : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.shield_outlined,
                          'AI Verification',
                          kIsWeb
                              ? 'Not available on web'
                              : _capturedImages.isEmpty
                                  ? 'Add a document to verify'
                                  : _verificationResults.values.any((v) => v == true)
                                      ? '✅ At least one document verified'
                                      : _verificationResults.values.any((v) => v == null)
                                          ? '⏳ Scanning documents...'
                                          : '❌ No documents verified by OCR',
                          const Color(0xFF0A84FF),
                          isDark,
                        ),
                        _buildDivider(isDark),
                        _buildInfoRow(
                          Icons.fingerprint,
                          'Blockchain Hash',
                          'SHA-256 fingerprint generated on submit',
                          const Color(0xFFFF9F0A),
                          isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button Area
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00), // Prominent Orange Submit Button
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text(_loadingMessage.isNotEmpty ? _loadingMessage : "Submitting...", style: GoogleFonts.poppins(fontSize: 16)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text("Submit Survey", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle, Color iconColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 48, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200);
  }

  Widget _buildMemberCard(FamilyMember member, Color cardColor, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3E2723), // Deep brown/orange bg
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(color: const Color(0xFFFF9F0A), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text(
                "${member.age} yrs • ${member.gender} • ${member.relation}",
                style: GoogleFonts.poppins(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
