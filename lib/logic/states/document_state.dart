import '../../data/models/cloud_document.dart';

enum DocumentStatus { initial, loading, success, error }

class DocumentState {
  final DocumentStatus status;
  final List<CloudDocument> documents;
  final String searchQuery;
  final String? selectedCategory;
  final String? selectedSubject;
  final bool isAscending;
  final String? errorMessage;
  final String? successMessage;
  final double? uploadProgress;

  const DocumentState({
    this.status = DocumentStatus.initial,
    this.documents = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.selectedSubject,
    this.isAscending = false,
    this.errorMessage,
    this.successMessage,
    this.uploadProgress,
  });

  bool get isLoading => status == DocumentStatus.loading;
  bool get hasError => status == DocumentStatus.error && errorMessage != null;
  bool get isEmpty => documents.isEmpty;
  bool get isFiltering =>
      searchQuery.trim().isNotEmpty ||
      (selectedCategory != null && selectedCategory != 'Tất cả') ||
      (selectedSubject != null && selectedSubject != 'Tất cả');

  DocumentState copyWith({
    DocumentStatus? status,
    List<CloudDocument>? documents,
    String? searchQuery,
    String? selectedCategory,
    bool clearCategory = false,
    String? selectedSubject,
    bool clearSubject = false,
    bool? isAscending,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
    double? uploadProgress,
    bool clearUploadProgress = false,
  }) {
    return DocumentState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedSubject: clearSubject
          ? null
          : (selectedSubject ?? this.selectedSubject),
      isAscending: isAscending ?? this.isAscending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      uploadProgress: clearUploadProgress
          ? null
          : (uploadProgress ?? this.uploadProgress),
    );
  }
}
