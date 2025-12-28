import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../services/service_locator.dart';

/// Registration screen with referral code support
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await getService<AuthService>().registerWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      referralCode: _referralController.text.trim().isEmpty
          ? null
          : _referralController.text.trim().toUpperCase(),
    );

    setState(() => _isLoading = false);

    if (result.error != null) {
      setState(() => _errorMessage = result.error);
    } else if (result.user != null && mounted) {
      // If referral code was entered, redeem it via worker
      final referralCode = _referralController.text.trim();
      if (referralCode.isNotEmpty) {
        // We don't wait for this to finish to avoid blocking the user
        // but we show a message if it succeeded
        getService<SyncService>()
            .redeemReferral(result.user!.uid, referralCode.toUpperCase())
            .then((res) {
              if (mounted && res.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Referral bonus applied! +5000 coins'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            });
      }

      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: AppColors.surface,
        ),
      );
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().shake().fadeIn(),

                if (_errorMessage != null) const SizedBox(height: 16),

                // Email field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ).animate(delay: 100.ms).fadeIn().slideX(begin: -0.1, end: 0),

                const SizedBox(height: 16),

                // Password field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: _validatePassword,
                ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1, end: 0),

                const SizedBox(height: 16),

                // Confirm password field
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: _validateConfirmPassword,
                ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1, end: 0),

                const SizedBox(height: 16),

                // Referral code field
                _buildTextField(
                  controller: _referralController,
                  label: 'Referral Code (Optional)',
                  hint: 'Enter referral code for 5000 bonus coins',
                  icon: Icons.card_giftcard,
                  textCapitalization: TextCapitalization.characters,
                ).animate(delay: 400.ms).fadeIn().slideX(begin: -0.1, end: 0),

                const SizedBox(height: 8),

                // Referral bonus info
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.gold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter a referral code to get 5000 bonus coins!',
                          style: TextStyle(color: AppColors.gold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 450.ms).fadeIn(),

                const SizedBox(height: 32),

                // Register button
                _buildRegisterButton()
                    .animate(delay: 500.ms)
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 600.ms).fadeIn(),

                const SizedBox(height: 24),

                // Terms
                Text(
                  'By registering, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ).animate(delay: 700.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Start earning coins today!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: NeumorphicDecoration.flat(),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppDimensions.md),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: NeumorphicDecoration.goldFlat(radius: AppDimensions.radiusMd),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
              ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}
