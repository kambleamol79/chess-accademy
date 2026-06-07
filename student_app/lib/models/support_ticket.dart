class SupportTicket {
  SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    this.assignedToUserId,
    this.resolutionComment,
    this.assigneeFirstName,
    this.assigneeLastName,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String subject;
  final String status;
  final int? assignedToUserId;
  final String? resolutionComment;
  final String? assigneeFirstName;
  final String? assigneeLastName;
  final String createdAt;
  final String updatedAt;

  bool get isResolved => status == 'resolved';

  String get assigneeName {
    final name = '${assigneeFirstName ?? ''} ${assigneeLastName ?? ''}'.trim();
    return name.isEmpty ? 'Admin' : name;
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as int,
      subject: json['subject'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      assignedToUserId: json['assigned_to_user_id'] as int?,
      resolutionComment: json['resolution_comment'] as String?,
      assigneeFirstName: json['assignee_first_name'] as String?,
      assigneeLastName: json['assignee_last_name'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class SupportTicketMessage {
  SupportTicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderUserId,
    required this.body,
    this.senderFirstName,
    this.senderLastName,
    this.senderRole,
    required this.createdAt,
  });

  final int id;
  final int ticketId;
  final int senderUserId;
  final String body;
  final String? senderFirstName;
  final String? senderLastName;
  final String? senderRole;
  final String createdAt;

  String get senderName {
    final name = '${senderFirstName ?? ''} ${senderLastName ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    return senderRole == 'admin' ? 'Admin' : 'You';
  }

  factory SupportTicketMessage.fromJson(Map<String, dynamic> json) {
    return SupportTicketMessage(
      id: json['id'] as int,
      ticketId: json['ticket_id'] as int,
      senderUserId: json['sender_user_id'] as int,
      body: json['body'] as String? ?? '',
      senderFirstName: json['sender_first_name'] as String?,
      senderLastName: json['sender_last_name'] as String?,
      senderRole: json['sender_role'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
