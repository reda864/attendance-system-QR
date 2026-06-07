import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../l10n/app_strings.dart';
import '../constants/app_theme.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _codeMassarController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _codeMassarFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String? _qrToken;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  void _initializeForm() {
    final attendanceProvider = context.read<AttendanceProvider>();
    final authProvider = context.read<AuthProvider>();

    _qrToken = attendanceProvider.scannedQrToken;

    // Auto-fill from logged-in student profile (official records)
    final user = authProvider.user;
    if (user?.studentProfile != null) {
      final profile = user!.studentProfile!;
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
    } else if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
    }

    // Also check provider prefill
    if (_firstNameController.text.isEmpty &&
        attendanceProvider.prefillFirstName.isNotEmpty) {
      _firstNameController.text = attendanceProvider.prefillFirstName;
    }
    if (_lastNameController.text.isEmpty &&
        attendanceProvider.prefillLastName.isNotEmpty) {
      _lastNameController.text = attendanceProvider.prefillLastName;
    }
    if (attendanceProvider.prefillCodeMassar.isNotEmpty) {
      _codeMassarController.text = attendanceProvider.prefillCodeMassar;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _codeMassarController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _codeMassarFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_submitted) return;

    final token = _qrToken;
    if (token == null || token.isEmpty) {
      _showSnackBar('No QR token found. Please scan again.', isError: true);
      return;
    }

    setState(() => _submitted = true);

    final attendanceProvider = context.read<AttendanceProvider>();
    final result = await attendanceProvider.validateAttendance(
      qrToken: token,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      codeMassar: _codeMassarController.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeSuccess);
    } else {
      Navigator.of(context).pushReplacementNamed(
        AppConstants.routeError,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? AppTheme.errorColor : AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.validateAttendance),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            context.read<AttendanceProvider>().clearScannedToken();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // ── QR token indicator ──────────────────────────────────
                  _QrTokenBadge(token: _qrToken),

                  const SizedBox(height: 24),

                  // ── Instruction card ────────────────────────────────────
                  _InstructionCard(),

                  const SizedBox(height: 24),

                  // ── Form card ───────────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Student Information',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Verify your details match the institution records.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 13),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(),
                            ),

                            // ── First Name ──────────────────────────────
                            CustomTextField(
                              controller: _firstNameController,
                              focusNode: _firstNameFocus,
                              label: AppStrings.firstName,
                              hint: 'e.g. Mohammed',
                              prefixIcon: Icons.badge_outlined,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateFirstName,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_lastNameFocus);
                              },
                            ),

                            const SizedBox(height: 16),

                            // ── Last Name ───────────────────────────────
                            CustomTextField(
                              controller: _lastNameController,
                              focusNode: _lastNameFocus,
                              label: AppStrings.lastName,
                              hint: 'e.g. Alaoui',
                              prefixIcon: Icons.badge_outlined,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateLastName,
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_codeMassarFocus);
                              },
                            ),

                            const SizedBox(height: 16),

                            // ── Code Massar ─────────────────────────────
                            CustomTextField(
                              controller: _codeMassarController,
                              focusNode: _codeMassarFocus,
                              label: AppStrings.codeMassar,
                              hint: 'e.g. M123456789',
                              prefixIcon: Icons.numbers_rounded,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              validator: Validators.validateCodeMassar,
                              helperText:
                                  'Your official student identification code',
                              onFieldSubmitted: (_) => _handleSubmit(),
                            ),

                            const SizedBox(height: 28),

                            // ── Submit button ────────────────────────────
                            Consumer<AttendanceProvider>(
                              builder: (context, provider, _) {
                                return LoadingButton(
                                  onPressed: _handleSubmit,
                                  isLoading: provider.isLoading,
                                  label: AppStrings.submitAttendance,
                                  icon: Icons.how_to_reg_rounded,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Re-scan option ──────────────────────────────────────
                  _RescanButton(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── QR Token Badge ───────────────────────────────────────────────────────────

class _QrTokenBadge extends StatelessWidget {
  final String? token;

  const _QrTokenBadge({this.token});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primary.withOpacity(0.15)
            : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QR Code Detected',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  token != null
                      ? '${token!.substring(0, 8)}…${token!.substring(token!.length - 4)}'
                      : 'No token',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 12, color: AppTheme.successColor),
                SizedBox(width: 4),
                Text(
                  'Valid',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Instruction Card ─────────────────────────────────────────────────────────

class _InstructionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppTheme.warningColor.withOpacity(0.8),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter your details exactly as registered in the system. '
              'Name verification is required to prevent fraud.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Re-scan Button ───────────────────────────────────────────────────────────

class _RescanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        context.read<AttendanceProvider>().clearScannedToken();
        Navigator.of(context).pushReplacementNamed(AppConstants.routeScanner);
      },
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
      label: const Text('Scan a different QR code'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primary.withOpacity(0.7),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
