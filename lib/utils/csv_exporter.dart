import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Conditional import for web
import 'web_export_stub.dart' if (dart.library.html) 'web_export.dart';

class CsvExporter {
  /// Export data to CSV file
  /// Returns true if successful, false otherwise
  static Future<bool> exportToCSV({
    required String filename,
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    try {
      // Convert data to CSV format
      String csvContent = _convertToCSV(headers, data);

      if (kIsWeb) {
        // For web, trigger download
        await WebExport.downloadFile(filename, csvContent);
        return true;
      } else {
        // For mobile/desktop, use path_provider and file writing
        // TODO: Implement for mobile/desktop if needed
        debugPrint('CSV Export not implemented for non-web platforms');
        return false;
      }
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return false;
    }
  }

  /// Convert headers and data to CSV format
  static String _convertToCSV(List<String> headers, List<List<String>> data) {
    final StringBuffer buffer = StringBuffer();

    // Add UTF-8 BOM for proper Vietnamese character support in Excel
    buffer.write('\uFEFF');

    // Write headers
    buffer.write(headers.map(_escapeCSV).join(','));
    buffer.write('\n');

    // Write data rows
    for (var row in data) {
      buffer.write(row.map(_escapeCSV).join(','));
      buffer.write('\n');
    }

    return buffer.toString();
  }

  /// Escape CSV values (handle commas, quotes, newlines)
  static String _escapeCSV(String value) {
    // Replace newlines with spaces
    value = value.replaceAll('\n', ' ').replaceAll('\r', ' ');

    // If value contains comma, quote, or double-quote, wrap in quotes
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      // Escape quotes by doubling them
      value = value.replaceAll('"', '""');
      // Wrap in quotes
      value = '"$value"';
    }

    return value;
  }
}
