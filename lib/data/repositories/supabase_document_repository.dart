import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/supabase_constants.dart';
import '../models/cloud_document.dart';
import '../models/document_permission.dart';

/// Repository quản lý dữ liệu tài liệu và phân quyền trên Supabase (PostgreSQL).
/// Kết nối với Firebase Storage (lưu URL tệp) và hỗ trợ phân quyền chia sẻ đa người dùng.
class SupabaseDocumentRepository {
  final SupabaseClient? _client;

  SupabaseDocumentRepository({SupabaseClient? client})
      : _client = client ??
            (SupabaseConstants.isConfigured
                ? Supabase.instance.client
                : null);

  SupabaseClient? get client => _client;

  /// Kiểm tra xem Supabase đã được khởi tạo và sẵn sàng hoạt động hay chưa
  bool get isAvailable => _client != null && SupabaseConstants.isConfigured;

  /// Lắng nghe luồng dữ liệu tài liệu thời gian thực (Realtime Stream)
  /// Bao gồm tài liệu do người dùng sở hữu và tài liệu được chia sẻ
  Stream<List<CloudDocument>> watchUserDocuments({
    required String uid,
    String query = '',
    String? category,
    String? subject,
    bool ascending = false,
  }) {
    if (!isAvailable || uid.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _client!
          .from('documents')
          .stream(primaryKey: ['id'])
          .asyncMap((dataList) async {
            final docs = dataList
                .map((row) => CloudDocument.fromSupabase(row))
                .toList();

            // Lấy danh sách ID các tài liệu được chia sẻ với user này
            Set<String> sharedDocIds = {};
            try {
              final permRes = await _client
                  .from('permissions')
                  .select('document_id')
                  .eq('user_id', uid);
              sharedDocIds = (permRes as List)
                  .map((p) => p['document_id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toSet();
            } catch (permErr) {
              debugPrint('Supabase watchUserDocuments lấy permissions lỗi: $permErr');
            }

            // Lọc theo người sở hữu HOẶC tài liệu được cấp quyền chia sẻ
            final userDocs = docs.where((doc) {
              return doc.ownerUid.isEmpty ||
                  doc.ownerUid == uid ||
                  sharedDocIds.contains(doc.id);
            }).toList();

            // Lọc danh mục nếu có
            var filtered = userDocs;
            if (category != null && category.isNotEmpty && category != 'Tất cả') {
              filtered = filtered.where((d) => d.category == category).toList();
            }

            // Lọc môn học nếu có
            if (subject != null && subject.isNotEmpty && subject != 'Tất cả') {
              filtered = filtered.where((d) => d.subject == subject).toList();
            }

            // Lọc từ khóa tìm kiếm
            final cleanQuery = query.trim().toLowerCase();
            if (cleanQuery.isNotEmpty) {
              filtered = filtered.where((doc) {
                return doc.title.toLowerCase().contains(cleanQuery) ||
                    doc.subject.toLowerCase().contains(cleanQuery) ||
                    doc.category.toLowerCase().contains(cleanQuery) ||
                    doc.fileName.toLowerCase().contains(cleanQuery) ||
                    (doc.description?.toLowerCase().contains(cleanQuery) ?? false);
              }).toList();
            }

            // Sắp xếp theo ngày cập nhật
            filtered.sort((a, b) {
              return ascending
                  ? a.updatedAt.compareTo(b.updatedAt)
                  : b.updatedAt.compareTo(a.updatedAt);
            });

            return filtered;
          });
    } catch (e) {
      debugPrint('SupabaseDocumentRepository.watchUserDocuments error: $e');
      return Stream.value([]);
    }
  }

  /// Thêm tài liệu mới vào bảng documents trên Supabase
  Future<void> addDocument(CloudDocument doc) async {
    if (!isAvailable) {
      throw Exception(
        'Supabase chưa được cấu hình. Vui lòng cấu hình URL và Key trong SupabaseConstants.',
      );
    }

    try {
      await _client!.from('documents').insert(doc.toSupabase());
    } on PostgrestException catch (e) {
      debugPrint('Supabase addDocument error: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Supabase addDocument unexpected error: $e');
      rethrow;
    }
  }

  /// Cập nhật tài liệu trên Supabase
  Future<void> updateDocument(CloudDocument doc) async {
    if (!isAvailable) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    try {
      await _client!
          .from('documents')
          .update(doc.toSupabase())
          .eq('id', doc.id);
    } on PostgrestException catch (e) {
      debugPrint('Supabase updateDocument error: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Supabase updateDocument unexpected error: $e');
      rethrow;
    }
  }

  /// Xóa tài liệu khỏi Supabase
  Future<void> deleteDocument({required String docId}) async {
    if (!isAvailable) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    try {
      await _client!.from('documents').delete().eq('id', docId);
    } on PostgrestException catch (e) {
      debugPrint('Supabase deleteDocument error: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Supabase deleteDocument unexpected error: $e');
      rethrow;
    }
  }

  /// Bật / Tắt yêu thích tài liệu
  Future<void> toggleFavorite({
    required String docId,
    required bool currentStatus,
  }) async {
    if (!isAvailable) return;

    try {
      await _client!.from('documents').update({
        'is_favorite': !currentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', docId);
    } catch (e) {
      debugPrint('Supabase toggleFavorite error: $e');
      rethrow;
    }
  }

  /// Đồng bộ thông tin người dùng từ Firebase Authentication sang bảng users trên Supabase
  Future<void> syncUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    if (!isAvailable || uid.isEmpty) return;

    try {
      await _client!.from('users').upsert({
        'id': uid,
        'email': email,
        'display_name': displayName ?? email.split('@').first,
        'photo_url': photoUrl,
      });
    } catch (e) {
      debugPrint('Supabase syncUserProfile error: $e');
    }
  }

  /// Tìm kiếm thông tin người dùng theo email trong bảng users
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    if (!isAvailable) return null;

    try {
      final response = await _client!
          .from('users')
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Supabase findUserByEmail error: $e');
      return null;
    }
  }

  /// Cấp quyền chia sẻ tài liệu cho người dùng khác (Checklist 4)
  Future<void> shareDocument({
    required String documentId,
    required String targetEmail,
    required String role, // 'viewer' hoặc 'editor'
  }) async {
    if (!isAvailable) {
      throw Exception('Supabase chưa được cấu hình.');
    }

    final targetUser = await findUserByEmail(targetEmail);
    if (targetUser == null) {
      throw Exception(
        'Không tìm thấy người dùng với email "$targetEmail" trong hệ thống. '
        'Yêu cầu người dùng đó đăng nhập ít nhất 1 lần để tạo tài khoản.',
      );
    }

    final targetUid = targetUser['id'] as String;

    try {
      await _client!.from('permissions').upsert({
        'document_id': documentId,
        'user_id': targetUid,
        'shared_email': targetEmail.trim().toLowerCase(),
        'role': role,
      });
    } catch (e) {
      debugPrint('Supabase shareDocument error: $e');
      rethrow;
    }
  }

  /// Lấy danh sách các quyền chia sẻ của một tài liệu
  Future<List<DocumentPermission>> getDocumentPermissions(
    String documentId,
  ) async {
    if (!isAvailable) return [];

    try {
      final res = await _client!
          .from('permissions')
          .select()
          .eq('document_id', documentId);

      return (res as List)
          .map((item) => DocumentPermission.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Supabase getDocumentPermissions error: $e');
      return [];
    }
  }

  /// Thu hồi quyền chia sẻ tài liệu
  Future<void> revokePermission(String permissionId) async {
    if (!isAvailable) return;

    try {
      await _client!.from('permissions').delete().eq('id', permissionId);
    } catch (e) {
      debugPrint('Supabase revokePermission error: $e');
      rethrow;
    }
  }

  /// Lấy danh sách tất cả người dùng trong hệ thống (phục vụ chọn người nhận chia sẻ)
  Future<List<Map<String, dynamic>>> getAllUsers({String? excludeUid}) async {
    if (!isAvailable) return [];
    try {
      var query = _client!.from('users').select('id, email, display_name, photo_url');
      if (excludeUid != null && excludeUid.isNotEmpty) {
        query = query.neq('id', excludeUid);
      }
      final res = await query;
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('Supabase getAllUsers error: $e');
      return [];
    }
  }

  /// Lấy vai trò của user đối với tài liệu ('owner', 'editor', 'viewer')
  Future<String> getUserRoleForDocument({
    required String documentId,
    required String uid,
    required String ownerUid,
  }) async {
    if (uid.isNotEmpty && uid == ownerUid) return 'owner';
    if (!isAvailable || uid.isEmpty) return 'viewer';

    try {
      final res = await _client!
          .from('permissions')
          .select('role')
          .eq('document_id', documentId)
          .eq('user_id', uid)
          .maybeSingle();

      if (res != null) {
        return (res['role'] as String? ?? 'viewer').toLowerCase();
      }
      return 'viewer';
    } catch (e) {
      debugPrint('Supabase getUserRoleForDocument error: $e');
      return 'viewer';
    }
  }
}
