import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';

class FileHelper {
  FileHelper._();

  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  static String formatDateShort(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  static Color getFileTypeColor(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return AppColors.pdfColor;
      case 'DOC':
      case 'DOCX':
        return AppColors.docxColor;
      case 'PPT':
      case 'PPTX':
        return AppColors.pptxColor;
      case 'XLS':
      case 'XLSX':
        return AppColors.xlsxColor;
      case 'DART':
      case 'PY':
      case 'JAVA':
      case 'JS':
      case 'CPP':
      case 'HTML':
      case 'CODE':
        return AppColors.codeColor;
      case 'ZIP':
      case 'RAR':
      case '7Z':
        return AppColors.zipColor;
      default:
        return AppColors.otherColor;
    }
  }

  static IconData getFileTypeIcon(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'DOC':
      case 'DOCX':
        return Icons.description_rounded;
      case 'PPT':
      case 'PPTX':
        return Icons.slideshow_rounded;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart_rounded;
      case 'DART':
      case 'PY':
      case 'JAVA':
      case 'JS':
      case 'CPP':
      case 'HTML':
      case 'CODE':
        return Icons.code_rounded;
      case 'ZIP':
      case 'RAR':
      case '7Z':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
