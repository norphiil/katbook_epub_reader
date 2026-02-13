import 'dart:typed_data';
import 'package:epubx_kuebiko/epubx_kuebiko.dart';
import 'package:flutter/foundation.dart';

/// Utility class for extracting images from EPUB files.
class EpubImageExtractor {
  /// Extract all images from an EPUB book.
  /// Returns a map of image paths to their binary data.
  static Map<String, Uint8List> extractImages(EpubBook book) {
    final imageData = <String, Uint8List>{};
    
    if (book.Content?.Images == null) return imageData;

    for (final entry in book.Content!.Images!.entries) {
      final key = entry.key;
      final image = entry.value;
      
      if (image.Content != null) {
        final bytes = Uint8List.fromList(image.Content!);
        
        // Add with original path
        imageData[key] = bytes;
        
        // Add with just filename for easier matching
        final filename = key.split('/').last;
        imageData[filename] = bytes;
        
        // Handle common EPUB path prefixes
        if (key.startsWith('OEBPS/')) {
          imageData[key.substring(6)] = bytes;
        }
        if (key.startsWith('OPS/')) {
          imageData[key.substring(4)] = bytes;
        }
        if (key.startsWith('images/')) {
          imageData[key.substring(7)] = bytes;
        }
      }
    }

    debugPrint('🖼️ Extracted ${imageData.length} image entries');
    return imageData;
  }
}
