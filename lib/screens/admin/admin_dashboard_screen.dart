import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_census/screens/admin/enumerator_detail_screen.dart';
import 'package:smart_census/screens/auth/login_screen.dart';
import 'package:smart_census/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabs = [
      const _OverviewTab(),
      const _EnumeratorsTab(),
      const _AllSurveysTab(),
      const _AdminProfileTab(),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          selectedItemColor: const Color(0xFFFF6B35),
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Enumerators'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Surveys'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// ─── TAB 1: OVERVIEW ────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();
  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _loading = false;
  String? _error;
  int _totalSurveys = 0;
  int _totalMembers = 0;
  int _surveyorCount = 0;
  Map<String, int> _dailyCounts = {};
  List<Map<String, dynamic>> _recentSurveys = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('surveys').get();
      final docs = snapshot.docs;
      int totalMembers = 0;
      Set<String> surveyorIds = {};
      Map<String, int> dailyCounts = {};
      List<Map<String, dynamic>> recentSurveys = [];

      for (var doc in docs) {
        final data = doc.data();
        final members = data['members'] as List<dynamic>? ?? [];
        totalMembers += members.length;
        final sid = data['surveyorPhone'] as String? ?? 'unknown';
        surveyorIds.add(sid);
        recentSurveys.add(data);
        try {
          final ts = DateTime.parse(data['timestamp'] ?? '');
          final key = DateFormat('MM/dd').format(ts);
          dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
        } catch (_) {}
      }

      recentSurveys.sort((a, b) => (b['timestamp'] ?? '').toString().compareTo((a['timestamp'] ?? '').toString()));

      setState(() {
        _totalSurveys = docs.length;
        _totalMembers = totalMembers;
        _surveyorCount = surveyorIds.length;
        _dailyCounts = dailyCounts;
        _recentSurveys = recentSurveys;
        _loading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${docs.length} surveys from Firebase'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchData, tooltip: 'Refresh Data'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF4444)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome, Admin', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Census Management Portal', style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
                    ]),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── FETCH BUTTON ──
            InkWell(
              onTap: _loading ? null : _fetchData,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFE05500)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark ? [] : [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    _loading ? 'Fetching from Firebase...' : 'Fetch Latest Data from Firebase',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // Error display
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12), width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                child: Text('Error: $_error', style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 12)),
              ),

            // KPI section
            Text('Key Metrics', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _kpiCard('Total Surveys', _totalSurveys.toString(), Icons.assignment_rounded, const Color(0xFF4F46E5), isDark),
                _kpiCard('Total Members', _totalMembers.toString(), Icons.people_alt_rounded, const Color(0xFF059669), isDark),
                _kpiCard('Surveyors', _surveyorCount.toString(), Icons.person_search_rounded, const Color(0xFFFF6B35), isDark),
                _kpiCard('Families', _totalSurveys.toString(), Icons.family_restroom_rounded, const Color(0xFF8B5CF6), isDark),
              ],
            ),
            const SizedBox(height: 24),

            // Recent surveys list
            Text('Recent Surveys', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            if (_recentSurveys.isEmpty && !_loading)
              Container(
                padding: const EdgeInsets.all(20), width: double.infinity,
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Icon(Icons.cloud_off_rounded, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('No survey data yet', style: GoogleFonts.inter(color: Colors.grey)),
                  Text('Tap the button above to fetch from Firebase', style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 12)),
                ]),
              )
            else
              ..._recentSurveys.take(8).map((data) {
                final mc = ((data['members'] as List?) ?? []).length;
                final sn = data['surveyorName'] ?? '';
                String dateStr = '';
                try { dateStr = data['timestamp']?.toString().substring(0, 10) ?? ''; } catch (_) {}
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: isDark ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
                      child: const Icon(Icons.assignment, size: 20, color: Color(0xFFFF6B35))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(data['householdId'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface)),
                      Text('$mc members · ${data['address'] ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (sn.isNotEmpty) Text('by $sn · $dateStr', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(data['status'] ?? 'Synced', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green)),
                    ),
                  ]),
                );
              }),
            const SizedBox(height: 24),

            // Daily activity
            Text('Daily Activity', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            if (_dailyCounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(20), width: double.infinity,
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
                child: Text('No activity data yet.', style: GoogleFonts.inter(color: Colors.grey)),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: _dailyCounts.entries.take(7).map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Text(e.key, style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (e.value / (_totalSurveys == 0 ? 1 : _totalSurveys)).clamp(0.0, 1.0),
                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF6B35)),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                    ]),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── TAB 2: ENUMERATORS ─────────────────────────────────────
