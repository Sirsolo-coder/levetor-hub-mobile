import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const Color skyBlue = Color(0xFF29B6F6);
  static const String whatsappNumber = '2349131542208';

  Future<void> _openWhatsApp(BuildContext context) async {
    final Uri url = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(
        'Hello Levetor Hub, I would like to make an enquiry.',
      )}',
    );

    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open WhatsApp.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open WhatsApp.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Us',
          style: TextStyle(
            color: skyBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: skyBlue,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: skyBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                size: 60,
                color: skyBlue,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'We’re Here to Help',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Have a question about a product, order or service? '
              'Contact Levetor Hub and our team will be happy to assist you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: skyBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: skyBlue,
                  ),
                ),
                title: const Text(
                  'WhatsApp',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  '2349131542208',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                  color: skyBlue,
                ),
                onTap: () => _openWhatsApp(context),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openWhatsApp(context),
                icon: const Icon(Icons.chat),
                label: const Text(
                  'Chat with us on WhatsApp',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: skyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Levetor Hub',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Every Gadget You Love, One Hub.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
