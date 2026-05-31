class Reminder {
  Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.dueAt,
    this.priority = 'medium',
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      dueAt: json['due_at'] as String?,
      priority: json['priority'] as String? ?? 'medium',
    );
  }

  final String id;
  final String type;
  final String title;
  final String message;
  final String? dueAt;
  final String priority;
}
