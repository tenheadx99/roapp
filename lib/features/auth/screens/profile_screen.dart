import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../../../widgets/label_text.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../bloc/auth_bloc.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;
  late final TextEditingController _currentPasskeyController;
  late final TextEditingController _newPasskeyController;
  late final TextEditingController _confirmPasskeyController;
  final AuthRepository _authRepository = AuthRepository();
  late final Future<_ProfileSummary> _summaryFuture;
  bool _isSaving = false;
  bool _isUpdatingPasskey = false;
  bool _obscureCurrentPasskey = true;
  bool _obscureNewPasskey = true;
  bool _obscureConfirmPasskey = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _roleController = TextEditingController(text: widget.user.role);
    _currentPasskeyController = TextEditingController();
    _newPasskeyController = TextEditingController();
    _confirmPasskeyController = TextEditingController();
    _summaryFuture = _loadSummary();

    _nameController.addListener(_refreshPreview);
    _emailController.addListener(_refreshPreview);
    _phoneController.addListener(_refreshPreview);
    _roleController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshPreview);
    _emailController.removeListener(_refreshPreview);
    _phoneController.removeListener(_refreshPreview);
    _roleController.removeListener(_refreshPreview);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _currentPasskeyController.dispose();
    _newPasskeyController.dispose();
    _confirmPasskeyController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final role = _roleController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required.')),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _authRepository.updateUserProfile(
        widget.user.copyWith(
          name: name,
          email: email,
          phone: phone,
          role: role,
        ),
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(CurrentUserUpdated(updated));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changePasskey() async {
    final currentPasskey = _currentPasskeyController.text.trim();
    final newPasskey = _newPasskeyController.text.trim();
    final confirmPasskey = _confirmPasskeyController.text.trim();

    if (currentPasskey.isEmpty || newPasskey.isEmpty || confirmPasskey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all password fields.')),
      );
      return;
    }

    if (newPasskey != confirmPasskey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    setState(() {
      _isUpdatingPasskey = true;
    });

    try {
      await _authRepository.updateUserPasskey(
        userId: widget.user.id,
        currentPasskey: currentPasskey,
        newPasskey: newPasskey,
      );

      _currentPasskeyController.clear();
      _newPasskeyController.clear();
      _confirmPasskeyController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPasskey = false;
        });
      }
    }
  }

  void _logout() {
    context.read<AuthBloc>().add(LogoutRequested());
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewUser = widget.user.copyWith(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      role: _roleController.text,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF007FFF), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007FFF).withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(
                      previewUser.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  HeaderText(
                    text: previewUser.displayName,
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    previewUser.role.trim().isEmpty
                        ? 'Operations Team'
                        : previewUser.role,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    previewUser.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<_ProfileSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                final summary = snapshot.data;
                return _buildSummaryCards(summary);
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007FFF).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: Color(0xFF007FFF),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SemiBoldTextView(text: 'Local Profile', fontSize: 15),
                        const SizedBox(height: 4),
                        SubRegularText(
                          text: 'Member ID: ${widget.user.id}',
                          fontSize: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SemiBoldTextView(text: 'Your Details', fontSize: 18),
            const SizedBox(height: 16),
            const LabelText(text: 'Full Name'),
            CustomTextField(
              controller: _nameController,
              hintText: 'Your full name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: 16),
            const LabelText(text: 'Email Address'),
            CustomTextField(
              controller: _emailController,
              hintText: 'name@company.com',
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            const SizedBox(height: 16),
            const LabelText(text: 'Phone Number'),
            CustomTextField(
              controller: _phoneController,
              hintText: '+91 9876543210',
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: 16),
            const LabelText(text: 'Role'),
            CustomTextField(
              controller: _roleController,
              hintText: 'Operations Admin',
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined, color: Color(0xFF007FFF)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldTextView(text: 'Profile Tip', fontSize: 15),
                        SizedBox(height: 4),
                        SubRegularText(
                          text:
                              'Keeping your name, role, and phone updated helps technicians and suppliers identify the right contact faster.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SemiBoldTextView(text: 'Security', fontSize: 18),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SubRegularText(
                    text:
                        'Update your local app password here. This affects only this device database.',
                    fontSize: 13,
                  ),
                  const SizedBox(height: 16),
                  const LabelText(text: 'Current Password'),
                  CustomTextField(
                    controller: _currentPasskeyController,
                    hintText: 'Enter current password',
                    obscureText: _obscureCurrentPasskey,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPasskey = !_obscureCurrentPasskey;
                        });
                      },
                      icon: Icon(
                        _obscureCurrentPasskey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LabelText(text: 'New Password'),
                  CustomTextField(
                    controller: _newPasskeyController,
                    hintText: 'Enter new password',
                    obscureText: _obscureNewPasskey,
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureNewPasskey = !_obscureNewPasskey;
                        });
                      },
                      icon: Icon(
                        _obscureNewPasskey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const LabelText(text: 'Confirm New Password'),
                  CustomTextField(
                    controller: _confirmPasskeyController,
                    hintText: 'Re-enter new password',
                    obscureText: _obscureConfirmPasskey,
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPasskey = !_obscureConfirmPasskey;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPasskey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUpdatingPasskey ? null : _changePasskey,
                      icon: const Icon(Icons.shield_outlined),
                      label: Text(
                        _isUpdatingPasskey
                            ? 'Updating Password...'
                            : 'Update Password',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        foregroundColor: const Color(0xFF007FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: _isSaving ? 'Saving...' : 'Save Changes',
              onPressed: _isSaving ? () {} : _saveProfile,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(_ProfileSummary? summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final cardWidth = isNarrow
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 24) / 3;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _ProfileStatCard(
                label: 'Customers',
                value: '${summary?.customerCount ?? '--'}',
                icon: Icons.people_outline,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _ProfileStatCard(
                label: 'Open Jobs',
                value: '${summary?.openRequests ?? '--'}',
                icon: Icons.build_outlined,
              ),
            ),
            SizedBox(
              width: isNarrow ? constraints.maxWidth : cardWidth,
              child: _ProfileStatCard(
                label: 'Stock Units',
                value: '${summary?.stockUnits ?? '--'}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_ProfileSummary> _loadSummary() async {
    final customers = await CustomerRepository().getCustomers();
    final requests = await DispatchRepository().getServiceRequests();
    final inventory = await InventoryRepository().getInventory();

    return _ProfileSummary(
      customerCount: customers.length,
      openRequests: requests.where((request) => request.status != 'completed').length,
      stockUnits: inventory.fold<int>(0, (sum, item) => sum + item.stock),
    );
  }
}

class _ProfileSummary {
  final int customerCount;
  final int openRequests;
  final int stockUnits;

  const _ProfileSummary({
    required this.customerCount,
    required this.openRequests,
    required this.stockUnits,
  });
}

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF007FFF), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
