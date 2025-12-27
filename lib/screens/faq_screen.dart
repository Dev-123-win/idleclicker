import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/ads/native_ad_widget.dart';

/// FAQ screen with expandable items
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How does TapMine work?',
      'answer':
          'Tap the coin button to earn virtual coins. Complete missions to unlock more rewards. When you reach 100,000 coins (₹100), you can withdraw real money to your UPI account.',
    },
    {
      'question': 'How much can I earn?',
      'answer':
          'You can earn up to ₹100 per month by completing all 50 missions. The first 15 missions (₹50) are easy, while the remaining 35 missions (₹50) are harder but more rewarding.',
    },
    {
      'question': 'What is the minimum withdrawal?',
      'answer':
          'The minimum withdrawal is ₹100 (100,000 coins). Once you withdraw, your missions will reset so you can earn again next month.',
    },
    {
      'question': 'How do withdrawals work?',
      'answer':
          'Enter your UPI ID (like yourname@upi) and submit a withdrawal request. Our team will process it within 24-48 hours and send money directly to your UPI account.',
    },
    {
      'question': 'What is the referral program?',
      'answer':
          'Share your unique referral code with friends. When they sign up using your code, you get 2,000 coins and they get 5,000 coins as a welcome bonus!',
    },
    {
      'question': 'Why do I see ads?',
      'answer':
          'Ads are how we generate revenue to pay users. We share 35% of ad revenue with you through mission rewards. Watching more ads helps you earn faster!',
    },
    {
      'question': 'Can I use multiple accounts?',
      'answer':
          'No. Only one account per device is allowed. Creating multiple accounts will result in permanent ban and loss of earnings.',
    },
    {
      'question': 'Why is the app asking for internet?',
      'answer':
          'Internet connection is required to sync your progress, verify your device, show ads, and process withdrawals. Your data is synced every 3 hours.',
    },
    {
      'question': 'What happens if my withdrawal is rejected?',
      'answer':
          'Withdrawals may be rejected if there are suspicious activities or invalid UPI details. Your coins will be returned and you can try again with correct information.',
    },
    {
      'question': 'How do I contact support?',
      'answer':
          'For any issues or questions, email us at support@tapmine.app. We typically respond within 24 hours.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.md),
        itemCount: _faqs.length + 1, // +1 for native ad
        itemBuilder: (context, index) {
          // Show native ad in middle
          if (index == _faqs.length ~/ 2) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.sm),
              child: NativeAdWidget(
                templateType: TemplateType.small,
                height: 100,
              ),
            );
          }

          final faqIndex = index > _faqs.length ~/ 2 ? index - 1 : index;
          if (faqIndex >= _faqs.length) return const SizedBox();

          final faq = _faqs[faqIndex];

          return _FAQItem(question: faq['question']!, answer: faq['answer']!)
              .animate(delay: Duration(milliseconds: 50 * faqIndex))
              .fadeIn()
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: NeumorphicDecoration.flat(),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.md,
                0,
                AppDimensions.md,
                AppDimensions.md,
              ),
              child: Text(
                widget.answer,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
