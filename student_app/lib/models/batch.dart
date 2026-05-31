class StudentBatch {
  StudentBatch({
    required this.enrollmentId,
    required this.formId,
    required this.batch,
    required this.time,
    required this.daysSummary,
    required this.day1,
    required this.day2,
    this.module,
    this.coach1,
    this.coach2,
    this.notes,
    this.highlight,
    this.enrolledAt,
    this.status,
    this.zoomJoinUrl,
    this.zoomMeetingId,
  });

  factory StudentBatch.fromJson(Map<String, dynamic> json) {
    return StudentBatch(
      enrollmentId: json['enrollment_id'] as int? ?? 0,
      formId: json['form_id'] as int? ?? 0,
      batch: json['batch'] as String? ?? '',
      time: json['time'] as String? ?? '',
      daysSummary: json['days_summary'] as String? ?? '',
      day1: json['day_1'] as String? ?? '',
      day2: json['day_2'] as String? ?? '',
      module: json['module'] as String?,
      coach1: json['coach_1'] as String?,
      coach2: json['coach_2'] as String?,
      notes: json['notes'] as String?,
      highlight: json['highlight'] as String?,
      enrolledAt: json['enrolled_at'] as String?,
      status: json['status'] as String?,
      zoomJoinUrl: json['zoom_join_url'] as String?,
      zoomMeetingId: json['zoom_meeting_id'] as String?,
    );
  }

  final int enrollmentId;
  final int formId;
  final String batch;
  final String time;
  final String daysSummary;
  final String day1;
  final String day2;
  final String? module;
  final String? coach1;
  final String? coach2;
  final String? notes;
  final String? highlight;
  final String? enrolledAt;
  final String? status;
  final String? zoomJoinUrl;
  final String? zoomMeetingId;

  String get coachesLabel {
    final parts = [coach1, coach2].where((c) => c != null && c.isNotEmpty).toList();
    return parts.isEmpty ? 'Not assigned' : parts.join(' · ');
  }
}
