import 'package:flutter/material.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/step1_household.dart';

class SurveyDetailScreen extends StatelessWidget {
  final SurveyModel survey;

  const SurveyDetailScreen({super.key, required this.survey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Survey: ${survey.householdId}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!survey.isSynced)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Survey',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Step1Household(existingSurvey: survey)),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: survey.isSynced ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: survey.isSynced ? Colors.green.shade200 : Colors.orange.shade200
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    survey.isSynced ? Icons.check_circle : Icons.sync_problem,
                    color: survey.isSynced ? Colors.green : Colors.orange
                  ),
                  const SizedBox(width: 8),
                  Text(
                    survey.isSynced ? 'Synced to Cloud' : 'Pending Upload',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: survey.isSynced ? Colors.green.shade800 : Colors.orange.shade800
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Household Info
            const Text("Household Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.home, "Address", survey.address),
                    const Divider(),
                    _buildInfoRow(Icons.location_on, "GPS", "${survey.latitude}, ${survey.longitude}"),
                    const Divider(),
                    _buildInfoRow(Icons.access_time, "Created", survey.timestamp.toString().split('.')[0]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Family Members
            Text("Family Members (${survey.members.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: survey.members.length,
                separatorBuilder: (c, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = survey.members[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(member.name[0])),
                    title: Text(member.name),
                    subtitle: Text("${member.relation} • ${member.age} yrs • ${member.gender}"),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Documents
            Text("Documents (${survey.documentPaths.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (survey.documentPaths.isEmpty) 
              const Text("No documents attached", style: TextStyle(color: Colors.grey))
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: survey.documentPaths.length,
                  itemBuilder: (context, index) {
                    final path = survey.documentPaths[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          path, // On web, this is a blob URL. On mobile this needs fix (conditional import)
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            width: 120, 
                            height: 120, 
                            color: Colors.grey.shade200, 
                            child: const Icon(Icons.broken_image)
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }
}
