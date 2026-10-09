import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/file_helper.dart';
import '../../data/models/cloud_document.dart';
import '../../logic/controllers/document_controller.dart';

class DocumentFormScreen extends StatefulWidget {
  final CloudDocument? document;

  const DocumentFormScreen({super.key, this.document});

  bool get isEditMode => document != null;

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _subjectController;
  late final TextEditingController _categoryController;
  late final TextEditingController _fileNameController;
  late final TextEditingController _filePathController;
  late final TextEditingController _fileSizeKbController;

  late String _selectedFileType;
  late bool _isFavorite;
  bool _isSubmitting = false;

  // Dữ liệu nhị phân của tệp thật khi được chọn qua FilePicker
  Uint8List? _selectedFileBytes;
  String? _pickedFileName;
  int? _pickedFileSize;

  @override
  void initState() {
    super.initState();
    final doc = widget.document;

    _titleController = TextEditingController(text: doc?.title ?? '');
    _descriptionController = TextEditingController(
      text: doc?.description ?? '',
    );
    _subjectController = TextEditingController(
      text: doc?.subject ?? AppConstants.defaultSubjects.first,
    );
    _categoryController = TextEditingController(
      text: doc?.category ?? AppConstants.defaultCategories[1], // Giáo trình
    );
    _fileNameController = TextEditingController(text: doc?.fileName ?? '');
    _filePathController = TextEditingController(text: doc?.filePath ?? '');
    _fileSizeKbController = TextEditingController(
      text: doc != null && doc.fileSize > 0
          ? (doc.fileSize / 1024).round().toString()
          : '0',
    );

    _selectedFileType = doc?.fileType ?? 'PDF';
    _isFavorite = doc?.isFavorite ?? false;

    if (!widget.isEditMode) {
      _titleController.addListener(_autoSuggestFileName);
    }
  }

