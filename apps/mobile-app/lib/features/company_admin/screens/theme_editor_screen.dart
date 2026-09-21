import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/admin_session_gate.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

Color? _tryParseHex(String hex) {
  final String cleaned = hex.trim();
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(cleaned)) return null;
  return Color(int.parse('FF${cleaned.substring(1)}', radix: 16));
}

class ThemeEditorScreen extends StatefulWidget {
  const ThemeEditorScreen({required this.tenantId, super.key, this.apiService});

  final String tenantId;
  final CompanyAdminApiService? apiService;

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late final CompanyAdminApiService _apiService;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _isCustomized = false;

  final TextEditingController _primaryController = TextEditingController();
  final TextEditingController _secondaryController = TextEditingController();
  final TextEditingController _accentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();
  final TextEditingController _bannerUrlController = TextEditingController();
  bool _darkThemeEnabled = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CompanyAdminDependencies.apiService;
    // Live preview: rebuild the swatches as the admin edits any hex field.
    for (final TextEditingController controller in <TextEditingController>[
      _primaryController,
      _secondaryController,
      _accentController,
    ]) {
      controller.addListener(_onColorFieldChanged);
    }
    _load();
  }

  void _onColorFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _accentController.dispose();
    _titleController.dispose();
    _logoUrlController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final EffectiveTenantThemeModel theme = await _apiService.getTheme(widget.tenantId);
      if (!mounted) return;
      setState(() {
        _isCustomized = theme.isCustomized;
        _primaryController.text = theme.primaryColorHex;
        _secondaryController.text = theme.secondaryColorHex;
        _accentController.text = theme.accentColorHex;
        _titleController.text = theme.customAppTitle;
        _logoUrlController.text = theme.logoUrl ?? '';
        _bannerUrlController.text = theme.bannerUrl ?? '';
        _darkThemeEnabled = theme.darkThemeEnabled;
        _isLoading = false;
      });
    } on CompanyAdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _apiService.setTheme(
        widget.tenantId,
        primaryColorHex: _primaryController.text.trim(),
        secondaryColorHex: _secondaryController.text.trim(),
        accentColorHex: _accentController.text.trim(),
        darkThemeEnabled: _darkThemeEnabled,
        customAppTitle: _titleController.text.trim(),
        logoUrl: _logoUrlController.text.trim().isEmpty
            ? null
            : _logoUrlController.text.trim(),
        bannerUrl: _bannerUrlController.text.trim().isEmpty
            ? null
            : _bannerUrlController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isCustomized = true;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Theme saved.')));
    } on CompanyAdminApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminSessionGate(
      child: Scaffold(
        appBar: AppBar(title: const Text('Theme & Branding')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppStatusBadge(
            label: _isCustomized ? 'Customized' : 'Using app defaults',
            tone: _isCustomized ? AppBadgeTone.info : AppBadgeTone.neutral,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ColorPreviewRow(
            primary: _tryParseHex(_primaryController.text),
            secondary: _tryParseHex(_secondaryController.text),
            accent: _tryParseHex(_accentController.text),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            controller: _primaryController,
            label: 'Primary Color (hex)',
            hintText: '#2563EB',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _secondaryController,
            label: 'Secondary Color (hex)',
            hintText: '#7C3AED',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _accentController,
            label: 'Accent Color (hex)',
            hintText: '#0EA5E9',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _titleController,
            label: 'App Title',
            hintText: 'Nexoraa CleanSoft',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _logoUrlController,
            label: 'Logo URL (optional)',
            hintText: 'https://...',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _bannerUrlController,
            label: 'Banner URL (optional)',
            hintText: 'https://...',
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark theme enabled'),
            value: _darkThemeEnabled,
            onChanged: (bool value) => setState(() => _darkThemeEnabled = value),
          ),
          const SizedBox(height: AppSpacing.xl),
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PrimaryButton(
                label: _isSaving ? '' : 'Save Theme',
                onPressed: _isSaving ? null : _save,
              ),
              if (_isSaving)
                const SizedBox.square(
                  dimension: AppIconSizes.xl,
                  child: CircularProgressIndicator(
                    color: AppColors.surface,
                    strokeWidth: AppBorderWidths.medium,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorPreviewRow extends StatelessWidget {
  const _ColorPreviewRow({this.primary, this.secondary, this.accent});

  final Color? primary;
  final Color? secondary;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _Swatch(color: primary, label: 'Primary'),
        const SizedBox(width: AppSpacing.md),
        _Swatch(color: secondary, label: 'Secondary'),
        const SizedBox(width: AppSpacing.md),
        _Swatch(color: accent, label: 'Accent'),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.label});

  final Color? color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: color ?? AppColors.surfaceMuted,
              borderRadius: AppRadius.cardRadius,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: const SizedBox(height: AppSpacing.xxl, width: double.infinity),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
