/// Returns the calendar-day difference from [from] to [date].
///
/// A positive result means [date] is in the future, zero means today, and a
/// negative result means [date] has passed. Time-of-day is intentionally
/// ignored for date-only fields such as subscription renewal dates.
int calendarDaysUntil(DateTime date, {DateTime? from}) {
  final start = from ?? DateTime.now();
  final startDay = DateTime.utc(start.year, start.month, start.day);
  final targetDay = DateTime.utc(date.year, date.month, date.day);
  return targetDay.difference(startDay).inDays;
}

String subscriptionDueStatus(DateTime dueDate, {DateTime? today}) {
  final daysUntil = calendarDaysUntil(dueDate, from: today);
  if (daysUntil == 0) return 'Due today';
  if (daysUntil == 1) return 'Due tomorrow';
  if (daysUntil > 1) return 'Due in $daysUntil days';

  final daysOverdue = -daysUntil;
  if (daysOverdue == 1) return 'Overdue by 1 day';
  return 'Overdue by $daysOverdue days';
}

const List<String> billingCycleUnits = ['Days', 'Weeks', 'Months', 'Years'];

/// Parses a stored billing cycle string (legacy `'Monthly'`, `'Weekly'`,
/// `'Yearly'`, `'Daily'`, or custom `'Every 2 Weeks'`) into `(interval, unit)`.
({int interval, String unit}) parseBillingCycle(String billingCycle) {
  final trimmed = billingCycle.trim();
  switch (trimmed.toLowerCase()) {
    case 'daily':
      return (interval: 1, unit: 'Days');
    case 'weekly':
      return (interval: 1, unit: 'Weeks');
    case 'monthly':
      return (interval: 1, unit: 'Months');
    case 'yearly':
      return (interval: 1, unit: 'Years');
  }

  final match = RegExp(
    r'^every\s+(\d+)\s+(day|days|week|weeks|month|months|year|years)$',
    caseSensitive: false,
  ).firstMatch(trimmed);

  if (match != null) {
    final rawInterval = int.tryParse(match.group(1) ?? '1') ?? 1;
    final interval = rawInterval < 1 ? 1 : rawInterval;
    final rawUnit = (match.group(2) ?? 'months').toLowerCase();
    if (rawUnit.startsWith('day')) {
      return (interval: interval, unit: 'Days');
    }
    if (rawUnit.startsWith('week')) {
      return (interval: interval, unit: 'Weeks');
    }
    if (rawUnit.startsWith('month')) {
      return (interval: interval, unit: 'Months');
    }
    if (rawUnit.startsWith('year')) {
      return (interval: interval, unit: 'Years');
    }
  }

  return (interval: 1, unit: 'Months');
}

/// Formats an interval and unit into a compact stored label (<= 20 chars),
/// e.g. `'Every 1 Month'`, `'Every 2 Weeks'`, `'Every 3 Days'`.
String formatBillingCycle(int interval, String unit) {
  final safeInterval = interval < 1 ? 1 : interval;
  final normalizedUnit = switch (unit.toLowerCase()) {
    'day' || 'days' => safeInterval == 1 ? 'Day' : 'Days',
    'week' || 'weeks' => safeInterval == 1 ? 'Week' : 'Weeks',
    'year' || 'years' => safeInterval == 1 ? 'Year' : 'Years',
    _ => safeInterval == 1 ? 'Month' : 'Months',
  };
  return 'Every $safeInterval $normalizedUnit';
}

/// Compact suffix shown under subscription cost, e.g. `/mo`, `/2 wk`, `/5d`.
String shortBillingCycleLabel(String billingCycle) {
  final parsed = parseBillingCycle(billingCycle);
  final n = parsed.interval;
  return switch (parsed.unit) {
    'Days' => n == 1 ? '/day' : '/${n}d',
    'Weeks' => n == 1 ? '/wk' : '/$n wk',
    'Years' => n == 1 ? '/yr' : '/$n yr',
    _ => n == 1 ? '/mo' : '/$n mo',
  };
}

/// Estimates the monthly equivalent cost for analytics.
double monthlyEquivalentCost(double cost, String billingCycle) {
  final parsed = parseBillingCycle(billingCycle);
  final n = parsed.interval;
  return switch (parsed.unit) {
    'Days' => cost * (30.4375 / n),
    'Weeks' => cost * (4.348 / n),
    'Years' => cost / (12.0 * n),
    _ => cost / n,
  };
}
