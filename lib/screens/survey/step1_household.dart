import 'package:flutter/material.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/step2_members.dart';

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
    // For MVP, using a simple timestamp based ID
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    setState(() {
      _householdId = 'DL-Ward05-$timestamp';
    });
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);

    // Simulate GPS capture for now as we might be on emulator/without permissions setup fully
    await Future.delayed(const Duration(seconds: 1));

    // Real implementation would look like:
    /*
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) { ... }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) { ... }
    Position position = await Geolocator.getCurrentPosition();
    */

    setState(() {
      _gettingLocation = false;
      _gpsLocation = '28.6139, 77.2090'; // Mock Coordinates (New Delhi)
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location Captured Successfully!')),
      );
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

      // Pass data to next step (or save draft)
      // For now, simple navigation or placeholder
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proceeding to Step 2...')),
      );

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Step2Members(
                    householdId: _householdId,
                    address: _addressController.text,
                    gpsLocation: _gpsLocation!,
                    existingMembers: widget.existingSurvey?.members ?? [],
                    existingSurvey: widget.existingSurvey,
                  )));
    }
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
              const Text("Step 1 of 4", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),

              // Household ID
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Household ID (Auto-generated)",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(_householdId,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  border: OutlineInputBorder(),
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
              const Text("Location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(Icons.location_on,
                      color: _gpsLocation != null ? Colors.green : Colors.grey),
                  title: Text(
                    _gpsLocation ?? "Location not captured",
                    style: TextStyle(
                      color: _gpsLocation != null ? Colors.black : Colors.grey,
                      fontWeight: _gpsLocation != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: _gpsLocation != null
                      ? const Text("Accuracy: High")
                      : null,
                  trailing: ElevatedButton.icon(
                    onPressed: _gettingLocation ? null : _captureLocation,
                    icon: _gettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: const Text("Capture"),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Next Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Next Step: Family Members"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
