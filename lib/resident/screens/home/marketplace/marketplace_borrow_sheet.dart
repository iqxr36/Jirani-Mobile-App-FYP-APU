part of '../resident_marketplace_view.dart';

// Marketplace borrow feature: bottom sheet for choosing dates/times/mode and submitting a borrow request.
class _BorrowRequestSheet extends StatefulWidget {
  const _BorrowRequestSheet({required this.item});

  final ItemModel item;

  @override
  State<_BorrowRequestSheet> createState() => _BorrowRequestSheetState();
}

class _BorrowRequestSheetState extends State<_BorrowRequestSheet> {
  final TextEditingController _messageController = TextEditingController();
  _RentalMode _mode = _RentalMode.daily;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int get _dailyDuration =>
      MarketplaceBorrowFlow.dailyDurationDays(_startDate, _endDate);

  int get _hourlyDuration {
    return MarketplaceBorrowFlow.hourlyDurationHours(
      DateTime(0, 1, 1, _startTime.hour, _startTime.minute),
      DateTime(0, 1, 1, _endTime.hour, _endTime.minute),
    );
  }

  double get _dailyRate =>
      widget.item.hasUsageFee ? widget.item.feeAmount ?? 0 : 0;

  double get _hourlyRate => MarketplaceBorrowFlow.derivedHourlyRate(_dailyRate);

  double get _usageFee {
    if (!widget.item.hasUsageFee) return 0;
    return _mode == _RentalMode.daily
        ? MarketplaceBorrowFlow.dailyUsageFee(
            dailyFee: _dailyRate,
            start: _startDate,
            end: _endDate,
          )
        : MarketplaceBorrowFlow.hourlyUsageFee(
            dailyFee: _dailyRate,
            hours: _hourlyDuration,
          );
  }

  bool get _hourlyFeeCapped =>
      _mode == _RentalMode.hourly &&
      widget.item.hasUsageFee &&
      _hourlyRate * _hourlyDuration > _dailyRate;

  double get _deposit =>
      widget.item.hasDeposit ? widget.item.depositAmount ?? 0 : 0;

