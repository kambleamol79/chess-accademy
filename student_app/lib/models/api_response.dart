class ApiResponse<T> {
  ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? parser,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      data: json['data'] != null && parser != null ? parser(json['data']) : json['data'] as T?,
      message: json['message'] as String?,
    );
  }

  final bool success;
  final T? data;
  final String? message;
}
