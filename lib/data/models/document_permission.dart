/// Mô hình quyền chia sẻ tài liệu giữa các người dùng trong hệ thống (Supabase Permissions Table).
class DocumentPermission {
  final String id;
  final String documentId;
  final String userId;
  final String sharedEmail;
  final String role; // 'viewer' hoặc 'editor'
  final DateTime createdAt;

  const DocumentPermission({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.sharedEmail,
    required this.role,
    required this.createdAt,
  });

  bool get isEditor => role.toLowerCase() == 'editor';
  bool get isViewer => role.toLowerCase() == 'viewer';

  factory DocumentPermission.fromMap(Map<String, dynamic> map) {
    return DocumentPermission(
      id: map['id']?.toString() ?? '',
      documentId: map['document_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      sharedEmail: map['shared_email'] as String? ?? '',
      role: map['role'] as String? ?? 'viewer',
      createdAt: _parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'shared_email': sharedEmail,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic val) {
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
