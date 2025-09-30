import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A provider that fetches all product documents and returns a map of
/// product ID to its corresponding image URL.
///
/// This allows UI components to easily look up an image URL for any product ID.
final productImagesProvider = FutureProvider<Map<String, String>>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final productsSnapshot = await firestore.collection('products').get();
  
  final Map<String, String> imageMap = {};
  for (var doc in productsSnapshot.docs) {
    final data = doc.data();
    // Check if the document has an 'image' field and it's not empty.
    if (data.containsKey('image') && (data['image' as Object] as String).isNotEmpty) {
      imageMap[doc.id] = data['image' as Object] as String;
    }
  }
  
  return imageMap;
});
