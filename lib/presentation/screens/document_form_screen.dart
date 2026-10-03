import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../logic/controllers/document_controller.dart';

class DocumentFormScreen extends StatefulWidget {
  final Document? document;

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
          : '1024',
    );

    _selectedFileType = doc?.fileType ?? 'PDF';
    _isFavorite = doc?.isFavorite ?? false;

    // Tự động gợi ý tên file khi nhập title nếu đang thêm mới
    if (!widget.isEditMode) {
      _titleController.addListener(_autoSuggestFileName);
    }
  }

  void _autoSuggestFileName() {
    if (!widget.isEditMode &&
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
    final fileSizeBytes = fileSizeKb * 1024;

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
                : 'Đã thêm tài liệu mới!',
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();

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
            // Tiêu đề
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

            // TỆP ĐÍNH KÈM
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

            // Đường dẫn tệp / URI
            TextFormField(
              controller: _filePathController,
              decoration: const InputDecoration(
                labelText: 'Đường dẫn tệp cục bộ / URI (tùy chọn)',
                hintText: 'VD: /storage/emulated/0/Documents/kien_truc.pdf',
                prefixIcon: Icon(
                  Icons.folder_open_rounded,
                  color: AppColors.primary,
                ),
              ),
              textInputAction: TextInputAction.done,
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
            const SizedBox(height: 28),

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
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSubmitting
                    ? 'Đang lưu...'
                    : (widget.isEditMode ? 'LƯU THAY ĐỔI' : 'THÊM TÀI LIỆU'),
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
