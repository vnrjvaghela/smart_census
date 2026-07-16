import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/screens/profile/profile_screen.dart';
import 'package:smart_census/screens/survey/survey_list_screen.dart';
import 'package:smart_census/screens/survey/household_info_screen.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/services/database_service.dart';
import 'package:smart_census/services/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_census/screens/survey/survey_detail_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'package:smart_census/screens/home/lab_features_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _tabs = [
    const DashboardTab(),
    const SurveyListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.grid_view_rounded)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.grid_view_rounded)),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.assignment_outlined)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.assignment)),
              label: 'Surveys',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_outline_rounded)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_rounded)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _totalCount = 0;
  bool _isOnline = true;
  SurveyModel? _activeDraft;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Cloud data state
  List<Map<String, dynamic>> _cloudSurveys = [];
  bool _isFetchingCloud = false;
  int _cloudFamilies = 0;
  int _cloudMembers = 0;
  String? _cloudError;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _initConnectivity();
    _fetchCloudData();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      final nowOnline = result != ConnectivityResult.none;
      if (!_isOnline && nowOnline) _triggerSync();
      setState(() => _isOnline = nowOnline);
    });
  }

  Future<void> _loadStats() async {
    try {
      await DatabaseService.init();
      final allSurveys = DatabaseService().getAllSurveys();
      final draft = DatabaseService().getActiveDraft();
      setState(() {
        _totalCount = allSurveys.length;
        _pendingCount = allSurveys.where((s) => !s.isSynced).length;
        _activeDraft = draft;
      });
    } catch (e) {
      print("Error in _loadStats: $e");
    }
  }

  Future<void> _fetchCloudData() async {
    setState(() {
      _isFetchingCloud = true;
      _cloudError = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .get();
      final docs = snapshot.docs;
      int families = docs.length;
      int members = 0;
      List<Map<String, dynamic>> surveys = [];
      for (var doc in docs) {
        final data = doc.data();
        members += ((data['members'] as List<dynamic>?) ?? []).length;
        surveys.add(data);
      }
      // Sort by timestamp descending (client-side to avoid index requirement)
      surveys.sort((a, b) {
        final tsA = a['timestamp'] ?? '';
        final tsB = b['timestamp'] ?? '';
        return tsB.toString().compareTo(tsA.toString());
      });
      setState(() {
        _cloudSurveys = surveys;
        _cloudFamilies = families;
        _cloudMembers = members;
        _isFetchingCloud = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched $families surveys from cloud'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      setState(() {
        _isFetchingCloud = false;
        _cloudError = e.toString();
      });
      print('Cloud fetch error: $e');
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
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $synced surveys successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      // Firebase may not be initialized; silently fall back to default phone
    }
    final phoneNumber = user?.phoneNumber ?? "+91 9999999999";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabFeaturesScreen())),
            tooltip: 'Lab Features',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isSyncing ? null : _loadStats,
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.menu_book, size: 32, color: Colors.white),
                  const SizedBox(height: 8),
                  Text('Smart Census', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.grid_view_rounded), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
            ListTile(
              leading: const Icon(Icons.assignment_outlined), title: const Text('Surveys'),
              onTap: () {
                Navigator.pop(context);
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                homeState?.setState(() => homeState._currentIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded), title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                homeState?.setState(() => homeState._currentIndex = 2);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.science), title: const Text('Lab Features'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LabFeaturesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline), title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(context: context, applicationName: 'Smart Census', applicationVersion: '1.0.0');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Offline Banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            height: _isOnline ? 0 : 40,
            color: Colors.red.shade700,
            child: _isOnline
                ? const SizedBox.shrink()
                : Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text('Offline — surveys will sync when connected',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF0056B3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: isDark ? [] : [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.person, size: 28, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Welcome back!', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                          Text(phoneNumber, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Resume Draft Card
                  if (_activeDraft != null) ...[
                    _buildResumeDraftCard(isDark, theme),
                    const SizedBox(height: 24),
                  ],

                  // Stats Row
                  Row(children: [
                    Expanded(child: _buildStatCard("Total", _totalCount.toString(), theme.colorScheme.primary, isDark, theme.cardTheme.color!)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Pending", _pendingCount.toString(), Colors.orange, isDark, theme.cardTheme.color!)),
                  ]),
                  const SizedBox(height: 24),

                  // Sync Actions
                  Text("Sync Actions", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _isSyncing ? null : _triggerSync,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: _pendingCount > 0
                            ? (isDark ? Colors.orange.withOpacity(0.1) : const Color(0xFFFFF3E0))
                            : (isDark ? Colors.green.withOpacity(0.1) : const Color(0xFFE8F5E9)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _pendingCount > 0
                            ? (isDark ? Colors.orange.withOpacity(0.3) : const Color(0xFFFFB74D))
                            : (isDark ? Colors.green.withOpacity(0.3) : const Color(0xFFA5D6A7))),
                      ),
                      child: Row(children: [
                        _isSyncing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_pendingCount > 0 ? Icons.sync_problem_rounded : Icons.check_circle_rounded,
                                color: _pendingCount > 0 ? const Color(0xFFFF6F00) : const Color(0xFF2E7D32)),
                        const SizedBox(width: 16),
                        Text(
                          _isSyncing ? "Syncing data..." : (_pendingCount > 0 ? "Sync Now ($_pendingCount pending)" : "All data synced"),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15,
                            color: _pendingCount > 0 ? const Color(0xFFE65100) : const Color(0xFF1B5E20)),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── CLOUD DATA (from Firebase) ───
                  Row(children: [
                    Expanded(child: Text("Cloud Census Data", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                    if (_isFetchingCloud)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: _fetchCloudData,
                        tooltip: 'Refresh Cloud Data',
                        color: const Color(0xFF8B5CF6),
                      ),
                  ]),
                  const SizedBox(height: 4),
                  Text("Tap refresh to fetch latest data from Firebase", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 12),

                  // Fetch button (prominent)
                  InkWell(
                    onTap: _isFetchingCloud ? null : _fetchCloudData,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark ? [] : [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _isFetchingCloud
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          _isFetchingCloud ? 'Fetching from Firebase...' : 'Fetch Latest Cloud Data',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cloud error
                  if (_cloudError != null)
                    Container(
                      padding: const EdgeInsets.all(12), width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                      child: Text('Error: $_cloudError', style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 12)),
                    ),

                  // Cloud stats
                  if (_cloudSurveys.isNotEmpty) ...[
                    Row(children: [
                      Expanded(child: _buildStatCard("Cloud Families", _cloudFamilies.toString(), const Color(0xFF8B5CF6), isDark, theme.cardTheme.color!)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Cloud Members", _cloudMembers.toString(), const Color(0xFF059669), isDark, theme.cardTheme.color!)),
                    ]),
                    const SizedBox(height: 12),
                    // Cloud survey list
                    ..._cloudSurveys.take(10).map((data) {
                      final mc = ((data['members'] as List?) ?? []).length;
                      final surveyorName = data['surveyorName'] ?? '';
                      String dateStr = '';
                      try { dateStr = data['timestamp']?.toString().substring(0, 10) ?? ''; } catch (_) {}
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark ? null : Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                            child: const Icon(Icons.cloud_done_rounded, size: 18, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(data['householdId'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface)),
                            Text('$mc members · ${data['address'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (surveyorName.isNotEmpty || dateStr.isNotEmpty)
                              Text('${surveyorName.isNotEmpty ? surveyorName : ""} ${dateStr.isNotEmpty ? "· $dateStr" : ""}'.trim(), style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(data['status'] ?? 'Synced', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green)),
                          ),
                        ]),
                      );
                    }),
                  ] else if (!_isFetchingCloud) ...[
                    Container(
                      padding: const EdgeInsets.all(20), width: double.infinity,
                      decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16), border: isDark ? null : Border.all(color: Colors.grey.shade200)),
                      child: Column(children: [
                        Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text("No cloud data yet", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14)),
                        Text("Tap the button above to fetch from Firebase", style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),

                  Text("Recent Local Surveys", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  _buildRecentSurveysList(isDark, theme),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const Step1Household()));
          _loadStats();
        },
        elevation: 4,
        label: Text("New Survey", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRecentSurveysList(bool isDark, ThemeData theme) {
    final allSurveys = DatabaseService().getAllSurveys();
    if (allSurveys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20), width: double.infinity,
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16), border: isDark ? null : Border.all(color: Colors.grey.shade200)),
        child: Text("Tap 'New Survey' to get started.", style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14)),
      );
    }
    allSurveys.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentSurveys = allSurveys.take(3).toList();
    return Column(
      children: recentSurveys.map((survey) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: survey.isSynced
                  ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50)
                  : (isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50),
              child: Icon(survey.isSynced ? Icons.cloud_done : Icons.cloud_upload, color: survey.isSynced ? Colors.green : Colors.orange),
            ),
            title: Text(survey.householdId, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            subtitle: Text("${survey.members.length} members • ${survey.status}", style: GoogleFonts.inter(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SurveyDetailScreen(survey: survey))),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResumeDraftCard(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.primary.withOpacity(0.1) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Unfinished Survey", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary)),
          Text("Household: ${_activeDraft!.householdId}", style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ])),
        ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Step1Household(existingSurvey: _activeDraft))).then((_) => _loadStats());
          },
          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16)),
          child: const Text("Resume"),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () async {
            final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
              title: const Text("Discard Draft?"),
              content: const Text("This will permanently delete your unfinished survey data."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Discard", style: TextStyle(color: Colors.red))),
              ],
            ));
            if (confirmed == true) { await DatabaseService().deleteDraft(); _loadStats(); }
          },
        ),
      ]),
    );
  }

  Widget _buildStatCard(String label, String count, Color color, bool isDark, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(children: [
          Text(count, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
