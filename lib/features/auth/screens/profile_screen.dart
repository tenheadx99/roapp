import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roapp/features/access/screens/app_access_gate.dart';
import '../../../core/utils/db_exporter.dart';
import '../../../core/database/database_helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../../../widgets/label_text.dart';
import '../../../widgets/semi_bold_text_view.dart';
import '../../../widgets/sub_regular_text.dart';
import '../../customer/repositories/customer_repository.dart';
import '../../dispatch/repositories/dispatch_repository.dart';
import '../../inventory/repositories/inventory_repository.dart';
import '../../settings/bloc/settings_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _currentUser;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;
  late final TextEditingController _currentPasskeyController;
  late final TextEditingController _newPasskeyController;
  late final TextEditingController _confirmPasskeyController;
  final AuthRepository _authRepository = AuthRepository();
  late Future<_ProfileSummary> _summaryFuture;
  bool _isSaving = false;
  bool _isUpdatingPasskey = false;
  bool _obscureCurrentPasskey = true;
  bool _obscureNewPasskey = true;
  bool _obscureConfirmPasskey = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _nameController = TextEditingController(text: _currentUser.name);
    _emailController = TextEditingController(text: _currentUser.email);
    _phoneController = TextEditingController(text: _currentUser.phone);
    _roleController = TextEditingController(text: _currentUser.role);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required.')));
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
        _currentUser.copyWith(
          name: name,
          email: email,
          phone: phone,
          role: role,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentUser = updated;
      });
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

    if (currentPasskey.isEmpty ||
        newPasskey.isEmpty ||
        confirmPasskey.isEmpty) {
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
        userId: _currentUser.id,
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
      MaterialPageRoute(builder: (_) => const AppAccessGate()),
      (route) => false,
    );
  }

  Future<void> _exportBackup() async {
    try {
      final message = await DbExporter.exportDatabase();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final message = await DbExporter.restoreLatestBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      context.read<AuthBloc>().add(AuthStarted());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _clearAllData() async {
    bool shouldBackup = context.read<SettingsCubit>().state.autoBackupEnabled;
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirm Data Clearance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This action will delete all customers, inventory, and history. It cannot be undone.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: shouldBackup,
                onChanged: (val) =>
                    setDialogState(() => shouldBackup = val ?? false),
                title: const Text(
                  'Backup before deleting',
                  style: TextStyle(fontSize: 14),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Enter Password to Confirm',
                  hintText: 'password123',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (passwordController.text ==
                    AuthRepository.defaultAdminPasskey) {
                  if (shouldBackup) {
                    try {
                      final message = await DbExporter.exportDatabase();
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                      return;
                    }
                  }
                  try {
                    await DatabaseHelper.instance.clearAllData();
                    if (!mounted || !dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    setState(() {
                      _summaryFuture = _loadSummary();
                    });
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('All data cleared.')),
                    );
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect password!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Confirm & Clear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDemoData() async {
    bool shouldBackup = context.read<SettingsCubit>().state.autoBackupEnabled;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Load Demo Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will replace current business records with sample customers, inventory, technicians, dispatch jobs, and previous service history.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: shouldBackup,
                onChanged: (val) =>
                    setDialogState(() => shouldBackup = val ?? false),
                title: const Text(
                  'Backup current data first',
                  style: TextStyle(fontSize: 14),
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (shouldBackup) {
                    final message = await DbExporter.exportDatabase();
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  }

                  await DatabaseHelper.instance.loadDemoData();

                  if (!mounted || !dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  context.read<AuthBloc>().add(AuthStarted());
                  Navigator.of(this.context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AppAccessGate()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: const Text('Load Demo Data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBusinessProfileSheet() async {
    final settingsCubit = context.read<SettingsCubit>();
    final current = settingsCubit.state;
    final nameController = TextEditingController(text: current.businessName);
    final phoneController = TextEditingController(text: current.businessPhone);
    final addressController = TextEditingController(
      text: current.businessAddress,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SemiBoldTextView(text: 'Business Profile', fontSize: 18),
              const SizedBox(height: 16),
              CustomTextField(
                controller: nameController,
                hintText: 'Business name',
                prefixIcon: const Icon(Icons.storefront_outlined),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: phoneController,
                hintText: 'Business phone',
                prefixIcon: const Icon(Icons.call_outlined),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: addressController,
                hintText: 'Business address',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await settingsCubit.setBusinessProfile(
                      businessName: nameController.text.trim().isEmpty
                          ? 'RO Service Manager'
                          : nameController.text.trim(),
                      businessPhone: phoneController.text.trim(),
                      businessAddress: addressController.text.trim(),
                    );
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Business profile updated.'),
                      ),
                    );
                  },
                  child: const Text('Save Business Profile'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;
    final appSettings = context.watch<SettingsCubit>().state;
    final previewUser = _currentUser.copyWith(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      role: _roleController.text,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: foreground,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        foregroundColor: foreground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: foreground),
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
                color: cardColor,
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
                        const SemiBoldTextView(
                          text: 'Local Profile',
                          fontSize: 15,
                        ),
                        const SizedBox(height: 4),
                        SubRegularText(
                          text: 'Member ID: ${_currentUser.id}',
                          fontSize: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SemiBoldTextView(text: 'Preferences', fontSize: 18),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SemiBoldTextView(text: 'Theme Mode', fontSize: 15),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ThemeModeChip(
                        label: 'System',
                        icon: Icons.brightness_auto_outlined,
                        isSelected: appSettings.themeMode == ThemeMode.system,
                        onTap: () {
                          context.read<SettingsCubit>().setThemeMode(
                            ThemeMode.system,
                          );
                        },
                      ),
                      _ThemeModeChip(
                        label: 'Light',
                        icon: Icons.light_mode_outlined,
                        isSelected: appSettings.themeMode == ThemeMode.light,
                        onTap: () {
                          context.read<SettingsCubit>().setThemeMode(
                            ThemeMode.light,
                          );
                        },
                      ),
                      _ThemeModeChip(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                        isSelected: appSettings.themeMode == ThemeMode.dark,
                        onTap: () {
                          context.read<SettingsCubit>().setThemeMode(
                            ThemeMode.dark,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SettingsSwitchTile(
                    title: 'Service alerts',
                    subtitle:
                        'Keep operational notifications active for low stock and new service requests.',
                    value: appSettings.notificationsEnabled,
                    icon: Icons.notifications_active_outlined,
                    onChanged: (value) {
                      context.read<SettingsCubit>().setNotificationsEnabled(
                        value,
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _SettingsSwitchTile(
                    title: 'Auto backup reminder',
                    subtitle:
                        'Keep backup-first actions enabled when you clear business data.',
                    value: appSettings.autoBackupEnabled,
                    icon: Icons.backup_outlined,
                    onChanged: (value) {
                      context.read<SettingsCubit>().setAutoBackupEnabled(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportBackup,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download Database'),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loadDemoData,
                      icon: const Icon(Icons.auto_awesome_motion_outlined),
                      label: const Text('Load Demo Data'),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearAllData,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Clear All Data'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: BorderSide(color: Colors.red.shade100),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _restoreBackup,
                      icon: const Icon(Icons.restore_page_outlined),
                      label: const Text('Restore Latest Local Backup'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  const SemiBoldTextView(
                    text: 'Workspace Settings',
                    fontSize: 15,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storefront_outlined),
                    title: const Text('Business Profile'),
                    subtitle: Text(
                      appSettings.businessPhone.trim().isEmpty
                          ? appSettings.businessName
                          : '${appSettings.businessName} • ${appSettings.businessPhone}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _showBusinessProfileSheet,
                  ),
                  const Divider(height: 20),
                  const LabelText(text: 'Language'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ThemeModeChip(
                        label: 'English',
                        icon: Icons.language_outlined,
                        isSelected: appSettings.languageCode == 'en',
                        onTap: () {
                          context.read<SettingsCubit>().setLanguageCode('en');
                        },
                      ),
                      _ThemeModeChip(
                        label: 'Hindi',
                        icon: Icons.translate_outlined,
                        isSelected: appSettings.languageCode == 'hi',
                        onTap: () {
                          context.read<SettingsCubit>().setLanguageCode('hi');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const LabelText(text: 'Date Format'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ThemeModeChip(
                        label: 'dd MMM yyyy',
                        icon: Icons.event_outlined,
                        isSelected: appSettings.dateFormat == 'dd MMM yyyy',
                        onTap: () {
                          context.read<SettingsCubit>().setDateFormat(
                            'dd MMM yyyy',
                          );
                        },
                      ),
                      _ThemeModeChip(
                        label: 'dd/MM/yyyy',
                        icon: Icons.calendar_month_outlined,
                        isSelected: appSettings.dateFormat == 'dd/MM/yyyy',
                        onTap: () {
                          context.read<SettingsCubit>().setDateFormat(
                            'dd/MM/yyyy',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const LabelText(text: 'Backup Policy'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ThemeModeChip(
                        label: 'Manual',
                        icon: Icons.backup_outlined,
                        isSelected: appSettings.backupPolicy == 'Manual',
                        onTap: () {
                          context.read<SettingsCubit>().setBackupPolicy(
                            'Manual',
                          );
                        },
                      ),
                      _ThemeModeChip(
                        label: 'Manual + Before Clear',
                        icon: Icons.security_outlined,
                        isSelected:
                            appSettings.backupPolicy == 'Manual + Before Clear',
                        onTap: () {
                          context.read<SettingsCubit>().setBackupPolicy(
                            'Manual + Before Clear',
                          );
                        },
                      ),
                    ],
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
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: Color(0xFF007FFF),
                  ),
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
                color: cardColor,
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
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: cardColor,
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
      openRequests: requests
          .where((request) => request.status != 'completed')
          .length,
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
        color: Theme.of(context).cardColor,
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

class _ThemeModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => onTap(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
      selectedColor: const Color(0xFFDBEAFE),
      side: BorderSide(
        color: isSelected ? const Color(0xFF007FFF) : const Color(0xFFE2E8F0),
      ),
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF007FFF) : const Color(0xFF475569),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF007FFF).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF007FFF), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SemiBoldTextView(text: title, fontSize: 15),
              const SizedBox(height: 4),
              SubRegularText(text: subtitle, fontSize: 13),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
