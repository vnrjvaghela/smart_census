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
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _capturedImages.add(image.path); // Use blob URL on web, local path on mobile
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open camera: $e')),
        );
      }
    }
  }

  Future<void> _submitSurvey() async {
    if (_capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture at least one document photo')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _loadingMessage = 'Running AI Document Verification...';
    });

    try {
      // 1. Run AI Verification on the first image (or all images)
      bool isAiVerified = false;
      
      // On web, `path` is a blob URL which ML Kit can't easily read without downloading bytes.
      // For MVP, we will run ML Kit if it's a mobile file path, else default to false.
      if (!kIsWeb && _capturedImages.isNotEmpty) {
          final aiService = AiVerificationService();
          isAiVerified = await aiService.verifyDocument(_capturedImages.first);
          aiService.dispose();
      }

      setState(() {
         _loadingMessage = 'Generating Blockchain Hash...';
      });

      // 2. Create the Survey Model (Draft)
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAiVerified 
                ? 'Survey saved! AI successfully verified documents.' 
                : 'Survey saved pending manual verification.'
            ),
            backgroundColor: isAiVerified ? Colors.green : null,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 3: Documents'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const LinearProgressIndicator(value: 0.75),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Step 3 of 4", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _capturedImages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3), style: BorderStyle.solid, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF4F46E5)),
                          const SizedBox(height: 8),
                          Text("Take Photo", style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }
                
                final imagePath = _capturedImages[index - 1];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imagePath, // Blob URL on web
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _capturedImages.removeAt(index - 1);
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ]
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _submitSurvey,
                child: _saving 
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text(_loadingMessage.isNotEmpty ? _loadingMessage : "Saving...", style: const TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Text("Submit Survey", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
