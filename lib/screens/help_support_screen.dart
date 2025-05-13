import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    // Simple implementation without using url_launcher
    // In a real app, this would use the url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Would launch: $url'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(51), // 0.2 * 255 = 51
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to common questions or contact our support team',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // FAQ Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              'How do I track a PUV?',
              'Select a PUV type from the home screen, then choose a route from the available routes. The app will show you all active PUVs on that route.',
            ),
            _buildFaqItem(
              context,
              'How do I share my location with family members?',
              'Go to the Family Group section from the menu, add family members, and enable location sharing. They will be able to see your location on their map.',
            ),
            _buildFaqItem(
              context,
              'How do I save my favorite routes?',
              'When viewing a route, tap the heart icon to add it to your favorites. You can access your favorite routes from the menu.',
            ),
            _buildFaqItem(
              context,
              'What does the visibility button do?',
              'The visibility button toggles whether your location is visible to drivers. When enabled, drivers can see you on their map.',
            ),
            _buildFaqItem(
              context,
              'How accurate is the ETA?',
              'ETAs are calculated based on current traffic conditions and the average speed of the vehicle. They are estimates and may vary.',
            ),
            const SizedBox(height: 24),

            // Contact Section
            const Text(
              'Contact Us',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              icon: Icons.email,
              title: 'Email Support',
              subtitle: 'support@ipara.com',
              onTap: () => _launchUrl(context, 'mailto:support@ipara.com'),
            ),
            _buildContactItem(
              icon: Icons.phone,
              title: 'Phone Support',
              subtitle: '+63 912 345 6789',
              onTap: () => _launchUrl(context, 'tel:+639123456789'),
            ),
            _buildContactItem(
              icon: Icons.chat,
              title: 'Live Chat',
              subtitle: 'Available 24/7',
              onTap: () {
                // TODO: Implement live chat functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Live chat will be available soon!'),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // App Information
            const Text(
              'App Information',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem('Version', '2.9.3'),
            _buildInfoItem('Last Updated', 'May 2025'),
            _buildInfoItem('Developed By', 'iPara Team'),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  TextButton(
                    onPressed:
                        () => _launchUrl(context, 'https://ipara.com/terms'),
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => _launchUrl(context, 'https://ipara.com/privacy'),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2025 iPara. All rights reserved.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconColor: Colors.amber,
        collapsedIconColor: Colors.amber,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(51), // 0.2 * 255 = 51
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.amber),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
