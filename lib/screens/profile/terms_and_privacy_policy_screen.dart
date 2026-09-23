import 'package:flutter/material.dart';

class TermsAndPrivacyPolicyScreen extends StatelessWidget {
  const TermsAndPrivacyPolicyScreen({super.key});

  // Updated to match the light theme design system
  static const Color primaryColor = Color(0xFF22C55E);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                       icon: Icon(Icons.arrow_back_ios),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Terms & Privacy Policy',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.how_to_vote_rounded, color: primaryColor, size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'VoteSense Terms & Privacy',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Last updated: September 2026',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      Divider(color: Colors.black.withValues(alpha: 0.08), height: 28),

                      _buildSectionHeader('1. Acceptance of Terms'),
                      _buildParagraph(
                        'By downloading, accessing, or using the VoteSense mobile application, you agree to comply with and be bound by these Terms of Service and our Privacy Policy. If you do not agree to all of these terms, you must immediately discontinue use of the application.',
                      ),

                      _buildSectionHeader('2. Civic Information & Independence'),
                      _buildParagraph(
                        'VoteSense is an independent civic technology platform designed to provide accessible insights, candidate information, and public opinion polls. We are not an official electoral commission or government voting portal. While we ensure data integrity, users should verify critical electoral mandates from official independent electoral bodies.',
                      ),

                      _buildSectionHeader('3. User Accounts & Integrity'),
                      _buildParagraph(
                        'To participate in polls, discussions, or save preference settings, users may need to register an account. You agree to provide accurate information, refrain from voter manipulation or fraudulent polling activities, and safeguard your account credentials.',
                      ),

                      _buildSectionHeader('4. Privacy Policy & Data Handling'),
                      _buildParagraph(
                        'We deeply respect your privacy. VoteSense collects basic account details (such as username and email address) along with participation records strictly required for poll accuracy and platform security.',
                      ),
                      _buildParagraph(
                        'Individual user poll choices are handled securely. We do not sell or monetize personal voting data or disclose individual choices to third parties without explicit authorization.',
                      ),

                      _buildSectionHeader('5. Limitation of Liability'),
                      _buildParagraph(
                        'VoteSense and its developers shall not be held liable for any direct, indirect, incidental, or consequential damages arising out of or in connection with your use of the application, public poll trends, or candidate profiles hosted herein.',
                      ),

                      _buildSectionHeader('6. Modifications to Terms'),
                      _buildParagraph(
                        'We reserve the right to modify these terms or polling rules at any time. Continued use of the application following modifications indicates your acceptance of the updated terms.',
                      ),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryColor, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'For support or policy inquiries, contact us at openlawsnig@gmail.com',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}