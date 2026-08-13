import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/customers/widgets/customer_widgets.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({
    required this.controller,
    this.customer,
    super.key,
  });
  final CustomerController controller;
  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late CustomerType _type;
  late DateTime _joiningDate;
  bool _saving = false;

  bool get _editing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final Customer? customer = widget.customer;
    _name = TextEditingController(text: customer?.name);
    _mobile = TextEditingController(text: customer?.mobile);
    _email = TextEditingController(text: customer?.email);
    _address = TextEditingController(text: customer?.address);
    _type = customer?.customerType ?? CustomerType.regular;
    _joiningDate = customer?.joiningDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _joiningDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _joiningDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final CustomerDraft draft = CustomerDraft(
      name: _name.text,
      mobile: _mobile.text,
      email: _email.text,
      address: _address.text,
      customerType: _type,
      joiningDate: _joiningDate,
    );
    try {
      if (_editing) {
        await widget.controller.update(widget.customer!.id, draft);
      } else {
        await widget.controller.create(draft);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on CustomerApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(AppIcons.arrowBack),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_editing ? 'Edit Customer' : 'Add Customer'),
          Text(
            _editing
                ? 'Update customer information'
                : 'Fill in the details below',
            style: AppTextStyles.label,
          ),
        ],
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: <Widget>[
          CustomerSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel('CUSTOMER INFORMATION'),
                const SizedBox(height: AppSpacing.xl),
                _field(
                  controller: _name,
                  label: 'Customer Name *',
                  hint: 'Enter customer name',
                  icon: AppIcons.user,
                  validator: (String? value) =>
                      value == null || value.trim().isEmpty
                      ? 'Customer name is required'
                      : null,
                ),
                _field(
                  controller: _mobile,
                  label: _type == CustomerType.walkIn
                      ? 'Mobile Number'
                      : 'Mobile Number *',
                  hint: 'Enter mobile number',
                  icon: AppIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: _validateMobile,
                ),
                _field(
                  controller: _email,
                  label: 'Email',
                  hint: 'Enter email address',
                  icon: AppIcons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(value.trim())
                        ? null
                        : 'Enter a valid email address';
                  },
                ),
                _field(
                  controller: _address,
                  label: 'Address',
                  hint: 'Enter customer address',
                  icon: AppIcons.location,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomerSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel('CUSTOMER TYPE'),
                const SizedBox(height: AppSpacing.xl),
                Text('Customer Type *', style: AppTextStyles.inputLabel),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.15,
                  children: CustomerType.values
                      .map(_typeCard)
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomerSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _sectionLabel('MEMBERSHIP'),
                const SizedBox(height: AppSpacing.xl),
                Text('Joining Date', style: AppTextStyles.inputLabel),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(formatDate(_joiningDate)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.displayLarge),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: AppBorders.topBar,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SecondaryButton(
                label: 'Cancel',
                onPressed: _saving ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: _saving
                    ? 'Saving...'
                    : _editing
                    ? 'Save Changes'
                    : 'Create Customer',
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String? _validateMobile(String? value) {
    final String mobile = value?.trim() ?? '';
    if (_type != CustomerType.walkIn && mobile.isEmpty)
      return 'Mobile number is required';
    if (mobile.isNotEmpty && !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(mobile)) {
      return 'Enter 7-15 digits, optionally starting with +';
    }
    return null;
  }

  Widget _sectionLabel(String value) => Text(
    value,
    style: AppTextStyles.label.copyWith(
      color: AppColors.textSubtle,
      letterSpacing: 1,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        ),
      ],
    ),
  );

  Widget _typeCard(CustomerType type) {
    final bool selected = type == _type;
    final String note = switch (type) {
      CustomerType.regular => 'Returning customer',
      CustomerType.walkIn => 'One-time visit',
      CustomerType.corporate => 'Business account',
      CustomerType.vip => 'Priority treatment',
    };
    return InkWell(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: AppRadius.inputRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              type.apiValue,
              style: AppTextStyles.captionBold.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              note,
              style: AppTextStyles.label.copyWith(
                color: selected ? AppColors.primary : AppColors.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
