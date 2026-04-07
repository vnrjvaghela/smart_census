import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_census/screens/ai/ocr_screen.dart';
import 'package:smart_census/screens/api/api_screen.dart';
import 'package:smart_census/screens/notifications/notification_screen.dart';

class LabFeaturesScreen extends StatelessWidget {
  const LabFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lab Features', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Document Scanner (OCR)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              subtitle: const Text('LAB 11'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrScreen())),
            ),
          ),
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.api, color: Colors.green),
              title: Text('Census Database (API)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              subtitle: const Text('LAB 9'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApiScreen())),
            ),
          ),
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: Text('Push Alerts (Notifications)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              subtitle: const Text('LAB 10'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
