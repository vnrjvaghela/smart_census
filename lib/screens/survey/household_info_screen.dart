import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/family_members_screen.dart';
import 'package:smart_census/services/database_service.dart';

class Step1Household extends StatefulWidget {
  final SurveyModel? existingSurvey;

  const Step1Household({super.key, this.existingSurvey});

  @override
  State<Step1Household> createState() => _Step1HouseholdState();
}

class _Step1HouseholdState extends State<Step1Household> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _householdId = '';
  String? _gpsLocation;
  bool _gettingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSurvey != null) {
      _householdId = widget.existingSurvey!.householdId;
      _addressController.text = widget.existingSurvey!.address;
      _gpsLocation =
          '${widget.existingSurvey!.latitude}, ${widget.existingSurvey!.longitude}';
    } else {
      _generateHouseholdId();
    }
  }

  void _generateHouseholdId() {
    // Logic to auto-generate ID: DISTRICT-WARD-TIMESTAMP
    // For MVP, mixing timestamp and random string
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = now.microsecondsSinceEpoch.toString().substring(10);
    setState(() {
      _householdId = 'DL-W05-$dateStr-$randomPart';
    });
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kIsWeb) {
          // Web Chrome blocks Location API on insecure (HTTP) Localhost
          setState(() {
            _gettingLocation = false;
            _gpsLocation = '28.6139, 77.2090'; // Mock Coordinates (New Delhi)
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Web Localhost: Using Mock Location')),
            );
          }
          return;
        }
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _gettingLocation = false;
        _gpsLocation = '${position.latitude}, ${position.longitude}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location Captured Successfully!')),
        );
      }
    } catch (e) {
      setState(() => _gettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_gpsLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture GPS location')),
        );
        return;
      }
      _checkDuplicateAndProceed();
    }
  }

  Future<void> _checkDuplicateAndProceed() async {
    // Check if this householdId already exists in local DB
    final existing = DatabaseService().getAllSurveys();
    final isDuplicate = existing.any(
      (s) =>
          s.householdId == _householdId &&
          s.id != (widget.existingSurvey?.id ?? ''),
    );

    if (isDuplicate && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Duplicate Household',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: Text(
            'A survey for household ID "$_householdId" already exists.\nDo you want to create another survey for this household?',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Proceed Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    if (!mounted) return;

    // Auto-save draft
    final latLng = _gpsLocation!.split(',');
    final draft = SurveyModel(
      id: widget.existingSurvey?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      householdId: _householdId,
      address: _addressController.text,
      latitude: double.tryParse(latLng[0].trim()) ?? 0,
      longitude: double.tryParse(latLng[1].trim()) ?? 0,
      members: widget.existingSurvey?.members ?? [],
      timestamp: widget.existingSurvey?.timestamp ?? DateTime.now(),
      status: 'Draft',
    );
    await DatabaseService().saveDraft(draft);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step2Members(
          householdId: _householdId,
          address: _addressController.text,
          gpsLocation: _gpsLocation!,
          existingSurvey: widget.existingSurvey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1: Household Info'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              const LinearProgressIndicator(value: 0.25),
              const SizedBox(height: 8),
              Text("Step 1 of 4",
                  style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 24),

              // Household ID
              Card(
                color: Colors.grey.shade50,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Household ID (Auto-generated)",
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(_householdId,
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Address Field
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                style: GoogleFonts.poppins(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  hintText: 'House No, Street, Landmark...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // GPS Location
              Text("Location",
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _gpsLocation != null
                          ? const Color(0xFFECFDF5)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on_rounded,
                        color: _gpsLocation != null
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade500),
                  ),
                  title: Text(
                    _gpsLocation ?? "Location not captured",
                    style: GoogleFonts.poppins(
                      color: _gpsLocation != null
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade500,
                      fontWeight: _gpsLocation != null
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: _gpsLocation != null
                      ? Text("Accuracy: High",
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.grey.shade600))
                      : null,
                  trailing: ElevatedButton.icon(
                    onPressed: _gettingLocation ? null : _captureLocation,
                    icon: _gettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.my_location_rounded, size: 20),
                    label: const Text("Capture"),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Next Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  child: const Text("Next Step: Family Members",
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
