import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/screens/auth/login_screen.dart';
import 'package:smart_census/services/auth_service.dart';
import 'package:smart_census/screens/profile/profile_screen.dart';
import 'package:smart_census/screens/survey/step1_household.dart';
import 'package:smart_census/services/sync_service.dart';
import 'package:smart_census/services/database_service.dart';
import 'package:smart_census/screens/survey/survey_list_screen.dart';
import 'package:smart_census/screens/survey/survey_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    print("DEBUG: HomeScreen initState");
    _loadStats();
  }

  Future<void> _loadStats() async {
    print("DEBUG: _loadStats started");
    try {
      await DatabaseService.init(); // Ensure initialized
      print("DEBUG: DatabaseService initialized");
      final allSurveys = DatabaseService().getAllSurveys();
      print("DEBUG: Surveys fetched: ${allSurveys.length}");
      setState(() {
        _totalCount = allSurveys.length;
        _pendingCount = allSurveys.where((s) => !s.isSynced).length;
      });
    } catch (e) {
      print("DEBUG: Error in _loadStats: $e");
    }
  }

  Future<void> _triggerSync() async {
    if (_pendingCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending surveys to sync')),
      );
      return;
    }

    setState(() => _isSyncing = true);
    
    final synced = await SyncService().uploadPendingSurveys();
    
    setState(() => _isSyncing = false);
    
    await _loadStats(); // Refresh stats

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $synced surveys successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      print("DEBUG: Firebase not initialized (Test Mode active)");
    }
    final phoneNumber = user?.phoneNumber ?? "Test User (+91 9999999999)";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _loadStats,
            tooltip: 'Refresh Stats',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            phoneNumber,
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildStatCard("Total", _totalCount.toString(), Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard("Pending", _pendingCount.toString(), Colors.orange)),
              ],
            ),
            const SizedBox(height: 24),
            
            Text(
              "Sync Actions",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: _isSyncing ? null : _triggerSync,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: _pendingCount > 0 ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pendingCount > 0 ? const Color(0xFFFFB74D) : const Color(0xFFA5D6A7)
                  ),
                ),
                child: Row(
                  children: [
                    _isSyncing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          _pendingCount > 0 ? Icons.sync_problem_rounded : Icons.check_circle_rounded,
                          color: _pendingCount > 0 ? const Color(0xFFFF6F00) : const Color(0xFF2E7D32)
                        ),
                    const SizedBox(width: 16),
                    Text(
                      _isSyncing 
                        ? "Syncing data..." 
                        : (_pendingCount > 0 ? "Sync Now ($_pendingCount pending)" : "All data synced"),
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _pendingCount > 0 ? const Color(0xFFE65100) : const Color(0xFF1B5E20)
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Surveys",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SurveyListScreen()),
                    );
                  }, 
                  child: Text("View All", style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.w600))
                ),
              ],
            ),
            
            // Recent Surveys List
            const SizedBox(height: 8),
            _buildRecentSurveysList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Step1Household()),
          );
          _loadStats(); // Refresh after returning from survey
        },
        shape: const StadiumBorder(),
        elevation: 6,
        label: Text("New Survey", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRecentSurveysList() {
    final allSurveys = DatabaseService().getAllSurveys();
    if (allSurveys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text("Tap 'New Survey' to get started.", style: GoogleFonts.outfit(color: Colors.grey.shade500, fontSize: 14)),
      );
    }

    // Sort by newest first
    allSurveys.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentSurveys = allSurveys.take(3).toList();

    return Column(
      children: recentSurveys.map((survey) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: survey.isSynced ? Colors.green.shade50 : Colors.orange.shade50,
              child: Icon(
                survey.isSynced ? Icons.cloud_done : Icons.cloud_upload,
                color: survey.isSynced ? Colors.green : Colors.orange,
              ),
            ),
            title: Text(survey.householdId, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text("${survey.members.length} members • ${survey.status}"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => SurveyDetailScreen(survey: survey)),
               );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(count, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
