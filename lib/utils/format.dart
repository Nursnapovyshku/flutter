const _months = [
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

String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]}, '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

String formatCountdown(Duration duration) {
  if (duration.inDays > 0) return '${duration.inDays}d left';
  if (duration.inHours > 0) return '${duration.inHours}h left';
  return '${duration.inMinutes}m left';
}
