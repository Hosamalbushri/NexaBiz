import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../domain/services/first_run_setup_coordinator.dart';
import '../providers/system_setup_providers.dart';

class FirstRunSetupWizardPage extends ConsumerStatefulWidget {
  const FirstRunSetupWizardPage({super.key});

  static const routeName = '/setup/first-run';

  @override
  ConsumerState<FirstRunSetupWizardPage> createState() =>
      _FirstRunSetupWizardPageState();
}

class _FirstRunSetupWizardPageState
    extends ConsumerState<FirstRunSetupWizardPage> {
  int _currentStep = 0;
  bool _isCommitting = false;
  String? _errorMessage;

  // Form values
  String _selectedLanguage = 'ar';

  final _companyNameController = TextEditingController();
  final _companyCodeController = TextEditingController();

  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminPasswordConfirmController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyCodeController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminPasswordConfirmController.dispose();
    super.dispose();
  }

  bool get _isArabic => _selectedLanguage == 'ar';

  void _nextStep() {
    setState(() {
      _errorMessage = null;
    });

    if (_currentStep == 0) {
      // Step 0: Language selected -> Go to Company Name
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Step 1: Company Name Validation
      final companyName = _companyNameController.text.trim();
      if (companyName.isEmpty) {
        setState(() => _errorMessage = _isArabic
            ? 'يرجى إدخال اسم الشركة'
            : 'Please enter company name');
        return;
      }
      // If company code is empty, auto-generate code from name or set default
      if (_companyCodeController.text.trim().isEmpty) {
        _companyCodeController.text = companyName
            .replaceAll(RegExp(r'\s+'), '_')
            .toUpperCase();
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Step 2: Admin Account Validation
      if (_adminNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = _isArabic
            ? 'يرجى إدخال اسم المدير'
            : 'Please enter admin name');
        return;
      }
      final email = _adminEmailController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _errorMessage = _isArabic
            ? 'يرجى إدخال بريد إلكتروني صحيح'
            : 'Please enter a valid email address');
        return;
      }
      final pwd = _adminPasswordController.text.trim();
      if (pwd.length < 8) {
        setState(() => _errorMessage = _isArabic
            ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
            : 'Password must be at least 8 characters long');
        return;
      }
      if (pwd != _adminPasswordConfirmController.text.trim()) {
        setState(() => _errorMessage = _isArabic
            ? 'كلمتا المرور غير متطابقتين'
            : 'Passwords do not match');
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _prevStep() {
    if (_currentStep > 0 && !_isCommitting) {
      setState(() {
        _errorMessage = null;
        _currentStep -= 1;
      });
    }
  }

  Future<void> _commitSetup() async {
    setState(() {
      _isCommitting = true;
      _errorMessage = null;
    });

    final payload = FirstRunSetupPayload(
      language: _selectedLanguage,
      companyName: _companyNameController.text.trim(),
      companyCode: _companyCodeController.text.trim(),
      adminName: _adminNameController.text.trim(),
      adminEmail: _adminEmailController.text.trim(),
      adminPassword: _adminPasswordController.text.trim(),
    );

    try {
      final coordinator = ref.read(firstRunSetupCoordinatorProvider);
      await coordinator.commitFirstRunSetup(payload);

      if (!mounted) return;
      ref.read(firstRunCompletedProvider.notifier).markCompleted();
      ref.read(systemSetupReadyProvider.notifier).markReady();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isArabic
                ? 'تم إنشاء سياق التطبيق وحساب المدير بنجاح'
                : 'Application context & admin account created successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      if (e is FirstRunAlreadyCompletedException) {
        ref.read(firstRunCompletedProvider.notifier).markCompleted();
        ref.read(systemSetupReadyProvider.notifier).markReady();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isArabic
                  ? 'التهيئة الأولى مكتملة بالفعل، يتم الانتقال إلى تسجيل الدخول'
                  : 'First-run setup already completed. Redirecting to login.',
            ),
            backgroundColor: Colors.blue,
          ),
        );
        context.go('/login');
        return;
      }
      setState(() {
        _isCommitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = _isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isArabic
                ? 'تهيئة التطبيق للتشغيل الأول'
                : 'First Run Application Setup',
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeaderProgressBar(),
              if (_errorMessage != null) _buildErrorMessageBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildCurrentStepContent(),
                ),
              ),
              _buildBottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderProgressBar() {
    final steps = _isArabic
        ? ['اللغة', 'اسم الشركة', 'حساب المدير', 'الاعتماد']
        : ['Language', 'Company', 'Admin', 'Commit'];

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(steps.length, (index) {
          final isCurrent = index == _currentStep;
          final isDone = index < _currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDone
                    ? Colors.green
                    : isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildErrorMessageBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStepLanguage();
      case 1:
        return _buildStepCompanyName();
      case 2:
        return _buildStepAdminAccount();
      case 3:
        return _buildStepReviewAndCommit();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepLanguage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'الخطوة 1: لغة التطبيق' : 'Step 1: Application Language',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _isArabic
              ? 'اختر اللغة المفضلة لاستخدام التطبيق.'
              : 'Choose your preferred language.',
        ),
        const SizedBox(height: 24),
        RadioListTile<String>(
          title: const Text('العربية (Arabic)'),
          value: 'ar',
          groupValue: _selectedLanguage,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedLanguage = val);
              ref.read(settingsRepositoryProvider).saveLocale(Locale(val));
            }
          },
        ),
        RadioListTile<String>(
          title: const Text('English (الإنجليزية)'),
          value: 'en',
          groupValue: _selectedLanguage,
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedLanguage = val);
              ref.read(settingsRepositoryProvider).saveLocale(Locale(val));
            }
          },
        ),
      ],
    );
  }

  Widget _buildStepCompanyName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'الخطوة 2: اسم الشركة' : 'Step 2: Company Name',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _isArabic
              ? 'يرجى إدخال اسم الشركة الخاص بك لاستخدامه في النظام والفواتير.'
              : 'Please enter your company name to be used in the system and invoices.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _companyNameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _isArabic ? 'اسم الشركة *' : 'Company Name *',
            hintText: _isArabic ? 'مثال: شركة الأمل للتجارة' : 'e.g. Acme Trading Co.',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.business_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildStepAdminAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isArabic ? 'الخطوة 3: إنشاء حساب المدير' : 'Step 3: Create Admin Account',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          _isArabic
              ? 'أدخل بيانات حساب المدير الرئيسي لاستخدامها في تسجيل الدخول.'
              : 'Enter main admin credentials for logging into the application.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminNameController,
          decoration: InputDecoration(
            labelText: _isArabic ? 'اسم المدير *' : 'Admin Name *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _isArabic ? 'البريد الإلكتروني *' : 'Admin Email *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _isArabic ? 'كلمة المرور * (8 أحرف على الأقل)' : 'Password * (min 8 chars)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _adminPasswordConfirmController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _isArabic ? 'تأكيد كلمة المرور *' : 'Confirm Password *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_reset_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildStepReviewAndCommit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.verified_user, size: 64, color: Colors.blue),
        const SizedBox(height: 16),
        Text(
          _isArabic ? 'اعتماد سياق التطبيق' : 'Commit Application Setup',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(_isArabic ? 'اللغة' : 'Language'),
                  subtitle: Text(_selectedLanguage == 'ar' ? 'العربية' : 'English'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: Text(_isArabic ? 'اسم الشركة' : 'Company Name'),
                  subtitle: Text(_companyNameController.text.trim()),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(_isArabic ? 'اسم المدير' : 'Admin Name'),
                  subtitle: Text(_adminNameController.text.trim()),
                ),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(_isArabic ? 'البريد الإلكتروني' : 'Admin Email'),
                  subtitle: Text(_adminEmailController.text.trim()),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_isCommitting)
          const CircularProgressIndicator()
        else
          ElevatedButton.icon(
            onPressed: _commitSetup,
            icon: const Icon(Icons.check_circle),
            label: Text(
              _isArabic ? 'تأكيد واعتماد' : 'Confirm & Commit',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0 && _currentStep < 3)
            OutlinedButton(
              onPressed: _prevStep,
              child: Text(_isArabic ? 'السابق' : 'Back'),
            )
          else
            const SizedBox.shrink(),
          if (_currentStep < 3)
            ElevatedButton(
              onPressed: _nextStep,
              child: Text(_isArabic ? 'التالي' : 'Next'),
            ),
        ],
      ),
    );
  }
}
