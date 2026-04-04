import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/household_info_screen.dart';
import 'package:smart_census/services/database_service.dart';
import 'package:smart_census/screens/survey/survey_detail_screen.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await DatabaseService.init();
      final surveys = DatabaseService().getAllSurveys();
      setState(() {
        _allSurveys = surveys;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load surveys: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSurveys = _allSurveys.where((survey) {
        final matchesSearch = survey.householdId
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            survey.address.toLowerCase().contains(_searchQuery.toLowerCase());

        if (_filterStatus == 'All') return matchesSearch;
        if (_filterStatus == 'Pending')
          return matchesSearch && !survey.isSynced;
        if (_filterStatus == 'Uploaded')
          return matchesSearch && survey.isSynced;
        return false;
      }).toList();
    });
  }

  Future<void> _navigateToAddSurvey() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Step1Household()),
    );
    await _loadSurveys();
  }

  Future<void> _navigateToEditSurvey(SurveyModel survey) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step1Household(existingSurvey: survey)),
    );
    await _loadSurveys();
  }

  Future<void> _confirmDelete(String surveyId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Survey'),
          content: const Text(
              'Are you sure you want to delete this survey? This action cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete')),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteSurvey(surveyId);
    }
  }

  Future<void> _deleteSurvey(String surveyId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await DatabaseService().deleteSurvey(surveyId);
      await _loadSurveys();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Survey deleted successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete survey: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Surveys'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSurvey,
        child: const Icon(Icons.add),
        tooltip: 'Add Survey',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search & Filter Bar Section
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade200)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        style: GoogleFonts.inter(
                            color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search by ID or address...',
                          hintStyle:
                              GoogleFonts.inter(color: Colors.grey.shade600),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey.shade500),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey.shade100,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _applyFilters();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Filter Chips
                      Row(
                        children: [
                          _buildFilterChip('All', isDark, primaryColor),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pending', isDark, primaryColor),
                          const SizedBox(width: 8),
                          _buildFilterChip('Uploaded', isDark, primaryColor),
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _errorMessage!,
                            style:
                                GoogleFonts.inter(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // List View
                Expanded(
                  child: _filteredSurveys.isEmpty
                      ? Center(
                          child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 64,
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                                _allSurveys.isEmpty
                                    ? "No surveys yet."
                                    : "No surveys match your search.",
                                style: GoogleFonts.inter(
                                    fontSize: 16, color: Colors.grey.shade500)),
                          ],
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          itemCount: _filteredSurveys.length,
                          itemBuilder: (context, index) {
                            final survey = _filteredSurveys[index];
                            return _buildSurveyCard(survey, theme, isDark);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark, Color primaryColor) {
    final isSelected = _filterStatus == label;
    return GestureDetector(
      onTap: () {
        _filterStatus = label;
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyCard(SurveyModel survey, ThemeData theme, bool isDark) {
    final bool isPending = !survey.isSynced;
    final cardColor = theme.cardTheme.color;
    final textColor = theme.colorScheme.onSurface;
    final mutedColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    // Formatting date (Assuming timestamp is a string in ISO format for simplicity, adjust if necessary)
    String dateStr = "Unknown";
    try {
      final date = survey.timestamp;
      dateStr = DateFormat('dd MMM').format(date);
    } catch (_) {
      // Fallback
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SurveyDetailScreen(survey: survey)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    survey.householdId,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPending
                            ? Icons.cloud_upload_outlined
                            : Icons.cloud_done_outlined,
                        size: 14,
                        color: isPending ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPending ? "Pending" : "Uploaded",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isPending ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Small indicator dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors
                        .orange, // Assuming default surveyor color as per screenshot
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  survey
                      .address, // Showing address as main subtitle like screenshot
                  style: GoogleFonts.inter(fontSize: 14, color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade600, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_alt_outlined,
                        size: 16, color: mutedColor),
                    const SizedBox(width: 6),
                    Text(
                      "${survey.members.length}",
                      style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEditSurvey(survey),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(survey.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
