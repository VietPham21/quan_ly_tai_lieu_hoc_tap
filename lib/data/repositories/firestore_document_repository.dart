import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/cloud_document.dart';

/// Repository quản lý dữ liệu tài liệu trên Cloud Firestore
/// Cấu trúc phân cấp: users/{uid}/documents/{documentId}
class FirestoreDocumentRepository {
  final FirebaseFirestore _firestore;

  FirestoreDocumentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  CollectionReference<Map<String, dynamic>> _userDocsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('documents');
  }

  /// Lắng nghe danh sách tài liệu theo thời gian thực (Reactive Stream)
  /// Tích hợp lọc theo danh mục, môn học và tìm kiếm từ khóa
  Stream<List<CloudDocument>> watchUserDocuments({
    required String uid,
    String query = '',
    String? category,
    String? subject,
    bool ascending = false,
  }) {
    if (uid.isEmpty) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> firestoreQuery = _userDocsRef(uid);

    // Lọc theo danh mục trên Firestore nếu có
    if (category != null && category.isNotEmpty && category != 'Tất cả') {
      firestoreQuery = firestoreQuery.where('category', isEqualTo: category);
    }

    // Lọc theo môn học trên Firestore nếu có
    if (subject != null && subject.isNotEmpty && subject != 'Tất cả') {
      firestoreQuery = firestoreQuery.where('subject', isEqualTo: subject);
    }

    firestoreQuery = firestoreQuery.orderBy(
      'updatedAt',
      descending: !ascending,
    );

    return firestoreQuery.snapshots().map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => CloudDocument.fromFirestore(doc))
          .toList();

      final cleanQuery = query.trim().toLowerCase();
      if (cleanQuery.isEmpty) {
        return docs;
      }

      // Lọc từ khóa in-memory trên tập dữ liệu của user (tiêu đề, môn học, danh mục, tên file, mô tả)
      return docs.where((doc) {
        return doc.title.toLowerCase().contains(cleanQuery) ||
            doc.subject.toLowerCase().contains(cleanQuery) ||
            doc.category.toLowerCase().contains(cleanQuery) ||
            doc.fileName.toLowerCase().contains(cleanQuery) ||
            (doc.description?.toLowerCase().contains(cleanQuery) ?? false);
      }).toList();
    });
  }

  /// Thêm tài liệu mới vào Cloud Firestore
  Future<void> addDocument(CloudDocument doc) async {
    try {
      await _userDocsRef(doc.ownerUid).doc(doc.id).set(doc.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint(
        'FirestoreDocumentRepository.addDocument Error: [${e.code}] ${e.message}',
      );
      rethrow;
    }
  }

  /// Cập nhật tài liệu hiện có trong Cloud Firestore
  Future<void> updateDocument(CloudDocument doc) async {
    try {
      await _userDocsRef(doc.ownerUid).doc(doc.id).update(doc.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint(
        'FirestoreDocumentRepository.updateDocument Error: [${e.code}] ${e.message}',
      );
      rethrow;
    }
  }

  /// Xóa tài liệu khỏi Cloud Firestore
  Future<void> deleteDocument({
    required String uid,
    required String docId,
  }) async {
    try {
      await _userDocsRef(uid).doc(docId).delete();
    } on FirebaseException catch (e) {
      debugPrint(
        'FirestoreDocumentRepository.deleteDocument Error: [${e.code}] ${e.message}',
      );
      rethrow;
    }
  }

  /// Đổi trạng thái yêu thích
  Future<void> toggleFavorite({
    required String uid,
    required String docId,
    required bool currentStatus,
  }) async {
    try {
      await _userDocsRef(uid)
          .doc(docId)
          .update({'isFavorite': !currentStatus, 'updatedAt': Timestamp.now()});
    } on FirebaseException catch (e) {
      debugPrint(
        'FirestoreDocumentRepository.toggleFavorite Error: [${e.code}] ${e.message}',
      );
      rethrow;
    }
  }
}