class _EnumeratorsTab extends StatelessWidget {
  const _EnumeratorsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Enumerators', style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEnumeratorDialog(context),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('surveys').snapshots(),
        builder: (context, surveySnap) {
          // Build enumerator stats from surveys
          Map<String, Map<String, dynamic>> enumerators = {};
          if (surveySnap.hasData) {
            for (var doc in surveySnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final phone = data['surveyorPhone'] as String? ?? 'unknown';
              final name = data['surveyorName'] as String? ?? 'Surveyor';
              final members = (data['members'] as List<dynamic>?)?.length ?? 0;
              if (!enumerators.containsKey(phone)) {
                enumerators[phone] = {'name': name, 'phone': phone, 'families': 0, 'members': 0, 'surveys': <Map<String, dynamic>>[]};
              }
              enumerators[phone]!['families'] = (enumerators[phone]!['families'] as int) + 1;
              enumerators[phone]!['members'] = (enumerators[phone]!['members'] as int) + members;
              (enumerators[phone]!['surveys'] as List).add(data);
            }
          }

          // Also fetch from enumerators collection
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('enumerators').snapshots(),
            builder: (context, enumSnap) {
              if (enumSnap.hasData) {
                for (var doc in enumSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final phone = data['phone'] as String? ?? '';
                  if (phone.isNotEmpty && !enumerators.containsKey(phone)) {
                    enumerators[phone] = {
                      'name': data['name'] ?? 'Surveyor',
                      'phone': phone,
                      'area': data['area'] ?? '',
                      'families': 0, 'members': 0,
                      'surveys': <Map<String, dynamic>>[],
                      'status': data['status'] ?? 'Active',
                    };
                  } else if (phone.isNotEmpty) {
                    enumerators[phone]!['area'] = data['area'] ?? '';
                    enumerators[phone]!['status'] = data['status'] ?? 'Active';
                    if (data['name'] != null) enumerators[phone]!['name'] = data['name'];
                  }
                }
              }

              final enumList = enumerators.values.toList();
              enumList.sort((a, b) => (b['families'] as int).compareTo(a['families'] as int));

              if (enumList.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No enumerators found', style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Surveyors appear here after uploading data', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                ]));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: enumList.length,
                itemBuilder: (context, index) {
                  final e = enumList[index];
                  final status = e['status'] as String? ?? 'Active';
                  final isActive = status == 'Active';
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => EnumeratorDetailScreen(enumeratorData: e),
                    )),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark ? null : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isActive ? const Color(0xFFFF6B35).withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                          child: Text((e['name'] as String)[0].toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
                              color: isActive ? const Color(0xFFFF6B35) : Colors.grey)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(e['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: theme.colorScheme.onSurface))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                                color: isActive ? Colors.green : Colors.red)),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text(e['phone'] as String, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Row(children: [
                            _statBadge(Icons.family_restroom, '${e['families']} families', const Color(0xFF4F46E5)),
                            const SizedBox(width: 10),
                            _statBadge(Icons.people_alt_outlined, '${e['members']} members', const Color(0xFF059669)),
                          ]),
                        ])),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
                      ]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _statBadge(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    ]);
  }

  void _showAddEnumeratorDialog(BuildContext context) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final areaC = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Add Enumerator', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
        const SizedBox(height: 12),
        TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextField(controller: areaC, decoration: const InputDecoration(labelText: 'Assigned Area', prefixIcon: Icon(Icons.location_on))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (nameC.text.trim().isEmpty || phoneC.text.trim().isEmpty) return;
            await FirebaseFirestore.instance.collection('enumerators').doc(phoneC.text.trim()).set({
              'name': nameC.text.trim(),
              'phone': phoneC.text.trim(),
              'area': areaC.text.trim(),
              'status': 'Active',
              'createdAt': DateTime.now().toIso8601String(),
            });
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
          child: const Text('Add'),
        ),
      ],
    ));
  }
}

