class BatchMessage {
  BatchMessage({
    required this.id,
    required this.formId,
    required this.senderUserId,
    required this.body,
    this.senderFirstName,
    this.senderLastName,
    this.senderRole,
    required this.createdAt,
  });

  final int id;
  final int formId;
  final int senderUserId;
  final String body;
  final String? senderFirstName;
  final String? senderLastName;
  final String? senderRole;
  final String createdAt;

  String get senderName {
    final name = '${senderFirstName ?? ''} ${senderLastName ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    return senderRole == 'admin' ? 'Academy' : 'Coach';
  }

  factory BatchMessage.fromJson(Map<String, dynamic> json) {
    return BatchMessage(
      id: json['id'] as int,
      formId: json['form_id'] as int,
      senderUserId: json['sender_user_id'] as int,
      body: json['body'] as String? ?? '',
      senderFirstName: json['sender_first_name'] as String?,
      senderLastName: json['sender_last_name'] as String?,
      senderRole: json['sender_role'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
