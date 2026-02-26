import 'package:flutter/material.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/services/database_service.dart';
import 'package:smart_census/screens/survey/survey_detail_screen.dart';

class SurveyListScreen extends StatefulWidget {
  const SurveyListScreen({super.key});

  @override
  State<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends State<SurveyListScreen> {
  List<SurveyModel> _allSurveys = [];
  List<SurveyModel> _filteredSurveys = [];
  String _searchQuery = '';
  String _filterStatus = 'All'; // All, Pending, Uploaded

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    await DatabaseService.init();
    final surveys = DatabaseService().getAllSurveys();
    setState(() {
      _allSurveys = surveys;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredSurveys = _allSurveys.where((survey) {
      final matchesSearch = survey.householdId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          survey.address.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (_filterStatus == 'All') return matchesSearch;
      if (_filterStatus == 'Pending') return matchesSearch && !survey.isSynced;
      if (_filterStatus == 'Uploaded') return matchesSearch && survey.isSynced;
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Surveys'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by ID or Address',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterStatus,
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                      _applyFilters();
                    });
                  },
                  items: ['All', 'Pending', 'Uploaded']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filteredSurveys.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("🚀", style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          _allSurveys.isEmpty 
                            ? "Start your first survey!" 
                            : "No surveys match your filters 🔍", 
                          style: const TextStyle(fontSize: 16, color: Colors.grey)
                        ),
                      ],
                    )
                  )
                : ListView.builder(
                    itemCount: _filteredSurveys.length,
                    itemBuilder: (context, index) {
                      final survey = _filteredSurveys[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: survey.isSynced ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                            child: Icon(
                              survey.isSynced ? Icons.check_circle_rounded : Icons.sync_problem_rounded,
                              color: survey.isSynced ? const Color(0xFF2E7D32) : const Color(0xFFFF6F00),
                            ),
                          ),
                          title: Text(survey.householdId, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${survey.members.length} Members • ${survey.address}"),
                          onTap: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => SurveyDetailScreen(survey: survey))
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
