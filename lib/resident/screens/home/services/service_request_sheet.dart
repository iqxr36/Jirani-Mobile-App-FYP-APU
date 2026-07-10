part of '../resident_services_view.dart';

Future<void> _showRequestSheet(
  BuildContext context,
  AppUser user,
  ServiceModel service,
) async {
  final message = TextEditingController();
  final schedule = parseServiceAvailability(service);
  var date = nextAllowedBookingDate(
        schedule: schedule,
        after: DateTime.now().add(const Duration(days: 1)),
      ) ??
      DateTime.now().add(const Duration(days: 1));
  var preferredTime = clampPreferredTime(
    schedule: schedule,
    preferred: TimeOfDay.fromDateTime(
      DateTime.now().add(const Duration(hours: 2)),
    ),
  );
  var durationHours = 1;
  String? availabilityError;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Request Service',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                _ServiceRequestSummaryCard(service: service),
                const SizedBox(height: 12),
                _ServiceRequestTotalCard(
                  service: service,
                  durationHours: durationHours,
                  onDecrease: durationHours <= 1
                      ? null
                      : () => setState(() => durationHours -= 1),
                  onIncrease: durationHours >= 12
                      ? null
                      : () => setState(() => durationHours += 1),
                ),
                const SizedBox(height: 14),
                if (availabilityError != null) ...[
                  Text(
                    availabilityError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _ServiceRequestPickerTile(
                        label: 'Preferred date',
                        value: DateFormat('MMM d, yyyy').format(date),
                        icon: Icons.calendar_today_rounded,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 90),
                            ),
                            initialDate: date,
                            selectableDayPredicate: (day) {
                              if (!schedule.hasStructuredFields &&
                                  schedule.weekdays.isEmpty) {
                                return true;
                              }
                              return schedule.isWeekdayAllowed(day.weekday);
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              date = picked;
                              availabilityError = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ServiceRequestPickerTile(
                        label: 'Preferred time',
                        value: preferredTime.format(context),
                        icon: Icons.schedule_rounded,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: preferredTime,
                          );
                          if (picked != null) {
                            setState(() {
                              preferredTime = picked;
                              final minutes = timeOfDayToMinutes(picked);
                              if (schedule.hasStructuredFields &&
                                  !schedule.isTimeAllowed(minutes)) {
                                availabilityError = schedule.validationMessage;
                              } else {
                                availabilityError = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: message,
                  decoration: context.residentInputDecoration(
                    label: 'Message to provider (optional)',
                    hint: 'Describe what you need or timing details',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                const _ServiceRequestHelperText(
                  text:
                      'Tip: include location notes, task size, and whether your time is flexible.',
                ),
                const SizedBox(height: 18),
                Consumer<services.ServiceProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: ResidentSecondaryButton(
                            icon: Icons.close_rounded,
                            label: 'Cancel',
                            onTap: provider.isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ResidentPrimaryButton(
                            icon: Icons.check_rounded,
                            label: provider.isLoading
                                ? 'Sending...'
                                : 'Confirm',
                            onTap: provider.isLoading
                                ? null
                                : () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    try {
                                      validateServiceAvailability(
                                        schedule: schedule,
                                        preferredDate: date,
                                        preferredTimeLabel:
                                            preferredTime.format(context),
                                      );
                                      await context
                                          .read<services.ServiceProvider>()
                                          .createServiceRequest(
                                            service: service,
                                            requester: user,
                                            message: message.text,
                                            preferredDate: date,
                                            preferredTime:
                                                preferredTime.format(context),
                                            durationHours:
                                                _isHourlyService(service)
                                                    ? durationHours
                                                    : null,
                                          );
                                      if (!context.mounted) return;
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Booking sent. Watch My Requests for provider approval.',
                                          ),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            error.toString().replaceFirst(
                                                  'Exception: ',
                                                  '',
                                                ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ServiceRequestSummaryCard extends StatelessWidget {
  const _ServiceRequestSummaryCard({required this.service});

  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    final ink = context.appInk;
    final muted = context.appMuted;
    final provider = service.providerName.trim().isEmpty
        ? 'Service provider'
        : service.providerName.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: residentBrandTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.design_services_outlined,
              color: residentBrandTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  provider,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 108),
            child: Text(
              _priceLabel(service),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: residentBrandTeal,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRequestTotalCard extends StatelessWidget {
  const _ServiceRequestTotalCard({
    required this.service,
    required this.durationHours,
    required this.onDecrease,
    required this.onIncrease,
  });

  final ServiceModel service;
  final int durationHours;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final hourly = _isHourlyService(service);
    final rate = _serviceBasePrice(service);
    final total = hourly ? rate * durationHours : rate;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.softSurface(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.residentOutline()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResidentSummaryRow(
            label: hourly ? 'Hourly rate' : 'Fixed total',
            value: hourly ? '${_money(rate)} / hour' : _money(total),
          ),
          if (hourly) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Duration',
                    style: TextStyle(
                      color: context.appInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Decrease hours',
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 82,
                  child: Text(
                    '$durationHours h',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Increase hours',
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const Divider(height: 24),
            ResidentSummaryRow(
              label: 'Estimated total',
              value: '${_money(rate)} x $durationHours h = ${_money(total)}',
              emphasized: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceRequestPickerTile extends StatelessWidget {
  const _ServiceRequestPickerTile({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.softSurface(),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.residentOutline()),
          ),
          child: Row(
            children: [
              Icon(icon, color: residentBrandTeal, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: residentBrandTeal,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRequestHelperText extends StatelessWidget {
  const _ServiceRequestHelperText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.appMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}
