import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialProfile,
    this.tenantId,
    this.isOwner = false,
    this.initialBusinessName,
    this.initialLocation,
  });

  final StaffMember initialProfile;
  final String? initialBusinessName;
  final String? initialLocation;

  /// The tenant ID — used to call the tenant-service update endpoint for owners.
  final String? tenantId;

  /// When true, profile changes are saved to the tenant-service (owner record).
  /// When false, changes go to user-service (staff record).
  final bool isOwner;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _departmentController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _locationController;

  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.displayName);
    _phoneController = TextEditingController(text: widget.initialProfile.mobileNumber);
    _departmentController = TextEditingController(text: widget.initialProfile.department);
    _businessNameController = TextEditingController(text: widget.initialBusinessName ?? '');
    _locationController = TextEditingController(text: widget.initialLocation ?? widget.initialProfile.department ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _businessNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      await AppAlertDialog.show(
        context,
        title: 'Required information',
        message: 'Please fix the highlighted fields before saving.',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final session = AuthenticationDependencies.controller.session;
      if (session == null) throw Exception('Not authenticated');

      final api = StaffApiService();
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final department = _departmentController.text.trim();
      final businessName = _businessNameController.text.trim();
      final location = _locationController.text.trim();

      if (widget.isOwner && widget.tenantId != null) {
        // ── Owner: update via tenant-service ─────────────────────────────────
        await api.updateTenantProfile(
          tenantId: widget.tenantId!,
          ownerName: name.isNotEmpty ? name : null,
          mobileNumber: phone.isNotEmpty ? phone : null,
          businessName: businessName.isNotEmpty ? businessName : null,
          location: location.isNotEmpty ? location : null,
        );
      } else {
        // ── Staff: update via user-service ───────────────────────────────────
        final userId = widget.initialProfile.id.isNotEmpty
            ? widget.initialProfile.id
            : session.ownerUserId;
        if (userId == null || userId.isEmpty) throw Exception('User ID not available');

        await api.updateStaff(
          userId: userId,
          name: name.isNotEmpty ? name : null,
          mobileNumber: phone.isNotEmpty ? phone : null,
          department: department.isNotEmpty ? department : null,
        );
      }

      if (!mounted) return;
      context.pop(true); // Return true to trigger profile reload
    } catch (e) {
      if (!mounted) return;
      final String message = e is StaffApiException ? e.userMessage : e.toString();
      setState(() => _error = message);
      await AppAlertDialog.show(
        context,
        title: AppAlertDialog.titleFor(message),
        message: message,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.error.withOpacity(0.5)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Name is required' : null,
              enabled: !_isSaving,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
              ),
              enabled: !_isSaving,
            ),
            if (widget.isOwner) ...[
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  hintText: 'Enter your business name',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Business Name is required' : null,
                enabled: !_isSaving,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter your location (City/Branch)',
                ),
                enabled: !_isSaving,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter your location',
                ),
                enabled: !_isSaving,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.surface),
                    )
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