  void _autoSuggestFileName() {
    if (!widget.isEditMode &&
        _selectedFileBytes == null &&
        _fileNameController.text.isEmpty &&
        _titleController.text.isNotEmpty) {
      final sanitized = _titleController.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^\w\.-]'), '');
      if (sanitized.isNotEmpty) {
        _fileNameController.text =
            '$sanitized.${_selectedFileType.toLowerCase()}';
      }
    }
  }

  /// Chọn tệp tin thực tế từ thiết bị thông qua FilePicker
  Future<void> _pickFileFromDevice() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'zip',
          'txt',
          'dart',
          'py',
        ],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        final size = (await file.length()) ?? bytes.lengthInBytes;

        // Giới hạn dung lượng tối đa 25MB
        const maxBytes = 25 * 1024 * 1024;
        if (size > maxBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tệp tin vượt quá dung lượng tối đa cho phép (25MB).',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFileBytes = bytes;
          _pickedFileName = file.name;
          _pickedFileSize = size;
          _fileNameController.text = file.name;
          _fileSizeKbController.text = (size / 1024).round().toString();

          final ext = file.extension?.toUpperCase() ?? 'PDF';
          if (AppConstants.supportedFileTypes.contains(ext)) {
            _selectedFileType = ext;
          } else if (['DOC', 'DOCX'].contains(ext)) {
            _selectedFileType = 'DOCX';
          } else if (['PPT', 'PPTX'].contains(ext)) {
            _selectedFileType = 'PPTX';
          } else if (['XLS', 'XLSX'].contains(ext)) {
            _selectedFileType = 'XLSX';
          } else {
            _selectedFileType = 'TXT';
          }

          if (_titleController.text.isEmpty) {
            // Tự điền tiêu đề từ tên file nếu chưa nhập
            final nameWithoutExt = file.name.contains('.')
                ? file.name.substring(0, file.name.lastIndexOf('.'))
                : file.name;
            _titleController.text = nameWithoutExt.replaceAll('_', ' ');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn tệp: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (!widget.isEditMode) {
      _titleController.removeListener(_autoSuggestFileName);
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _categoryController.dispose();
    _fileNameController.dispose();
    _filePathController.dispose();
    _fileSizeKbController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final controller = context.read<DocumentController>();
    final fileSizeKb = int.tryParse(_fileSizeKbController.text.trim()) ?? 0;
    final fileSizeBytes = _selectedFileBytes != null
        ? _selectedFileBytes!.lengthInBytes
        : fileSizeKb * 1024;

    bool success;
    if (widget.isEditMode) {
      success = await controller.updateDocument(
        id: widget.document!.id,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        subject: _subjectController.text,
        category: _categoryController.text,
        fileName: _fileNameController.text,
        filePath: _filePathController.text.isEmpty
            ? null
            : _filePathController.text,
        fileType: _selectedFileType,
        fileSize: fileSizeBytes,
        isFavorite: _isFavorite,
        createdAt: widget.document!.createdAt,
        oldStoragePath: widget.document!.storagePath,
        existingFileUrl: widget.document!.fileUrl,
        newFileBytes: _selectedFileBytes,
      );
    } else {
      success = await controller.createDocument(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        subject: _subjectController.text,
        category: _categoryController.text,
        fileName: _fileNameController.text,
        filePath: _filePathController.text.isEmpty
            ? null
            : _filePathController.text,
        fileType: _selectedFileType,
        fileSize: fileSizeBytes,
        isFavorite: _isFavorite,
        fileBytes: _selectedFileBytes,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditMode
                ? 'Đã cập nhật tài liệu thành công!'
                : 'Đã thêm tài liệu mới lên Cloud!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Thao tác không thành công'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditMode ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // CHỌN TỆP TIN THỰC TẾ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFileBytes != null
                      ? AppColors.primary
                      : Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: _selectedFileBytes != null ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_upload_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedFileBytes != null
                            ? 'TỆP ĐÃ CHỌN ĐỂ TẢI LÊN'
                            : (widget.document?.storagePath != null
                                  ? 'TỆP ĐÃ LƯU TRÊN CLOUD STORAGE'
                                  : 'CHỌN TỆP TỪ THIẾT BỊ (TÙY CHỌN)'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedFileBytes != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            FileHelper.getFileTypeIcon(_selectedFileType),
                            color: FileHelper.getFileTypeColor(
                              _selectedFileType,
                            ),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickedFileName ?? _fileNameController.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dung lượng: ${FileHelper.formatFileSize(_pickedFileSize ?? 0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hủy chọn tệp này',
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.error,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedFileBytes = null;
                              _pickedFileName = null;
                              _pickedFileSize = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (widget.document?.storagePath != null) ...[
                    Text(
                      'Tệp hiện tại: ${widget.document!.fileName} (${FileHelper.formatFileSize(widget.document!.fileSize)})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _pickFileFromDevice,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(
                      _selectedFileBytes != null
                          ? 'Chọn tệp khác thay thế'
                          : (widget.isEditMode
                                ? 'Thay thế tệp mới từ máy'
                                : 'Chọn tệp từ máy tính / điện thoại'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TIÊU ĐỀ
            const Text(
              'THÔNG TIN TÀI LIỆU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề tài liệu *',
                hintText: 'VD: Giáo trình Kiến trúc Phần mềm',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
              ),
              validator: controller.validateTitle,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Môn học (Subject)
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Môn học *',
                hintText: 'Nhập hoặc chọn môn học gợi ý',
                prefixIcon: const Icon(
                  Icons.school_outlined,
                  color: AppColors.primary,
                ),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                  tooltip: 'Chọn môn học gợi ý',
                  onSelected: (val) => _subjectController.text = val,
                  itemBuilder: (context) => AppConstants.defaultSubjects
                      .map(
                        (subj) => PopupMenuItem(value: subj, child: Text(subj)),
                      )
                      .toList(),
                ),
              ),
              validator: controller.validateSubject,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Danh mục (Category)
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Danh mục *',
                hintText: 'Nhập hoặc chọn danh mục gợi ý',
                prefixIcon: const Icon(
                  Icons.category_outlined,
                  color: AppColors.primary,
                ),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                  tooltip: 'Chọn danh mục gợi ý',
                  onSelected: (val) => _categoryController.text = val,
                  itemBuilder: (context) => AppConstants.defaultCategories
                      .where((c) => c != 'Tất cả')
                      .map((cat) => PopupMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                ),
              ),
              validator: controller.validateCategory,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Mô tả
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Mô tả / Ghi chú (không bắt buộc)',
                hintText: 'Tóm tắt nội dung trọng tâm, số chương, tác giả...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),

            // TỆP ĐÍNH KÈM & SIÊU DỮ LIỆU
            const Text(
              'TỆP ĐÍNH KÈM & SIÊU DỮ LIỆU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Chọn loại file
            const Text(
              'Định dạng tệp: *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.supportedFileTypes.map((type) {
                final isSelected = _selectedFileType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedFileType = type;
                        if (!widget.isEditMode &&
                            _fileNameController.text.contains('.')) {
                          final nameWithoutExt = _fileNameController.text
                              .split('.')
                              .first;
                          _fileNameController.text =
                              '$nameWithoutExt.${type.toLowerCase()}';
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tên tệp tin
            TextFormField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'Tên tệp tin (File name) *',
                hintText: 'VD: kien_truc_phan_mem.pdf',
                prefixIcon: Icon(
                  Icons.insert_drive_file_outlined,
                  color: AppColors.primary,
                ),
              ),
              validator: controller.validateFileName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Dung lượng tệp tin (KB)
            TextFormField(
              controller: _fileSizeKbController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dung lượng tệp (KB)',
                hintText: 'VD: 2048 (tương đương 2MB)',
                prefixIcon: Icon(
                  Icons.storage_rounded,
                  color: AppColors.primary,
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Đánh dấu yêu thích
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đánh dấu tài liệu quan trọng / yêu thích'),
              subtitle: const Text('Ghim hoặc đánh dấu sao để tra cứu nhanh'),
              value: _isFavorite,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _isFavorite = val),
            ),
            const SizedBox(height: 20),

            // Hiển thị thanh tiến trình Upload nếu đang tải
            if (controller.uploadProgress != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đang tải tệp lên Cloud Storage...',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${((controller.uploadProgress ?? 0) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: controller.uploadProgress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],

            // Nút Lưu
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                _isSubmitting
                    ? 'Đang lưu lên Cloud...'
                    : (widget.isEditMode
                          ? 'LƯU THAY ĐỔI'
                          : 'THÊM TÀI LIỆU LÊN CLOUD'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
