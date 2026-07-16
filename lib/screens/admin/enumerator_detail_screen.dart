import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EnumeratorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> enumeratorData;
  const EnumeratorDetailScreen({super.key, required this.enumeratorData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = enumeratorData['name'] as String? ?? 'Surveyor';
    final phone = enumeratorData['phone'] as String? ?? '';
    final area = enumeratorData['area'] as String? ?? 'Not assigned';
    final families = enumeratorData['families'] as int? ?? 0;
    final members = enumeratorData['members'] as int? ?? 0;
    final status = enumeratorData['status'] as String? ?? 'Active';
    final isActive = status == 'Active';

    return Scaffold(
      appBar: AppBar(
        title: Text('Enumerator Details', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'toggle_status') {
                final newStatus = isActive ? 'Inactive' : 'Active';
                await FirebaseFirestore.instance.collection('enumerators').doc(phone).set(
                  {'name': name, 'phone': phone, 'area': area, 'status': newStatus},
                  SetOptions(merge: true),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'toggle_status', child: Text(isActive ? 'Deactivate' : 'Activate')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [const Color(0xFFFF6B35), const Color(0xFFFF4444)]
                      : [Colors.grey.shade600, Colors.grey.shade500],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(name[0].toUpperCase(),
                    style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const SizedBox(height: 14),
                Text(name, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(phone, style: GoogleFonts.inter(fontSize: 15, color: Colors.white70)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            // Stats row
            Row(children: [
              _statCard('Families', families.toString(), Icons.family_restroom, const Color(0xFF4F46E5), isDark, theme),
              const SizedBox(width: 12),
              _statCard('Members', members.toString(), Icons.people_alt, const Color(0xFF059669), isDark, theme),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: isDark ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Icon(Icons.location_on_outlined, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 10),
                Text('Area: ', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14)),
                Expanded(child: Text(area, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: theme.colorScheme.onSurface))),
              ]),
            ),
            const SizedBox(height: 24),
            // Surveys by this enumerator
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Surveys Submitted', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('surveys')
                  .where('surveyorPhone', isEqualTo: phone)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20), width: double.infinity,
                    decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(14)),
                    child: Text('No surveys found for this enumerator.', style: GoogleFonts.inter(color: Colors.grey)),
                  );
                }
                return Column(
                  children: snap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final mc = (d['members'] as List?)?.length ?? 0;
                    String dateStr = '';
                    try { dateStr = DateFormat('dd MMM yyyy').format(DateTime.parse(d['timestamp'])); } catch (_) {}
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: isDark ? null : Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                          child: const Icon(Icons.assignment, size: 20, color: Color(0xFF4F46E5)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(d['householdId'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
                          Text('$mc members · $dateStr', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(d['status'] ?? '', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green)),
                        ),
                      ]),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isDark, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}