  String get _durationLabel => _mode == _RentalMode.daily
      ? '$_dailyDuration days'
      : '$_hourlyDuration hours';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.residentOutline(),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose Borrowing Dates',
              style: TextStyle(
                color: context.appInk,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily fee is set by the lender. Hourly borrowing is calculated from that daily price.',
              style: TextStyle(
                color: context.appMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Select Rental Type'),
            const SizedBox(height: 8),
            _ModeSelector(
              selected: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
            const SizedBox(height: 14),
            if (_mode == _RentalMode.daily) ...[
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      label: 'Start Date',
                      value: _shortDateFormat.format(_startDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      label: 'End Date',
                      value: _shortDateFormat.format(_endDate),
                      icon: Icons.event_available_rounded,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Duration', value: _durationLabel),
            ] else ...[
              _PickerTile(
                label: 'Borrow Date',
                value: _shortDateFormat.format(_startDate),
                icon: Icons.calendar_today_rounded,
                onTap: () => _pickDate(isStart: true),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      label: 'Start Time',
                      value: _startTime.format(context),
                      icon: Icons.schedule_rounded,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      label: 'End Time',
                      value: _endTime.format(context),
                      icon: Icons.schedule_send_rounded,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow(label: 'Duration', value: _durationLabel),
            ],
            const SizedBox(height: 12),
            if (widget.item.hasUsageFee) ...[
              _SummaryRow(label: 'Daily rate', value: _money(_dailyRate)),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Hourly rate',
                value: '${_money(_hourlyRate)} / hour',
              ),
              if (_mode == _RentalMode.hourly) ...[
                const SizedBox(height: 8),
                _PricingNote(capped: _hourlyFeeCapped),
              ],
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 3,
              decoration: context.residentInputDecoration(
                label: 'Message to owner',
                hint: 'Optional meetup note or reason for borrowing',
              ),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: _mode == _RentalMode.daily
                  ? 'Item fee'
                  : _hourlyFeeCapped
                  ? 'Item fee (daily cap)'
                  : 'Item fee',
              value: _money(_usageFee),
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Refundable deposit', value: _money(_deposit)),
            const Divider(height: 26),
            _SummaryRow(
              label: 'Total after approval',
              value: _money(
                MarketplaceBorrowFlow.totalDue(
                  usageFee: _usageFee,
                  deposit: _deposit,
                ),
              ),
              emphasized: true,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SecondaryButton(
                    icon: Icons.close_rounded,
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Consumer<BorrowRequestProvider>(
                    builder: (context, provider, _) {
                      return _PrimaryButton(
                        icon: Icons.check_rounded,
                        label: provider.isLoading
                            ? 'Sending...'
                            : 'Confirm to Checkout',
                        onTap: provider.isLoading ? null : _submitRequest,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Marketplace borrow feature: lets the borrower choose start or return date.
  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked.isBefore(_startDate) ? _startDate : picked;
      }
    });
  }

  // Marketplace borrow feature: lets the borrower choose pickup/return time.
  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  // Marketplace borrow feature: validates borrower access and creates the initial pending borrow request.
  Future<void> _submitRequest() async {
    final user = context.read<AuthViewModel>().currentUser;
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please sign in before requesting.')),
      );
      return;
    }

    final requestedStart = _mode == _RentalMode.daily
        ? DateTime(_startDate.year, _startDate.month, _startDate.day)
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
    var expectedReturn = _mode == _RentalMode.daily
        ? DateTime(_endDate.year, _endDate.month, _endDate.day)
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _endTime.hour,
            _endTime.minute,
          );
    if (!expectedReturn.isAfter(requestedStart)) {
      expectedReturn = requestedStart.add(const Duration(hours: 1));
    }
    final pickupTime = _mode == _RentalMode.daily
        ? 'Daily rental'
        : '${_startTime.format(context)} - ${_endTime.format(context)}';

    final provider = context.read<BorrowRequestProvider>();
    await provider.createBorrowRequest(
      item: widget.item,
      borrower: user,
      requestedStartDate: requestedStart,
      expectedReturnDate: expectedReturn,
      pickupTime: pickupTime,
      message: _messageController.text,
      usageFeeAmount: _usageFee,
      rentalMode: _mode == _RentalMode.daily
          ? AppConstants.rentalModeDaily
          : AppConstants.rentalModeHourly,
      rentalUnitCount: _mode == _RentalMode.daily
          ? _dailyDuration
          : _hourlyDuration,
      dailyRateSnapshot: widget.item.hasUsageFee ? _dailyRate : null,
      hourlyRateSnapshot: widget.item.hasUsageFee ? _hourlyRate : null,
    );

    if (!mounted) return;
    final error = provider.errorMessage;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error == null || error.isEmpty
              ? 'Borrow request sent. Watch My Requests for approval.'
              : error,
        ),
      ),
    );
    if (error == null || error.isEmpty) {
      Navigator.of(context).pop();
    }
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onChanged});

  final _RentalMode selected;
  final ValueChanged<_RentalMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Daily',
              selected: selected == _RentalMode.daily,
              onTap: () => onChanged(_RentalMode.daily),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Hourly',
              selected: selected == _RentalMode.hourly,
              onTap: () => onChanged(_RentalMode.hourly),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingNote extends StatelessWidget {
  const _PricingNote({required this.capped});

  final bool capped;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.infoContainerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.infoContainerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            capped ? Icons.savings_outlined : Icons.schedule_rounded,
            color: _kBrandTeal,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              capped
                  ? 'Hourly total reached the same-day daily cap, so you will not pay more than the daily rate.'
                  : 'Hourly borrowing uses the daily fee divided by ${MarketplaceBorrowFlow.hourlyBillingHoursPerDay}.',
              style: TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.appMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? context.glassFill( lightAlpha: 1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDarkUi ? 0.22 : 0.08,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _kBrandTeal : muted,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.softSurface(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.residentOutline()),
        ),
        child: Row(
          children: [
            Icon(icon, color: _kBrandTeal, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