// ─── TAB 3: ALL SURVEYS ─────────────────────────────────────
class _AllSurveysTab extends StatefulWidget {
  const _AllSurveysTab();
  @override
  State<_AllSurveysTab> createState() => _AllSurveysTabState();
}

class _AllSurveysTabState extends State<_AllSurveysTab> {
  String _search = '';
  List<Map<String, dynamic>> _surveys = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSurveys();
  }

  Future<void> _fetchSurveys() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snapshot = await FirebaseFirestore.instance.collection('surveys').get();
      final surveys = snapshot.docs.map((d) => d.data()).toList();
      surveys.sort((a, b) => (b['timestamp'] ?? '').toString().compareTo((a['timestamp'] ?? '').toString()));
      setState(() { _surveys = surveys; _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${surveys.length} surveys'), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    var filtered = _surveys;
    if (_search.isNotEmpty) {
      filtered = _surveys.where((data) {
        final hid = (data['householdId'] ?? '').toString().toLowerCase();
        final addr = (data['address'] ?? '').toString().toLowerCase();
        final sname = (data['surveyorName'] ?? '').toString().toLowerCase();
        return hid.contains(_search.toLowerCase()) || addr.contains(_search.toLowerCase()) || sname.contains(_search.toLowerCase());
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('All Census Data', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _fetchSurveys, tooltip: 'Refresh'),
        ],
      ),
      body: Column(children: [
        // Fetch button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: InkWell(
            onTap: _loading ? null : _fetchSurveys,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFE05500)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(_loading ? 'Fetching...' : 'Fetch Latest Surveys', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(10), width: double.infinity,
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
              child: Text('Error: $_error', style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 12)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search surveys...', prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('${filtered.length} surveys found', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(_loading ? 'Loading...' : 'No surveys found', style: GoogleFonts.inter(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index];
                    final memberCount = (data['members'] as List<dynamic>?)?.length ?? 0;
                    final status = data['status'] ?? 'Pending';
                    final surveyorName = data['surveyorName'] ?? 'Unknown';
                    String dateStr = '';
                    try { dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(data['timestamp'])); } catch (_) {}

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: isDark ? null : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(data['householdId'] ?? 'N/A',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: status == 'Uploaded' || status == 'Auto-Verified' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                              color: status == 'Uploaded' || status == 'Auto-Verified' ? Colors.green : Colors.orange)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(data['address'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(surveyorName, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                          const Spacer(),
                          Text('$memberCount members', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4F46E5), fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ─── TAB 4: ADMIN PROFILE ───────────────────────────────────
class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Admin avatar
          CircleAvatar(
            radius: 45,
            backgroundColor: const Color(0xFFFF6B35).withOpacity(0.15),
            child: const Icon(Icons.admin_panel_settings_rounded, size: 45, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(height: 16),
          Text('Administrator', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Census Admin', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFFF6B35))),
          ),
          const SizedBox(height: 32),
          // System stats from Firestore
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('surveys').snapshots(),
            builder: (context, snap) {
              final total = snap.data?.docs.length ?? 0;
              int members = 0;
              if (snap.hasData) {
                for (var d in snap.data!.docs) {
                  members += ((d.data() as Map<String, dynamic>)['members'] as List?)?.length ?? 0;
                }
              }
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  _stat('Surveys', total.toString(), theme.colorScheme.onSurface, Colors.grey),
                  Container(height: 40, width: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                  _stat('Members', members.toString(), theme.colorScheme.onSurface, Colors.grey),
                ]),
              );
            },
          ),
          const SizedBox(height: 24),
          // Logout
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('user_role');
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text('Log Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50, foregroundColor: Colors.red,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  static Widget _stat(String label, String value, Color textColor, Color sub) {
    return Expanded(child: Column(children: [
      Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: sub)),
    ]));
  }
}
