import 'package:flutter/material.dart';
import '../../core/models/user_model.dart';
import '../../core/services/game_service.dart';
import '../theme/app_theme.dart';
import '../widgets/neumorphic_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel user;
  final GameService gameService;
  final VoidCallback onBack;
  final VoidCallback onNavigateToHelp;

  const SettingsScreen({
    super.key,
    required this.user,
    required this.gameService,
    required this.onBack,
    required this.onNavigateToHelp,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English';

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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildSettingsSection(context),
                    const SizedBox(height: 24),
                    _buildAboutSection(context),
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
          NeumorphicIconButton(
            icon: Icons.arrow_back,
            onPressed: widget.onBack,
          ),
          const SizedBox(width: 16),
          const Text(
            'SETTINGS',
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

  Widget _buildSettingsSection(BuildContext context) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildHapticTile(),
          const Divider(color: Colors.white12, height: 32),
          _buildNavigationTile(
            icon: Icons.language,
            title: 'Language',
            value: _selectedLanguage,
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(color: Colors.white12, height: 32),
          _buildNavigationTile(
            icon: Icons.help_outline,
            title: 'Help & FAQ',
            onTap: widget.onNavigateToHelp,
          ),
        ],
      ),
    );
  }

  Widget _buildHapticTile() {
    final current = widget.user.hapticSetting;
    return _buildSettingRow(
      icon: Icons.vibration,
      title: 'Haptic Mode',
      trailing: TextButton(
        onPressed: () {
          final next = current == 'strong'
              ? 'eco'
              : current == 'eco'
              ? 'off'
              : 'strong';
          widget.gameService.updateUserHaptic(next);
          setState(() {});
        },
        child: Text(
          current.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'App Info',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _buildNavigationTile(
            icon: Icons.info_outline,
            title: 'About TapMine',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (value != null)
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TapMine',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 TapMine. All rights reserved.',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/AppCoin.png', width: 48, height: 48),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = ['English', 'हिंदी', 'தமிழ்', 'తెలుగు', 'ಕನ್ನಡ'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: NeumorphicDecoration.convex(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...languages.map(
                (lang) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(context);
                    AppSnackBar.success(context, 'Language changed to $lang');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _selectedLanguage == lang
                          ? AppTheme.primary.withOpacity(0.2)
                          : AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedLanguage == lang
                          ? Border.all(color: AppTheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        lang,
                        style: TextStyle(
                          color: _selectedLanguage == lang
                              ? AppTheme.primary
                              : Colors.white,
                          fontWeight: _selectedLanguage == lang
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
