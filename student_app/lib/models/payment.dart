class Invoice {
  Invoice({
    required this.id,
    required this.amount,
    required this.status,
    this.description,
    this.dueDate,
    this.paidAt,
    this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      amount: json['amount']?.toString() ?? '0',
      status: json['status'] as String? ?? 'pending',
      description: json['description'] as String?,
      dueDate: json['due_date'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  final int id;
  final String amount;
  final String status;
  final String? description;
  final String? dueDate;
  final String? paidAt;
  final String? createdAt;
}

class MonthlyPayment {
  MonthlyPayment({
    required this.period,
    required this.amount,
    required this.status,
  });

  factory MonthlyPayment.fromJson(Map<String, dynamic> json) {
    return MonthlyPayment(
      period: json['period'] as String? ?? '',
      amount: json['amount'] as String? ?? '',
      status: json['status'] as String? ?? 'paid',
    );
  }

  final String period;
  final String amount;
  final String status;
}

class PaymentSummary {
  PaymentSummary({
    this.totalPay,
    this.paymentReceived,
    this.paymentDate,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PaymentSummary();
    return PaymentSummary(
      totalPay: json['total_pay']?.toString(),
      paymentReceived: json['payment_received']?.toString(),
      paymentDate: json['payment_date'] as String?,
    );
  }

  final String? totalPay;
  final String? paymentReceived;
  final String? paymentDate;
}

class PaymentHistory {
  PaymentHistory({
    required this.summary,
    required this.invoices,
    required this.monthly,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      summary: PaymentSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      invoices: (json['invoices'] as List<dynamic>? ?? [])
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthly: (json['monthly'] as List<dynamic>? ?? [])
          .map((e) => MonthlyPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final PaymentSummary summary;
  final List<Invoice> invoices;
  final List<MonthlyPayment> monthly;
}
