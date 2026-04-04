import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/models/family_member_model.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/document_submission_screen.dart';
import 'package:smart_census/services/database_service.dart';

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

  void _showAddMemberBottomSheet({int? editIndex}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddMemberFormStateful(
          editIndex: editIndex,
          existingMember: editIndex != null ? _members[editIndex] : null,
          theme: theme,
          isDark: isDark,
          onSave: (member) {
            setState(() {
              if (editIndex == null) {
                _members.add(member);
              } else {
                _members[editIndex] = member;
              }
            });
            _saveCurrentDraft();
          },
        );
      },
    );
  }

  Future<void> _saveCurrentDraft() async {
    final draft = SurveyModel(
      id: widget.existingSurvey?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      householdId: widget.householdId,
      address: widget.address,
      latitude: double.tryParse(widget.gpsLocation.split(',')[0]) ?? 0,
      longitude: double.tryParse(widget.gpsLocation.split(',')[1].trim()) ?? 0,
      members: _members,
      timestamp: widget.existingSurvey?.timestamp ?? DateTime.now(),
      status: 'Draft',
    );
    await DatabaseService().saveDraft(draft);
  }

  void _finishSurvey() {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one family member')),
      );
      return;
    }

    _saveCurrentDraft().then((_) {
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Step3Documents(
                    householdId: widget.householdId,
                    address: widget.address,
                    gpsLocation: widget.gpsLocation,
                    members: _members,
                    existingSurvey: widget.existingSurvey,
                  )));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
      ),
      body: Column(
        children: [
          // Progress
          LinearProgressIndicator(
              value: 0.66,
              backgroundColor:
                  isDark ? Colors.grey.shade900 : Colors.grey.shade200),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Text("Step 2 of 3 — Family Members",
                    style: GoogleFonts.poppins(
                        color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),

          // Header Info Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.householdId,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Text(widget.address,
                        style: GoogleFonts.poppins(
                            color: Colors.grey.shade500, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.people_alt_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      "${_members.length}",
                      style: GoogleFonts.poppins(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of Members
          Expanded(
            child: _members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_add_outlined,
                            size: 60,
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "Tap + to add members",
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isDark
                              ? null
                              : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                _showAddMemberBottomSheet(editIndex: index),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : Colors.blue.shade50,
                                    child: Text(member.name[0].toUpperCase(),
                                        style: GoogleFonts.poppins(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(member.name,
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: theme
                                                    .colorScheme.onSurface)),
                                        const SizedBox(height: 4),
                                        Text(
                                            "${member.age} yrs • ${member.gender} • ${member.relation}",
                                            style: GoogleFonts.poppins(
                                                color: Colors.grey.shade500,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.redAccent,
                                        size: 22),
                                    onPressed: () {
                                      setState(() => _members.removeAt(index));
                                      _saveCurrentDraft();
                                    },
                                  ),
                                ],
                              ),
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
              color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _showAddMemberBottomSheet,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: theme.colorScheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _finishSurvey,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Next Step",
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
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

// Stateful widget for the bottom sheet to manage local form state independently
class _AddMemberFormStateful extends StatefulWidget {
  final int? editIndex;
  final FamilyMember? existingMember;
  final ThemeData theme;
  final bool isDark;
  final Function(FamilyMember) onSave;

  const _AddMemberFormStateful({
    this.editIndex,
    this.existingMember,
    required this.theme,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_AddMemberFormStateful> createState() => _AddMemberFormStatefulState();
}

class _AddMemberFormStatefulState extends State<_AddMemberFormStateful> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _educationController;
  late TextEditingController _occupationController;

  String _gender = 'Male';
  String _relation = 'Head';

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _relations = [
    'Head',
    'Spouse',
    'Child',
    'Parent',
    'Sibling',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingMember?.name ?? '');
    _ageController = TextEditingController(
        text: widget.existingMember?.age.toString() ?? '');
    _educationController =
        TextEditingController(text: widget.existingMember?.education ?? '');
    _occupationController =
        TextEditingController(text: widget.existingMember?.occupation ?? '');

    if (widget.existingMember != null) {
      if (_genders.contains(widget.existingMember!.gender))
        _gender = widget.existingMember!.gender;
      if (_relations.contains(widget.existingMember!.relation))
        _relation = widget.existingMember!.relation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _educationController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keyboard padding
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset > 0
            ? bottomInset + 16
            : MediaQuery.of(context).padding.bottom + 24,
        top: 8,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                widget.editIndex == null ? 'Add Family Member' : 'Edit Member',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 24),

              _buildLabel("Name"),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.inter(
                    color: widget.theme.colorScheme.onSurface),
                decoration: const InputDecoration(hintText: "Enter full name"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel("Age"),
              TextFormField(
                controller: _ageController,
                style: GoogleFonts.poppins(
                    color: widget.theme.colorScheme.onSurface),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Enter age"),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel("Gender"),
              Wrap(
                spacing: 8,
                children: _genders
                    .map((g) => _buildChoiceChip(
                        g, _gender, (val) => setState(() => _gender = val)))
                    .toList(),
              ),
              const SizedBox(height: 16),

              _buildLabel("Relation to Head"),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _relations
                    .map((r) => _buildChoiceChip(
                        r, _relation, (val) => setState(() => _relation = val)))
                    .toList(),
              ),
              const SizedBox(height: 16),

              _buildLabel("Education"),
              TextFormField(
                controller: _educationController,
                style: GoogleFonts.inter(
                    color: widget.theme.colorScheme.onSurface),
                decoration: const InputDecoration(hintText: "e.g., Bachelor's"),
              ),
              const SizedBox(height: 16),

              _buildLabel("Occupation"),
              TextFormField(
                controller: _occupationController,
                style: GoogleFonts.inter(
                    color: widget.theme.colorScheme.onSurface),
                decoration: const InputDecoration(hintText: "e.g., Teacher"),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: widget.isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey.shade200,
                          foregroundColor:
                              widget.isDark ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Cancel",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final member = FamilyMember(
                              id: widget.editIndex == null
                                  ? DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString()
                                  : widget.existingMember!.id,
                              name: _nameController.text.trim(),
                              age:
                                  int.tryParse(_ageController.text.trim()) ?? 0,
                              gender: _gender,
                              relation: _relation,
                              education: _educationController.text.trim(),
                              occupation: _occupationController.text.trim(),
                              caste:
                                  '', // Assuming caste is not asked in this step based on UI
                            );
                            widget.onSave(member);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              widget.theme.colorScheme.primary, // Blue button
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.editIndex == null ? "Add" : "Save",
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 12,
            color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildChoiceChip(
      String label, String groupValue, Function(String) onSelect) {
    final isSelected = label == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelect(label);
      },
      labelStyle: GoogleFonts.poppins(
        color: isSelected
            ? Colors.white
            : (widget.isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      backgroundColor:
          widget.isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
      selectedColor: widget.theme.colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
