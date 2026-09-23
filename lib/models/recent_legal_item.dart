import 'package:cloud_firestore/cloud_firestore.dart';

class RecentLegalItem {
  final String id;
  final String title;
  final String category;
  final String fetchedAt;
  final String tag;
  final String description;
  final String source;
  final String url;

  const RecentLegalItem({
    required this.id,
    required this.title,
    required this.category,
    required this.fetchedAt,
    required this.tag,
    required this.description,
    required this.source,
    required this.url,
  });

  factory RecentLegalItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final fetchedAtValue = data['fetchedAt'];

    String fetchedAt = '';

    if (fetchedAtValue is Timestamp) {
      final date = fetchedAtValue.toDate();

      fetchedAt =
      '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } else if (fetchedAtValue != null) {
      fetchedAt = fetchedAtValue.toString();
    }

    return RecentLegalItem(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      fetchedAt: fetchedAt,
      tag: data['tag']?.toString() ?? 'Election',
      description: data['description']?.toString() ?? '',
      source: data['source']?.toString() ?? '',
      url: data['url']?.toString() ?? '',
    );
  }
}