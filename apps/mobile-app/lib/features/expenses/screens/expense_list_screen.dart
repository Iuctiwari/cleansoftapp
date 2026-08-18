import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/expenses/controllers/expense_controller.dart';
import 'package:nexoraa_mobile/features/expenses/expense_dependencies.dart';
import 'package:nexoraa_mobile/features/expenses/models/expense.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late final ExpenseController _controller;
  bool _showingAddScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = ExpenseDependencies.createController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        if (_showingAddScreen) {
          return _AddExpenseScreen(
            categories: _controller.categories,
            paymentMethods: _controller.paymentMethods,
            onBack: () => setState(() => _showingAddScreen = false),
            onSubmit: _addExpense,
          );
        }
        return Material(
          color: AppColors.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 375),
              child: Column(
                children: <Widget>[
                  _ExpenseHeader(
                    onAdd: () => setState(() => _showingAddScreen = true),
                    onBack: widget.onBack,
                  ),
                  Expanded(
                    child: _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomScrollView(
                            physics: const ClampingScrollPhysics(),
                            slivers: <Widget>[
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  12,
                                  24,
                                  0,
                                ),
                                sliver: SliverToBoxAdapter(
                                  child: _ExpenseSummary(
                                    categoryCount: _controller.categoryCount,
                                    total: _controller.total,
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: _CategoryFilters(
                                  controller: _controller,
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  24,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: _controller.expenses.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                        final Expense expense =
                                            _controller.expenses[index];
                                        final ExpenseCategory category =
                                            _controller.categories.firstWhere(
                                              (ExpenseCategory item) =>
                                                  item.id ==
                                                  expense.expenseCategoryId,
                                            );
                                        return _ExpenseCard(
                                          category: category,
                                          expense: expense,
                                        );
                                      },
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addExpense(CreateExpenseRequest request) async {
    await _controller.addExpense(request);
    if (mounted) setState(() => _showingAddScreen = false);
  }
}

class _AddExpenseScreen extends StatefulWidget {
  const _AddExpenseScreen({
    required this.categories,
    required this.onBack,
    required this.onSubmit,
    required this.paymentMethods,
  });

  final List<ExpenseCategory> categories;
  final VoidCallback onBack;
  final ValueChanged<CreateExpenseRequest> onSubmit;
  final List<ExpensePaymentOption> paymentMethods;

  @override
  State<_AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<_AddExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _vendor = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  late String _categoryId;
  late ExpensePaymentMethod _paymentMethod;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categories.first.id;
    _paymentMethod = widget.paymentMethods.first.method;
  }

  @override
  void dispose() {
    _description.dispose();
    _vendor.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: Column(
            children: <Widget>[
              _AddExpenseHeader(onBack: widget.onBack),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Expense details',
                          style: AppTextStyles.headingSmall.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Record a new business expense',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _description,
                          decoration: _inputDecoration(
                            labelText: 'Expense name',
                            hintText: 'e.g. Electricity Bill, Detergent',
                            prefixIcon: AppIcons.receipt,
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration(
                            labelText: 'Amount',
                            hintText: '0.00',
                            prefixIcon: AppIcons.wallet,
                          ),
                          validator: (String? value) {
                            final double? amount = double.tryParse(
                              value?.trim() ?? '',
                            );
                            return amount == null || amount <= 0
                                ? 'Enter a valid amount'
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final ExpenseCategory selectedCategory = widget.categories
                                .firstWhere(
                                  (ExpenseCategory item) => item.id == _categoryId,
                                  orElse: () => widget.categories.first,
                                );
                            return PopupMenuButton<String>(
                              tooltip: '',
                              offset: const Offset(0, 52),
                              elevation: 6,
                              shadowColor: const Color(0x1A000000),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.inputRadius,
                                side: BorderSide(color: AppColors.border),
                              ),
                              color: AppColors.surface,
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                                maxWidth: constraints.maxWidth,
                              ),
                              onSelected: (String value) {
                                setState(() => _categoryId = value);
                              },
                              itemBuilder: (BuildContext context) => widget.categories
                                  .map(
                                    (ExpenseCategory category) {
                                      final bool isSelected = category.id == _categoryId;
                                      return PopupMenuItem<String>(
                                        value: category.id,
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.surfaceMuted
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              Text(
                                                category.symbol,
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  category.name,
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  AppIcons.brandCheck,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  .toList(),
                              child: InputDecorator(
                                decoration: _inputDecoration(
                                  labelText: 'Category',
                                  prefixIcon: AppIcons.tag,
                                ).copyWith(
                                  suffixIcon: const Icon(
                                    AppIcons.chevronDown,
                                    color: AppColors.textSubtle,
                                    size: 20,
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      selectedCategory.symbol,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedCategory.name,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final ExpensePaymentOption selectedPayment = widget.paymentMethods
                                .firstWhere(
                                  (ExpensePaymentOption item) => item.method == _paymentMethod,
                                  orElse: () => widget.paymentMethods.first,
                                );
                            final String selectedEmoji = switch (selectedPayment.method) {
                              ExpensePaymentMethod.cash => '💵',
                              ExpensePaymentMethod.upi => '📱',
                              ExpensePaymentMethod.card => '💳',
                              ExpensePaymentMethod.bankTransfer => '🏦',
                            };
                            return PopupMenuButton<ExpensePaymentMethod>(
                              tooltip: '',
                              offset: const Offset(0, 52),
                              elevation: 6,
                              shadowColor: const Color(0x1A000000),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.inputRadius,
                                side: BorderSide(color: AppColors.border),
                              ),
                              color: AppColors.surface,
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                                maxWidth: constraints.maxWidth,
                              ),
                              onSelected: (ExpensePaymentMethod value) {
                                setState(() => _paymentMethod = value);
                              },
                              itemBuilder: (BuildContext context) => widget.paymentMethods
                                  .map(
                                    (ExpensePaymentOption option) {
                                      final bool isSelected = option.method == _paymentMethod;
                                      final String emoji = switch (option.method) {
                                        ExpensePaymentMethod.cash => '💵',
                                        ExpensePaymentMethod.upi => '📱',
                                        ExpensePaymentMethod.card => '💳',
                                        ExpensePaymentMethod.bankTransfer => '🏦',
                                      };
                                      return PopupMenuItem<ExpensePaymentMethod>(
                                        value: option.method,
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.surfaceMuted
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              Text(
                                                emoji,
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  option.label,
                                                  style: TextStyle(
                                                    color: AppColors.textPrimary,
                                                    fontSize: 14,
                                                    fontWeight: isSelected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  AppIcons.brandCheck,
                                                  size: 16,
                                                  color: AppColors.primary,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  .toList(),
                              child: InputDecorator(
                                decoration: _inputDecoration(
                                  labelText: 'Payment method',
                                  prefixIcon: AppIcons.payment,
                                ).copyWith(
                                  suffixIcon: const Icon(
                                    AppIcons.chevronDown,
                                    color: AppColors.textSubtle,
                                    size: 20,
                                  ),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      selectedEmoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        selectedPayment.label,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _vendor,
                          decoration: _inputDecoration(
                            labelText: 'Vendor',
                            hintText: 'e.g. Power Corp, CleanSupply Co',
                            prefixIcon: AppIcons.branch,
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.buttonRadius,
                              ),
                            ),
                            onPressed: _submit,
                            child: const Text(
                              'Save Expense',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) => InputDecoration(
    labelText: labelText,
    hintText: hintText,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIcon: Icon(prefixIcon, color: AppColors.textSubtle, size: 20),
    border: const OutlineInputBorder(
      borderRadius: AppRadius.inputRadius,
      borderSide: AppBorders.inputDefaultSide,
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: AppRadius.inputRadius,
      borderSide: AppBorders.inputDefaultSide,
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppRadius.inputRadius,
      borderSide: AppBorders.inputFocusedSide,
    ),
    filled: true,
    fillColor: AppColors.surface,
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      CreateExpenseRequest(
        categoryId: _categoryId,
        amount: double.parse(_amount.text.trim()),
        paymentMethod: _paymentMethod,
        vendor: _vendor.text.trim(),
        description: _description.text.trim(),
        expenseDate: DateTime.now(),
      ),
    );
  }
}

class _AddExpenseHeader extends StatelessWidget {
  const _AddExpenseHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(border: AppBorders.topBar),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 34,
                child: Material(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.iconContainerSmall),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.iconContainerSmall),
                    onTap: onBack,
                    child: const Icon(
                      AppIcons.arrowBack,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Add Expense',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader({required this.onAdd, required this.onBack});

  final VoidCallback onAdd;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(border: AppBorders.topBar),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 34,
                child: Material(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.iconContainerSmall),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.iconContainerSmall),
                    onTap: onBack,
                    child: const Icon(
                      AppIcons.arrowBack,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Expenses',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(
                width: 68,
                height: 32,
                child: Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.iconContainerSmall),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onAdd,
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            AppIcons.add,
                            size: 15,
                            color: AppColors.surface,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ],
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

class _ExpenseSummary extends StatelessWidget {
  const _ExpenseSummary({required this.categoryCount, required this.total});

  final int categoryCount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF8B00),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'THIS MONTH',
            style: AppTextStyles.captionBold.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: 5),
          Text(
            _formatRupees(total),
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.surface,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Across $categoryCount expense categories',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.surface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.controller});

  final ExpenseController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: controller.categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final String? categoryId = index == 0
              ? null
              : controller.categories[index - 1].id;
          final String label = index == 0
              ? 'All'
              : controller.categories[index - 1].name;
          final bool selected = controller.selectedCategoryId == categoryId;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => controller.selectCategory(categoryId),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primaryMuted,
            side: selected
                ? AppBorders.chipActiveSide
                : AppBorders.chipDefaultSide,
            labelStyle: AppTextStyles.buttonMedium.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            elevation: 0,
            shape: const StadiumBorder(),
          );
        },
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.category, required this.expense});

  final ExpenseCategory category;
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 73,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: AppBorders.cardDefault,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(AppRadius.iconContainer),
            ),
            child: Text(category.symbol, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  expense.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: AppRadius.badgeRadius,
                  ),
                  child: Text(
                    expense.categoryName,
                    style: AppTextStyles.micro.copyWith(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _formatRupees(expense.amount),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.errorLight,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _formatDate(expense.expenseDate),
                style: AppTextStyles.micro.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatRupees(double amount) {
  final String digits = amount.round().toString();
  if (digits.length <= 3) return 'Rs. $digits';
  final String tail = digits.substring(digits.length - 3);
  String head = digits.substring(0, digits.length - 3);
  final List<String> groups = <String>[];
  while (head.length > 2) {
    groups.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) groups.insert(0, head);
  return 'Rs. ${groups.join(',')},$tail';
}

String _formatDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}
