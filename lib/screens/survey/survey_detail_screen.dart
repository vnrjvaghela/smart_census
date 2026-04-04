import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/screens/survey/household_info_screen.dart';

class SurveyDetailScreen extends StatelessWidget {
  final SurveyModel survey;

  const SurveyDetailScreen({super.key, required this.survey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Survey: ${survey.householdId}'),
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
            // Status Row: Sync + AI Verified badges
            Row(
              children: [
                // Sync Status Chip
                _buildStatusChip(
                  icon: survey.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                  label: survey.isSynced ? 'Synced' : 'Pending Upload',
                  color: survey.isSynced ? Colors.green : Colors.orange,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                // AI Verified Chip
                _buildStatusChip(
                  icon: survey.aiVerified ? Icons.verified_rounded : Icons.shield_outlined,
                  label: survey.aiVerified ? 'AI Verified' : 'Not Verified',
                  color: survey.aiVerified ? Colors.blue : Colors.grey,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Household Info
            _buildSectionTitle('Household Details', theme),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildInfoRow(Icons.home_outlined, 'Address', survey.address, isDark),
                  _buildDivider(isDark),
                  _buildInfoRow(Icons.location_on_outlined, 'GPS', '${survey.latitude}, ${survey.longitude}', isDark),
                  _buildDivider(isDark),
                  _buildInfoRow(Icons.access_time_rounded, 'Created', survey.timestamp.toString().split('.')[0], isDark),
                  _buildDivider(isDark),
                  _buildInfoRow(Icons.info_outline_rounded, 'Status', survey.status, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Family Members
            _buildSectionTitle('Family Members (${survey.members.length})', theme),
            const SizedBox(height: 8),
            _buildCard(
              isDark: isDark,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: survey.members.length,
                separatorBuilder: (c, i) => _buildDivider(isDark),
                itemBuilder: (context, index) {
                  final member = survey.members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(member.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${member.relation} • ${member.age} yrs • ${member.gender}',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Documents
            _buildSectionTitle('Documents (${survey.documentPaths.length})', theme),
            const SizedBox(height: 8),
            if (survey.documentPaths.isEmpty)
              _buildCard(
                isDark: isDark,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text('No documents attached', style: GoogleFonts.poppins(color: Colors.grey)),
                  ),
                ),
              )
            else
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: survey.documentPaths.length,
                  itemBuilder: (context, index) {
                    final path = survey.documentPaths[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          path,
                          width: 120,
                          height: 130,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            width: 120,
                            height: 130,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.insert_drive_file, size: 36, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Blockchain Hash Card
            if (survey.blockchainHash.isNotEmpty) ...[
              _buildSectionTitle('Blockchain Fingerprint', theme),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.orange.withOpacity(0.3) : const Color(0xFFFFCC02),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fingerprint, color: Color(0xFFFF9F0A), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'SHA-256 Hash',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: const Color(0xFFFF9F0A),
                          ),
                        ),
                        const Spacer(),
                        // Copy button
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: survey.blockchainHash));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hash copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9F0A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.copy_rounded, size: 14, color: Color(0xFFFF9F0A)),
                                const SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFF9F0A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: Text(
                        survey.blockchainHash,
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          color: isDark ? Colors.green.shade300 : Colors.green.shade700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This hash uniquely identifies this survey record. Any tampering with the data will change this value.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200);
  }
}
