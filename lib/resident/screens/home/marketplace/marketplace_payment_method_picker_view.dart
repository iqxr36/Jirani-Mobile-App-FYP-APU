part of '../resident_marketplace_view.dart';

class _MarketplacePaymentMethodPickerView extends StatefulWidget {
  const _MarketplacePaymentMethodPickerView({
    required this.initialPaymentMethodId,
  });

  final String? initialPaymentMethodId;

  @override
  State<_MarketplacePaymentMethodPickerView> createState() =>
      _MarketplacePaymentMethodPickerViewState();
}

class _MarketplacePaymentMethodPickerViewState
    extends State<_MarketplacePaymentMethodPickerView> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PaymentProvider>().loadPaymentMethods();
      }
    });
  }

  Future<void> _addPaymentMethod() async {
    final provider = context.read<PaymentProvider>();
    final ok = await provider.addPaymentMethod();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Payment method added.'
              : provider.errorMessage ?? 'Could not add payment method.',
        ),
      ),
    );
  }

  Future<void> _selectPaymentMethod(PaymentMethodModel method) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PaymentProvider>();
    if (!method.isDefault) {
      final ok = await provider.setDefaultPaymentMethod(
        method.stripePaymentMethodId,
      );
      if (!mounted) return;
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'Could not select payment method.',
            ),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(method);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: JiraniBackground(
        child: SafeArea(
          bottom: false,
          child: Consumer<PaymentProvider>(
            builder: (context, provider, _) {
              return RefreshIndicator(
                onRefresh: provider.loadPaymentMethods,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottom),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ScreenTitleBar(
                            title: 'Choose Card',
                            onBack: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 16),
                          _GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionLabel('Saved Payment Methods'),
                                const SizedBox(height: 12),
                                if (provider.isLoading &&
                                    provider.paymentMethods.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: _kBrandTeal,
                                      ),
                                    ),
                                  )
                                else if (provider.paymentMethods.isEmpty)
                                  _PickerEmptyState(
                                    message: provider.errorMessage,
                                  )
                                else ...[
                                  for (final method
                                      in provider.paymentMethods) ...[
                                    _PickerPaymentMethodTile(
                                      method: method,
                                      selected:
                                          widget.initialPaymentMethodId ==
                                              method.stripePaymentMethodId ||
                                          (widget.initialPaymentMethodId ==
                                                  null &&
                                              method.isDefault),
                                      busy: provider.isLoading,
                                      onTap: () => _selectPaymentMethod(method),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ],
                                if (provider.errorMessage != null &&
                                    provider.paymentMethods.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    provider.errorMessage!,
                                    style: const TextStyle(
                                      color: _kWarmAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _SecondaryButton(
                                  icon: Icons.add_card_rounded,
                                  label: provider.isLoading
                                      ? 'Please wait...'
                                      : 'Add Payment Method',
                                  onTap: provider.isLoading
                                      ? null
                                      : _addPaymentMethod,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Cards are saved by Stripe. Jirani stores only safe card labels such as brand, last four digits, and expiry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PickerEmptyState extends StatelessWidget {
  const _PickerEmptyState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Column(
        children: [
          Icon(
            message == null
                ? Icons.account_balance_wallet_outlined
                : Icons.error_outline_rounded,
            color: message == null ? _kBrandTeal : _kWarmAccent,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            message ?? 'No payment methods added yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appInk,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          if (message == null) ...[
            const SizedBox(height: 6),
            Text(
              'Add a card to continue with this marketplace payment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerPaymentMethodTile extends StatelessWidget {
  const _PickerPaymentMethodTile({
    required this.method,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final PaymentMethodModel method;
  final bool selected;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _kBrandTeal : context.residentOutline();

    return Material(
      color: context.softSurface(),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kBrandTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card_rounded, color: _kBrandTeal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _paymentBrandLabel(method.brand),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (method.isDefault) ...[
                          const SizedBox(width: 8),
                          const _DefaultPaymentBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '**** **** **** ${method.last4} · Exp ${_paymentExpiry(method)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _kBrandTeal : context.appMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultPaymentBadge extends StatelessWidget {
  const _DefaultPaymentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kBrandTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
          color: _kBrandTeal,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _paymentBrandLabel(String brand) {
  final value = brand.trim();
  if (value.isEmpty) return 'Card';
  return value
      .split(RegExp(r'\s+'))
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _paymentExpiry(PaymentMethodModel method) {
  final month = method.expMonth.toString().padLeft(2, '0');
  final year = (method.expYear % 100).toString().padLeft(2, '0');
  return '$month/$year';
}
