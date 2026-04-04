import 'package:flutter/material.dart';
import 'package:smart_census/models/family_member_model.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/step3_documents.dart';

class Step2Members extends StatefulWidget {
  final String householdId;
  final String address;
  final String gpsLocation;
  final List<FamilyMember> existingMembers;
  final SurveyModel? existingSurvey;

  const Step2Members({
    super.key,
    required this.householdId,
    required this.address,
    required this.gpsLocation,
    this.existingMembers = const [],
    this.existingSurvey,
  });

  @override
  State<Step2Members> createState() => _Step2MembersState();
}

class _Step2MembersState extends State<Step2Members> {
  final List<FamilyMember> _members = [];

  @override
  void initState() {
    super.initState();
    _members.addAll(widget.existingMembers);
  }

  void _showAddMemberDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String gender = 'Male';
    String relation = 'Head';
    final educationController = TextEditingController();
    final occupationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Family Member'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: ['Male', 'Female', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => gender = v!,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: relation,
                    decoration: const InputDecoration(labelText: 'Relation to Head'),
                    items: ['Head', 'Spouse', 'Child', 'Parent', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => relation = v!,
                  ),
                  TextFormField(
                    controller: educationController,
                    decoration: const InputDecoration(labelText: 'Education'),
                  ),
                  TextFormField(
                    controller: occupationController,
                    decoration: const InputDecoration(labelText: 'Occupation'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newMember = FamilyMember(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    age: int.parse(ageController.text),
                    gender: gender,
                    relation: relation,
                    education: educationController.text,
                    occupation: occupationController.text,
                  );
                  setState(() => _members.add(newMember));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _finishSurvey() {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one family member')),
      );
      return;
    }

    // Create Survey Object (Draft Save Logic here)
    // Normally proceed to Documents, but for end of Step 2 logic:
    
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => Step3Documents(
        householdId: widget.householdId,
        address: widget.address,
        gpsLocation: widget.gpsLocation,
        members: _members,
        existingSurvey: widget.existingSurvey,
      ))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2: Family Members'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress
          const LinearProgressIndicator(value: 0.5),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("Step 2 of 4"),
          ),

          // Header Info
          ListTile(
            title: Text("Household: ${widget.householdId}"),
            subtitle: Text(widget.address),
            trailing: Chip(label: Text("${_members.length} Members")),
          ),
          const Divider(),

          // List of Members
          Expanded(
            child: _members.isEmpty
                ? const Center(
                    child: Text(
                      "No members added yet.\nTap + to add family members.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(member.name[0])),
                          title: Text("${member.name} (${member.age}, ${member.gender})"),
                          subtitle: Text(member.relation),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() => _members.removeAt(index));
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text("Add Family Member"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _finishSurvey,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Next Step: Documents"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
