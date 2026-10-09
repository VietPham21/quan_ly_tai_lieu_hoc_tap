import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' as drift;

import '../database/app_database.dart';

/// Đại diện cho một tài liệu học tập trong hệ thống đám mây.
/// Tương thích cả Cloud Firestore và cơ sở dữ liệu Drift SQLite cục bộ.
class CloudDocument {
  final String id;
  final String title;
  final String? description;
  final String subject;
  final String category;
  final String fileName;
  final String? filePath;
  final String fileType;
  final int fileSize;
  final String? storagePath;
  final String? fileUrl;
  final String ownerUid;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CloudDocument({
    required this.id,
    required this.title,
    this.description,
    required this.subject,
    required this.category,
    required this.fileName,
    this.filePath,
    required this.fileType,
    required this.fileSize,
    this.storagePath,
    this.fileUrl,
    required this.ownerUid,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Chuyển đổi từ Firestore Map sang CloudDocument
  factory CloudDocument.fromFirestoreMap(Map<String, dynamic> data, String id) {
    return CloudDocument(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      subject: data['subject'] as String? ?? '',
      category: data['category'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      filePath: data['filePath'] as String?,
      fileType: (data['fileType'] as String? ?? 'OTHER').toUpperCase(),
      fileSize: (data['fileSize'] as num?)?.toInt() ?? 0,
      storagePath: data['storagePath'] as String?,
      fileUrl: data['fileUrl'] as String?,
      ownerUid: data['ownerUid'] as String? ?? '',
      isFavorite: data['isFavorite'] as bool? ?? false,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// Chuyển đổi từ Firestore DocumentSnapshot sang CloudDocument
  factory CloudDocument.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return CloudDocument.fromFirestoreMap(snapshot.data() ?? {}, snapshot.id);
  }

  /// Chuyển đổi từ Drift Document sang CloudDocument
  factory CloudDocument.fromDrift(Document doc) {
    return CloudDocument(
      id: doc.id,
      title: doc.title,
      description: doc.description,
      subject: doc.subject,
      category: doc.category,
      fileName: doc.fileName,
      filePath: doc.filePath,
      fileType: doc.fileType,
      fileSize: doc.fileSize,
      storagePath: null,
      fileUrl: null,
      ownerUid: '',
      isFavorite: doc.isFavorite,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    );
  }

  /// Chuyển đổi sang Map để lưu trữ trên Cloud Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'titleLowercase': title.toLowerCase(),
      'description': description,
      'subject': subject,
      'category': category,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType.toUpperCase(),
      'fileSize': fileSize,
      'storagePath': storagePath,
      'fileUrl': fileUrl,
      'ownerUid': ownerUid,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Chuyển đổi sang DocumentsCompanion để lưu vào SQLite qua Drift ORM
  DocumentsCompanion toDriftCompanion() {
    return DocumentsCompanion(
      id: drift.Value(id),
      title: drift.Value(title),
      description: drift.Value(description),
      subject: drift.Value(subject),
      category: drift.Value(category),
      fileName: drift.Value(fileName),
      filePath: drift.Value(filePath),
      fileType: drift.Value(fileType),
      fileSize: drift.Value(fileSize),
      isFavorite: drift.Value(isFavorite),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  CloudDocument copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? category,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSize,
    String? storagePath,
    String? fileUrl,
    String? ownerUid,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CloudDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      storagePath: storagePath ?? this.storagePath,
      fileUrl: fileUrl ?? this.fileUrl,
      ownerUid: ownerUid ?? this.ownerUid,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
