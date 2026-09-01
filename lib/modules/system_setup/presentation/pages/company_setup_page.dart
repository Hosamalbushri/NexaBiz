import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/presentation/providers/dashboard_services_provider.dart';
import '../../../../app/settings/company/company_profile.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../domain/services/company_setup_service.dart';
import '../../presentation/providers/system_setup_providers.dart';

/// Provider for [CompanySetupService].
final companySetupServiceProvider = Provider<CompanySetupService>((ref) {
  return CompanySetupService(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    initRepository: ref.watch(companyInitializationRepositoryProvider),
  );
});

/// Post-Authentication Company Setup Page.
class CompanySetupPage extends ConsumerStatefulWidget {
  const CompanySetupPage({super.key});

  @override
  ConsumerState<CompanySetupPage> createState() => _CompanySetupPageState();
}

class _CompanySetupPageState extends ConsumerState<CompanySetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final settings = ref.read(settingsRepositoryProvider);
    final profile = await settings.loadCompanyProfile();
    if (mounted) {
      setState(() {
        _nameController.text = profile.name;
        _legalNameController.text = profile.legalName ?? '';
        _taxNumberController.text = profile.taxNumber ?? '';
        _commercialRegisterController.text = profile.commercialRegister ?? '';
        _phoneController.text = profile.phone ?? '';
        _emailController.text = profile.email ?? '';
        _cityController.text = profile.city ?? '';
        _countryController.text = profile.country ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _taxNumberController.dispose();
    _commercialRegisterController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authStateProvider);
      final service = ref.read(companySetupServiceProvider);

      final draft = CompanyProfile(
        name: _nameController.text.trim(),
        legalName: _legalNameController.text.trim().isEmpty
            ? null
            : _legalNameController.text.trim(),
        taxNumber: _taxNumberController.text.trim().isEmpty
            ? null
            : _taxNumberController.text.trim(),
        commercialRegister: _commercialRegisterController.text.trim().isEmpty
            ? null
            : _commercialRegisterController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        country: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
      );

      final userPerms = auth.session?.permissions.toList();

      await service.setupCompany(
        session: auth.session,
        profile: draft,
        userPermissions: userPerms,
        isSuperAdmin: auth.session?.user.isSuperAdmin ?? false,
      );


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ بيانات الشركة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('إعداد الشركة')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'مطلوب تسجيل الدخول',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('لا يمكنك الوصول لإعداد الشركة دون جلسة نشطة.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعداد بيانات الشركة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (_errorMessage != null) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(_errorMessage!),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشركة *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'يرجى إدخال اسم الشركة' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _legalNameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم القانوني / التجاري',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxNumberController,
                decoration: const InputDecoration(
                  labelText: 'الرقم الضريبي (VAT)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commercialRegisterController,
                decoration: const InputDecoration(
                  labelText: 'السجل التجاري',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'المدينة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        labelText: 'الدولة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCompany,
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('حفظ واستمرار'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
