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
