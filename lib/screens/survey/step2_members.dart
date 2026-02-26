import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/models/family_member_model.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/step3_documents.dart';

class Step2Members extends StatefulWidget {
  final String householdId;
  final String address;
  final String gpsLocation;
  final SurveyModel? existingSurvey;

  const Step2Members({
    super.key,
    required this.householdId,
    required this.address,
    required this.gpsLocation,
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
    if (widget.existingSurvey != null) {
      _members.addAll(widget.existingSurvey!.members);
    }
  }

  void _showAddMemberDialog({int? editIndex}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String gender = 'Male';
    String relation = 'Head';
    final educationController = TextEditingController();
    final occupationController = TextEditingController();

    if (editIndex != null) {
      final m = _members[editIndex];
      nameController.text = m.name;
      ageController.text = m.age.toString();
      gender = m.gender;
      relation = m.relation;
      educationController.text = m.education;
      occupationController.text = m.occupation;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(editIndex == null ? 'Add Family Member' : 'Edit Member', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: GoogleFonts.outfit()
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: ageController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      labelText: 'Age',
                      labelStyle: GoogleFonts.outfit()
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: ['Male', 'Female', 'Other'].contains(gender) ? gender : 'Male',
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      labelStyle: GoogleFonts.outfit()
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit())))
                        .toList(),
                    onChanged: (v) => gender = v!,
                  ),
                  DropdownButtonFormField<String>(
                    value: ['Head', 'Spouse', 'Child', 'Parent', 'Other'].contains(relation) ? relation : 'Other',
                    decoration: InputDecoration(
                      labelText: 'Relation to Head',
                      labelStyle: GoogleFonts.outfit()
                    ),
                    items: ['Head', 'Spouse', 'Child', 'Parent', 'Other']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit())))
                        .toList(),
                    onChanged: (v) => relation = v!,
                  ),
                  TextFormField(
                    controller: educationController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      labelText: 'Education',
                      labelStyle: GoogleFonts.outfit()
                    ),
                  ),
                  TextFormField(
                    controller: occupationController,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      labelText: 'Occupation',
                      labelStyle: GoogleFonts.outfit()
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit()),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newMember = FamilyMember(
                    id: editIndex == null ? DateTime.now().millisecondsSinceEpoch.toString() : _members[editIndex].id,
                    name: nameController.text,
                    age: int.parse(ageController.text),
                    gender: gender,
                    relation: relation,
                    education: educationController.text,
                    occupation: occupationController.text,
                    caste: '',
                  );
                  
                  setState(() {
                    if (editIndex == null) {
                      _members.add(newMember);
                    } else {
                      _members[editIndex] = newMember;
                    }
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(editIndex == null ? 'Add' : 'Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _editMember(int index) {
    _showAddMemberDialog(editIndex: index);
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
      MaterialPageRoute(builder: (BuildContext context) => Step3Documents(
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Step 2 of 4", style: GoogleFonts.outfit(color: Colors.grey)),
          ),

          // Header Info
          ListTile(
            title: Text("Household: ${widget.householdId}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.address, style: GoogleFonts.outfit(color: Colors.grey.shade600)),
            trailing: Chip(
              label: Text("${_members.length} Members", style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFFEEF2FF),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const Divider(),

          // List of Members
          Expanded(
            child: _members.isEmpty
                ? Center(
                    child: Text(
                      "No members added yet.\nTap + to add family members.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _editMember(index),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text(member.name[0].toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 20)),
                            ),
                            title: Text("${member.name} (${member.age}, ${member.gender})", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(member.relation, style: GoogleFonts.outfit(color: Colors.grey.shade600)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () {
                                setState(() => _members.removeAt(index));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Buttons
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(Icons.person_add_rounded),
                  label: Text("Add Family Member", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                    shape: const StadiumBorder(),
                    foregroundColor: const Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishSurvey,
                    child: const Text("Next Step: Documents", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
