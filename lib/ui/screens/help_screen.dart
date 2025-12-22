import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';

class HelpScreen extends StatelessWidget {
  final VoidCallback onBack;

  const HelpScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildFaqItem(
                      'What is TapMine?',
                      'TapMine is a competitive mining game where you tap to earn AppCoins (AC) and complete missions for rewards.',
                    ),
                    _buildFaqItem(
                      'How do I withdraw?',
                      'Once you reach the minimum threshold of 100,000 AC (₹100), you can request a withdrawal via UPI in the Withdrawal screen.',
                    ),
                    _buildFaqItem(
                      'What are Missions?',
                      'Missions are tasks that reward you with bonus AC. Each mission has a 30-day cooldown period once completed.',
                    ),
                    _buildFaqItem(
                      'How does Referral work?',
                      'Share your code with friends. When they use it, you both get rewards! You get 2,000 AC and they get 2,500 AC.',
                    ),
                    _buildFaqItem(
                      'Is the game free?',
                      'Yes! TapMine is completely free to play. You can earn AC by tapping and completing missions.',
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          NeumorphicIconButton(icon: Icons.arrow_back, onPressed: onBack),
          const SizedBox(width: 16),
          const Text(
            'HELP & FAQ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: NeumorphicCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              answer,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
